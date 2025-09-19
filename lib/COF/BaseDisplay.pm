package COF::BaseDisplay;

use strict;
use warnings;

sub new {
    my ( $class, $args ) = @_;
    my $self = bless { %{ $args || {} } }, $class;

    return $self;
}

sub set_choices { shift->{frame}{controls}->set_choices(@_) }
sub set_undo    { shift->{frame}{controls}->set_undo(@_); }

1;
