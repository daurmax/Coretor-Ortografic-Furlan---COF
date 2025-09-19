package COF::TextDisplay;

use strict;
use warnings;

use Wx;

sub new {
    my ( $class, $args ) = @_;
    my $self = bless { %{ $args || {} } }, $class;

    return $self;
}

sub goto_char {
    my ( $self, $pos ) = @_;

    $self->{fulltext}->ShowPosition( $pos->{start} );
}

sub clear_text {
    local $_[0]->{changing} = 1;

    my ($self) = @_;

    $self->{fulltext}->SetValue("");
}

my $COL_CORRECT = Wx::TextAttr->new( Wx::Colour->new( 0,   0,  0 ) );
my $COL_ERROR   = Wx::TextAttr->new( Wx::Colour->new( 255, 0,  0 ) );
my $COL_COMUN   = Wx::TextAttr->new( Wx::Colour->new( 255, 15, 255 ) );

sub set_text {
    local $_[0]->{changing} = 1;

    my ($self) = @_;

    $self->{fulltext}->SetValue( $_[1] );
}

sub _set_text {
    local $_[0]->{changing} = 1;

    my ( $self, $attr, $pos, $text ) = @_;

    my $length = defined($text) ? length($text) : $pos->{length};

    $self->{fulltext}
      ->Replace( $pos->{start}, $pos->{start} + $pos->{length}, $text )
      if defined $text;
    $self->{fulltext}
      ->SetStyle( $pos->{start}, $pos->{start} + $length, $attr );
}

sub set_correct_text {
    _set_text( $_[0], $COL_CORRECT, $_[1], $_[2] );
}

sub set_error_text {
    _set_text( $_[0], $COL_ERROR, $_[1], $_[2] );
}

sub set_comun_text {
    _set_text( $_[0], $COL_COMUN, $_[1], $_[2] );
}

sub show_correct_text {
    _set_text( $_[0], $COL_CORRECT, $_[1] );
}

sub show_error_text {
    _set_text( $_[0], $COL_ERROR, $_[1] );
}

sub show_comun_text {
    _set_text( $_[0], $COL_COMUN, $_[1] );
}

1;
