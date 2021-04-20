package COF::FastChecker;

use strict;
use warnings;
use utf8;
use COF::WordIterator;
use COF::SpellChecker;

use COF::Letters qw($FUR_APOSTROPHS $FUR_LETTERS);

my $slash_w_s = "[$FUR_LETTERS$FUR_APOSTROPHS]";
my $slash_W_s = "[^$FUR_LETTERS$FUR_APOSTROPHS]";
my $slash_b_s =
  "(?:(?<=$slash_W_s)(?=$slash_w_s)|(?<=$slash_w_s)(?=$slash_W_s))";

sub new {
    my ( $class, $data, $display ) = @_;
    my $self = bless {
        data        => $data,
        display     => $display,
        iterator    => undef, checker => COF::SpellChecker->new($data),
        complet     => 1, string => '',
        errors      => [],  undo => [],
        autocorrect => {}, finished => 0,
    }, $class;

    return $self;
}

sub get_data { $_[0]->{data} }

sub set_text {
    my ( $self, $text ) = @_;

    $self->{errors}   = [];
    $self->{undo}     = [];
    $self->{string}   = defined $text ? $text : '';
    $self->{iterator} = COF::WordIterator->new($text);

    $self->{display}->clear_text;
    $self->{display}->set_text($text);
    $self->{display}->set_undo(0);
    $self->{finished}    = 0;
    $self->{autocorrect} = {};
}

sub set_progress { $_[0]->{progress} = $_[1] }

sub set_complet {
    my ( $self, $complet ) = @_;

    return if $self->{complet} == !!$complet;
    $self->{complet} = !!$complet;
    if ( $self->{iterator} ) {
        $self->{iterator}->reset;
    }
}

sub set_position { $_[0]->{iterator}->set_pos( $_[1] ) }

sub get_complet   { $_[0]->{complet} }
sub set_finito    { $_[0]->{finished} = $_[1] }
sub get_finito    { $_[0]->{finished} }
sub current_error { $_[0]->{errors}[0][1]{word} }

sub _clear_errors {
    my ($self) = @_;
    my $display = $self->{display};

    $display->show_correct_text( $_->[1]->{pos} ) foreach @{ $self->{errors} };
    $self->{errors} = [];
}

sub add_error {
    my ( $self, $error ) = @_;

    _clear_errors($self) if !$self->{complet};
    unshift @{ $self->{errors} }, $error;
}

sub add_errors {
    my ( $self, @err ) = @_;
    my $cmp = $self->{iterator}->can('compare_range');

    $self->{errors} =
      [ sort { $cmp->( $a->[1]{pos}, $b->[1]{pos} ) }
          ( @{ $self->{errors} }, @err ) ];
}

sub search_phrase {
    my ($self)  = @_;
    my $fast    = !$self->{complet};
    my $checker = $self->{checker};
    my $it      = $self->{iterator};
    my $display = $self->{display};

    _clear_errors($self) if $fast && @{ $self->{errors} };
    $self->{finished} = 0;

    while ( my $tok = $it->next ) {

        next if $tok->{type} ne 'WORD';
        my $word = $tok->{word};
        my $auto = $fast ? $self->{autocorrect}->{$word} : undef;
        if ( $auto && $auto->{skip} ) {
            next;
        }

        my $ans = $checker->check_word($word);

        if ( !$ans->ok ) {
            if ( $auto && $auto->{correct} ) {
                $self->_change_cmn( [ $ans, $tok ], $auto->{correct} );
                next;
            }

            if ( my $apost = $tok->{subtype} )
            { unless ( $checker->is_error($word) )
                { if (
                        ( $apost eq 'AFTER' )
                        && ( COF::Data::lc_word( substr( $word, -2, -1 ) ) eq
                            "c" )
                      )
                    {
                        ;
                    }
                    else {
                        $it->unshift_current_fix_apos();
                        next;
                    }
                }
            }
            else { if ( my $next_tok = $it->next ) {
                    if ( $next_tok->{type} eq 'POINT' ) {
                        my $new_word = $word . ".";
                        my $new_asw  = $checker->check_word($new_word);
                        if ( $new_asw->ok ) { $it->reset_current();
                            next;
                        }
                        elsif ( $checker->is_error($new_word) )
                        { $tok->{word} = $new_word;
                            $tok->{pos}->{length}++;
                            $it->reset_current();
                        }
                        else { $it->unshift_current();
                        }
                    }
                }
            }

            $display->show_error_text( $tok->{pos} );
            push @{ $self->{errors} }, [ $ans, $tok ];
            last if $fast;
        }
    }

    $self->_show_first_error;

    return scalar @{ $self->{errors} };
}

sub _show_error {
    my ( $self, $error ) = @_;

    my $suggs = $self->{checker}->suggest( $error->[0] );
    $self->{display}->set_choices( $suggs, $error->[0]->word );
    $self->{display}->goto_char( $error->[1]->{pos} );
}

sub backup_undo {
    my ( $self,   $args ) = @_;
    my ( $method, @args ) = @$args;

    $self->{display}->set_undo(1);
    push @{ $self->{undo} },
      [
        $method,
        COF::FastChecker::Undo->new(
            {
                pos => $self->{iterator}->get_pos,
                @args
            }
        )
      ];
}

sub undo {
    my ($self) = @_;
    return if !$self->{undo} || !@{ $self->{undo} };
    my ( $method, $undo ) = @{ pop @{ $self->{undo} } };

    $self->{display}->set_undo( @{ $self->{undo} } ? 1 : 0 );
    $undo->$method($self);
}

sub _method {
    my ($to) = @_;
    return
        $to eq 'error'        ? 'set_error_text'
      : $to eq 'correct'      ? 'set_correct_text'
      : $to eq 'show_error'   ? 'show_error_text'
      : $to eq 'show_correct' ? 'show_correct_text'
      :                         die "Wrong value: '$to'";
}

sub _change {
    my ( $self, $to, $pos, $new_word, $old_word ) = @_;
    my $meth    = _method($to);
    my $display = $self->{display};

    $display->$meth( $pos, $new_word );

    if ( defined $new_word ) {
        $self->{iterator}->change( $pos, $new_word, $old_word );
    }
    else {
        $self->{iterator}->skip($pos);
    }
}

sub _change_all {
    my ( $self, $to, $err, $undo_ent, $new_word ) = @_;
    my $meth    = _method($to);
    my $display = $self->{display};
    my @new_errors;

    my $change_err_word = $err->[1]{word};
    foreach my $error ( @{ $self->{errors} } ) {
        if ( $error->[1]{word} eq $change_err_word ) {
            $display->$meth( $error->[1]{pos}, $new_word );
            $self->{iterator}
              ->change( $error->[1]{pos}, $new_word, $error->[1]{word} )
              if defined $new_word;
            push @{ $undo_ent->[1]->{errors} }, $error if $undo_ent;
        }
        else {
            push @new_errors, $error if $undo_ent;
        }
    }

    $self->{errors} = \@new_errors if $undo_ent;
}

sub _show_first_error {
    my ($self) = @_;

    if ( @{ $self->{errors} } ) {
        $self->_show_error( $self->{errors}[0] );
    }
    else {
        $self->{finished} = 1;
    }
}

sub _change_cmn {
    my ( $self, $err, $new_word ) = @_;

    $self->backup_undo(
        [
            'change',
            error    => $err,
            new_word => $new_word
        ]
    );
    $self->_change( 'correct', $err->[1]{pos}, $new_word, $err->[1]{word} );
}

sub change {
    my ( $self, $new_word ) = @_;

    $self->_change_cmn( shift( @{ $self->{errors} } ), $new_word );
    if ( $self->{complet} ) {
        $self->_show_first_error;
    }
    else {
        $self->search_phrase;
    }
}

sub change_all {
    my ( $self, $new_word ) = @_;
    my $err = $self->{errors}[0];

    if ( !$self->{complet} ) {
        $self->{autocorrect}->{ $err->[1]{word} } = { correct => $new_word };
        $self->change($new_word);
    }
    else {
        $self->backup_undo(
            [
                'change_all',
                error    => $err,
                new_word => $new_word
            ]
        );
        $self->_change_all( 'correct', $err, $self->{undo}[-1], $new_word );
        $self->_show_first_error;
    }
}

sub _skip_cmn {
    my ( $self, $err ) = @_;

    $self->backup_undo( [ 'skip', error => $err ] );
    $self->_change( 'show_correct', $err->[1]{pos}, undef, undef );
}

sub skip {
    my ($self) = @_;

    $self->_skip_cmn( shift( @{ $self->{errors} } ) );
    $self->search_phrase unless $self->{complet};
    $self->_show_first_error;
}

sub skip_all {
    my ($self) = @_;
    my $err = $self->{errors}[0];

    if ( !$self->{complet} ) {
        $self->{autocorrect}->{ $err->[1]{word} } = { skip => 1 };
        $self->skip;
    }
    else {
        $self->backup_undo( [ 'skip_all', error => $err ] );
        $self->_change_all( 'show_correct', $err, $self->{undo}[-1], undef );
        $self->_show_first_error;
    }
}

sub go_back {
    my ($self) = @_;

    $self->_show_first_error;
}

package COF::FastChecker::Undo;

use strict;
use warnings;

sub new {
    my ( $class, $args ) = @_;
    my $self = bless {%$args}, $class;

    return $self;
}

sub _change {
    my ( $self, $checker, $how, $word ) = @_;
    my $err   = $self->error;
    my $token = $self->token;

    $checker->add_error( $self->{error} );
    $checker->_change( $how, $token->{pos},
        defined($word)
        ? ( $token->{word}, $self->corrected_word )
        : ( undef, undef ) );
    $checker->set_position( $self->pos );
    $checker->_show_error( $self->{error} );
}

sub _change_all {
    my ( $self, $checker, $how, $word ) = @_;
    my $token  = $self->token;
    my $errors = $self->errors;

    $checker->add_errors(@$errors);
    $checker->_change_all( $how, $self->{error}, undef,
        defined($word) ? $token->{word} : undef );
    $checker->set_position( $self->pos );
    $checker->_show_error( $errors->[0] );
}

sub change {
    my ( $self, $checker ) = @_;

    $self->_change( $checker, 'error', $self->corrected_word );
}

sub change_all {
    my ( $self, $checker ) = @_;

    $self->_change_all( $checker, 'error', $self->corrected_word );
}

sub skip {
    my ( $self, $checker ) = @_;

    $self->_change( $checker, 'show_error', undef );
}

sub skip_all {
    my ( $self, $checker ) = @_;

    $self->_change_all( $checker, 'show_error', undef );
}

sub errors         { $_[0]->{errors} }
sub error          { $_[0]->{error}[0] }
sub token          { $_[0]->{error}[1] }
sub corrected_word { $_[0]->{new_word} }
sub pos            { $_[0]->{pos} }

1;
