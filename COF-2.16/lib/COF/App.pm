package COF::App;

use strict;
use warnings;
use utf8;
use File::Spec;

use COF::Data;
use COF::Frame;
use COF::Utils;

use Wx;

use base 'Wx::App';

sub get_res_file {
    shift;
    my @df = @_;

    return File::Spec->catfile( get_res_dir(), @df );
}

sub get_user_file {
    shift;
    my $df = shift;

    return File::Spec->catfile( get_user_dir(), $df );
}

sub get_icon {
    my $class = shift;
    my $bndl  = Wx::IconBundle->new;

    Wx::Image::AddHandler( Wx::ICOHandler->new );

    foreach my $icon (qw(cof16 cof32 cof48 cof128)) {
        $bndl->AddIcon( $class->get_res_file( "icons", "$icon.ico" ),
            Wx::wxBITMAP_TYPE_ICO() );
    }

    return $bndl;
}

sub OnInit {
    my $self = shift;

    $self->SetVendorName('CdIF scarl');
    $self->SetAppName('COF2');

    my $frame =
      COF::Frame->new(
        COF::Data->new( COF::Data::make_default_args( get_dict_dir() ) ) );

    $frame->Show(1);

    1;
}

1;
