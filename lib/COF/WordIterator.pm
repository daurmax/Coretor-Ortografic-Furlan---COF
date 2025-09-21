package COF::WordIterator;
use strict;
use warnings;
use utf8;

use Scalar::Util qw(weaken);

use COF::Letters
  qw($WORD_CHARS $WORD_LETTERS $FUR_APOSTROPHS $FUR_LETTERS $FUR_VOWELS);

my @token_types = (

    [ "SPACE", '\s+' ],

    [ "WEB",  '(http://|www\.)[a-zA-Z0-9\.-]+\.[a-zA-Z]{2,}' ],
    [ "MAIL", '[a-zA-Z0-9\._-]+@[a-zA-Z0-9\.-]+\.[a-zA-Z]{2,}' ],

    [
        "WORD",
"([$FUR_APOSTROPHS]?)([$WORD_LETTERS](?:[$FUR_APOSTROPHS$WORD_LETTERS\\.\\-]*[$WORD_LETTERS])?)([$FUR_APOSTROPHS]?)"
    ],

    [ "NUM",     "\\d+([,'.]\\d+)*(?![$WORD_LETTERS])" ],
    [ "ALFANUM", "[$WORD_LETTERS\\d]+" ],

    [ "POINT", '\.' ],
    [ "SYM",   '.' ]
);

for my $elem (@token_types) {
    $elem->[1] = qr/\G$elem->[1]/;
}

sub new {
    my ( $class, $string ) = @_;

    my $self = bless {
        string => $string,
        ranges => {}, current => undef,
        queue  => [], finished => 0
    }, $class;

    $self->reset;

    return $self;
}

sub ahead {
    my ($self) = @_;
    my $queue = $self->{queue};

    return @$queue ? $queue->[0] : undef;
}

sub unshift_current {
    my $self = shift;
    if ( my $current = $self->{current} ) {
        unshift( @{$self->{queue}}, $current );
        $self->{current} = undef;
        return 1;
    }
    else {
        return 0;
    }
}

sub unshift_current_fix_apos {
    my $self = shift;
    if ( my $current = $self->{current} ) {
        if (   ( $current->{type} eq 'WORD' )
            && ( my $apo_type = $current->{subtype} ) )
        { delete $current->{subtype};
            if ( $apo_type eq 'BEFORE' ) {
                $current->{word} = substr( $current->{word}, 1 );
                $current->{pos} = $self->_wrap(
                    $current->{pos}->{start} + 1,
                    $current->{pos}->{length} - 1
                );
                $self->unshift_current();
            }
            else { my $apo_tok = {
                    'word' => substr( $current->{word}, -1 ),
                    'type' => 'SYM',
                    'pos'  => {
                        start => $current->{pos}->{start} +
                          $current->{pos}->{length} - 1,
                        length => 1
                    }
                };
                unshift( @{$self->{queue}}, $apo_tok );
                my ( $pos_shift, $length_dec ) =
                  $apo_type eq 'AFTER' ? ( 0, 1 ) : ( 1, 2 );
                $current->{word} = substr( $current->{word}, $pos_shift, -1 );
                $current->{pos} = $self->_wrap(
                    $current->{pos}->{start} + $pos_shift,
                    $current->{pos}->{length} - $length_dec
                );
                $self->unshift_current();
            }
            return 1;
        }
    }
    return 0;
}

sub get_current { $_[0]->{current} }

sub reset_current { $_[0]->{current} = undef }

sub next {
    my ($self) = @_;

    my $queue = $self->{queue};
    if (@$queue) {
        $self->{current} = shift @$queue;
        return $self->{current};
    }

    return if $self->{finished};

    for my $token_type (@token_types) {
        my ( $token_name, $token_regexp ) = @$token_type;
        if ( $self->{string} =~ /$token_regexp/gc ) {
            my ( $start, $length ) = ( $-[0], $+[0] - $-[0] );
            my $curr = $self->{current} = {
                word  => $&,
                type  => $token_name,
                'pos' => _wrap( $self, $start, $length )
            };
            if ( $token_name eq 'WORD' ) {
                if ( $1 || $3 ) { if ( !$3 ) {
                        $curr->{subtype} = 'BEFORE';
                    }
                    elsif ( !$1 ) {
                        $curr->{subtype} = 'AFTER';
                    }
                    else {
                        $curr->{subtype} = 'BOTH';
                    }
                }
            }
            return $curr;
        }
    }

    $self->{finished} = pos( $self->{string} ) == length( $self->{string} );

    if ( $self->{finished} ) {
        $self->{current} = undef;
        return;
    }
    else {
        my $pos = $self->get_pos;
        $self->set_pos( $pos + 1 );
        my $curr = $self->{current} = {
            word  => substr( $self->{string}, $pos, 1 ),
            type  => 'UNK',
            'pos' => _wrap( $self,            $pos, 1 )
        };
    }
}

sub _pos {
    my ( $self, $pos ) = @_;

    $self->{current}  = undef;
    $self->{queue}    = [];
    $self->{finished} = 0;

    pos( $self->{string} ) = $pos;
}

sub reset {
    my ($self) = @_;
    $self->_pos(0);
}

sub set_pos {
    _pos(@_);
}

sub get_pos {
    my $self  = shift;
    my $ahead = $self->ahead;
    return $ahead ? $ahead->{pos}->{start} : pos( $self->{string} );
}

sub len { length( $_[0]->{string} ) }

sub get_text { $_[0]->{string} }

sub at_end { $_[0]->{finished} ? 1 : 0 }

sub change {
    my ( $self, $position, $new_word, $old_word ) = @_;
    my $ahead = $self->ahead();
    my $pos   = $ahead ? $ahead->{pos}->{start} : pos( $self->{string} );
    my $delta = length($new_word) - length($old_word);

    $position->{length} += $delta;
    foreach my $v ( values %{ $self->{ranges} } ) {
        next if !$v || $v->{start} <= $position->{start};
        $v->{start} += $delta;
    }

    return
      if $position->{start} < 0
      || $position->{start} > $self->len;

    if ( $pos > $position->{start} ) {
        $pos += $delta;
    }
    else {
        $pos = $position->{start} + length($new_word);
    }

    substr $self->{string}, $position->{start}, length($old_word), $new_word;
    _pos( $self, $pos );
}

sub skip {
    my ( $self, $position ) = @_;

    _pos( $self, $position->{start} + $position->{length} );
}

sub _wrap {
    my ( $self, $start, $length ) = @_;

    my $key = sprintf "%d,%d", $start, $length;
    my $range = $self->{ranges}{$key};

    return $range if $range;

    $range = $self->{ranges}{$key} = { start => $start, length => $length };
    weaken( $self->{ranges}{$key} );

    return $range;
}

sub compare_range {
    return $_[0]->{start} <=> $_[1]->{start};
}

1;
