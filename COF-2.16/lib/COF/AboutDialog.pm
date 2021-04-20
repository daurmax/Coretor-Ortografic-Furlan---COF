
use Wx 0.15;
use strict;

package COF::AboutDialog;

use Wx qw[:everything];
use base qw(Wx::Dialog);
use strict;

sub new {
    my ( $self, $parent, $id, $title, $pos, $size, $style, $name ) = @_;
    $parent = undef             unless defined $parent;
    $id     = -1                unless defined $id;
    $title  = ""                unless defined $title;
    $pos    = wxDefaultPosition unless defined $pos;
    $size   = wxDefaultSize     unless defined $size;
    $name   = ""                unless defined $name;

    $style = wxDEFAULT_DIALOG_STYLE
      unless defined $style;

    $self =
      $self->SUPER::new( $parent, $id, $title, $pos, $size, $style, $name );
    $self->{cof_bitmap} =
      Wx::StaticBitmap->new( $self, wxID_ANY, wxNullBitmap, wxDefaultPosition,
        wxDefaultSize, );
    $self->{cof_label} =
      Wx::StaticText->new( $self, wxID_ANY, "Coret\xf4r Ortografic Furlan",
        wxDefaultPosition, wxDefaultSize, );
    $self->{info_label} =
      Wx::StaticText->new( $self, wxID_ANY, "info", wxDefaultPosition,
        wxDefaultSize, );
    $self->{label_1} =
      Wx::StaticText->new( $self, wxID_ANY,
        "Cooperative di Informazion Furlane S.C.A.R.L.",
        wxDefaultPosition, wxDefaultSize, );
    $self->{infofur_hyperlink} = Wx::HyperlinkCtrl->new(
        $self,
        wxID_ANY,
        "http://www.ondefurlane.eu",
        "http://www.ondefurlane.eu",
        wxDefaultPosition,
        wxDefaultSize,
        wxHL_ALIGN_CENTRE | wxHL_CONTEXTMENU | wxHL_DEFAULT_STYLE
    );
    $self->{label_7} =
      Wx::StaticText->new( $self, wxID_ANY,
        "ARLeF Agjenzie Regjon\xe2l pe lenghe furlane",
        wxDefaultPosition, wxDefaultSize, );
    $self->{arlef_hyperlink} = Wx::HyperlinkCtrl->new(
        $self,
        wxID_ANY,
        "http://www.arlef.it",
        "http://www.arlef.it",
        wxDefaultPosition,
        wxDefaultSize,
        wxHL_ALIGN_CENTRE | wxHL_CONTEXTMENU | wxHL_DEFAULT_STYLE
    );
    $self->{authors_label} =
      Wx::StaticText->new( $self, wxID_ANY, "", wxDefaultPosition,
        wxDefaultSize, );
    $self->{button_1} = Wx::Button->new( $self, wxID_OK, "" );

    $self->__set_properties();
    $self->__do_layout();

    return $self;

}

sub __set_properties {
    my $self = shift;
    $self->SetTitle("Informazions");
    $self->{button_1}->SetDefault();
}

sub __do_layout {
    my $self = shift;
    $self->{sizer_7} = Wx::BoxSizer->new(wxVERTICAL);
    $self->{sizer_8} = Wx::BoxSizer->new(wxHORIZONTAL);
    $self->{sizer_9} = Wx::BoxSizer->new(wxVERTICAL);
    $self->{sizer_8}->Add( $self->{cof_bitmap}, 0, 0,                   0 );
    $self->{sizer_9}->Add( $self->{cof_label},  0, 0,                   0 );
    $self->{sizer_9}->Add( $self->{info_label}, 0, wxBOTTOM | wxEXPAND, 10 );
    $self->{sizer_9}->Add( $self->{label_1},    0, 0,                   0 );
    $self->{sizer_9}
      ->Add( $self->{infofur_hyperlink}, 0, wxBOTTOM | wxEXPAND, 10 );
    $self->{sizer_9}->Add( $self->{label_7}, 0, wxEXPAND, 0 );
    $self->{sizer_9}
      ->Add( $self->{arlef_hyperlink}, 0, wxBOTTOM | wxEXPAND, 10 );
    $self->{sizer_9}->Add( $self->{authors_label}, 0, wxBOTTOM | wxEXPAND, 5 );
    $self->{sizer_8}->Add( $self->{sizer_9},       1, wxLEFT | wxEXPAND,   10 );
    $self->{sizer_7}->Add( $self->{sizer_8},       1, wxALL | wxEXPAND,    10 );
    $self->{sizer_7}
      ->Add( $self->{button_1}, 0, wxLEFT | wxRIGHT | wxBOTTOM | wxALIGN_RIGHT,
        10 );
    $self->SetSizer( $self->{sizer_7} );
    $self->{sizer_7}->Fit($self);
    $self->Layout();
}

1;

