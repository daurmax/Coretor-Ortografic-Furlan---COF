
use Wx 0.15;
use strict;

package COF::PersonalBase;

use Wx qw[:everything];
use base qw(Wx::Dialog);
use strict;
{
    no warnings;
    sub wxTHICK_FRAME { return wxRESIZE_BORDER }
}

sub new {
    my ( $self, $parent, $id, $title, $pos, $size, $style, $name ) = @_;
    $parent = undef             unless defined $parent;
    $id     = -1                unless defined $id;
    $title  = ""                unless defined $title;
    $pos    = wxDefaultPosition unless defined $pos;
    $size   = wxDefaultSize     unless defined $size;
    $name   = ""                unless defined $name;

    $style = wxDEFAULT_DIALOG_STYLE | wxRESIZE_BORDER | wxTHICK_FRAME
      unless defined $style;

    $self =
      $self->SUPER::new( $parent, $id, $title, $pos, $size, $style, $name );
    $self->{label_5} =
      Wx::StaticText->new( $self, wxID_ANY, "Peraule", wxDefaultPosition,
        wxDefaultSize, );
    $self->{word_tc} =
      Wx::TextCtrl->new( $self, wxID_ANY, "", wxDefaultPosition, wxDefaultSize,
      );
    $self->{add_btn} = Wx::Button->new( $self, wxID_ANY, "&Zonte" );
    $self->{list} =
      Wx::ListBox->new( $self, wxID_ANY, wxDefaultPosition, wxDefaultSize, [],
      );
    $self->{change_btn} = Wx::Button->new( $self, wxID_ANY, "&Cambie" );
    $self->{delete_btn} = Wx::Button->new( $self, wxID_ANY, "C&ancele" );
    $self->{label_6} = Wx::StaticText->new( $self, wxID_ANY, "Tot peraulis:",
        wxDefaultPosition, wxDefaultSize, );
    $self->{word_count_lab} =
      Wx::StaticText->new( $self, wxID_ANY, "0", wxDefaultPosition,
        wxDefaultSize, );
    $self->{static_line_2} =
      Wx::StaticLine->new( $self, wxID_ANY, wxDefaultPosition, wxDefaultSize, );
    $self->{close_btn} = Wx::Button->new( $self, wxID_CLOSE, "&Siere" );

    $self->__set_properties();
    $self->__do_layout();

    return $self;

}

sub __set_properties {
    my $self = shift;
    $self->SetTitle("Gjestion dizionari person\xe2l");
    $self->SetSize( Wx::Size->new( 400, 450 ) );
    $self->{list}->SetSelection(0);
    $self->{close_btn}->SetDefault();
}

sub __do_layout {
    my $self = shift;
    $self->{sizer_4}      = Wx::BoxSizer->new(wxVERTICAL);
    $self->{grid_sizer_3} = Wx::FlexGridSizer->new( 3, 2, 5, 5 );
    $self->{sizer_5}      = Wx::BoxSizer->new(wxVERTICAL);
    $self->{grid_sizer_3}->Add( $self->{label_5}, 0, 0, 0 );
    $self->{grid_sizer_3}->Add( 20, 20, 0, wxEXPAND, 0 );
    $self->{grid_sizer_3}->Add( $self->{word_tc}, 0, wxEXPAND, 0 );
    $self->{grid_sizer_3}->Add( $self->{add_btn}, 0, 0,        0 );
    $self->{grid_sizer_3}->Add( $self->{list},    1, wxEXPAND, 0 );
    $self->{sizer_5}->Add( $self->{change_btn}, 0, 0, 0 );
    $self->{sizer_5}->Add( $self->{delete_btn}, 0, wxTOP | wxBOTTOM, 5 );
    $self->{sizer_5}->Add( 20, 20, 1, wxEXPAND, 0 );
    $self->{sizer_5}->Add( $self->{label_6},        0, wxLEFT, 5 );
    $self->{sizer_5}->Add( $self->{word_count_lab}, 0, wxLEFT, 5 );
    $self->{grid_sizer_3}->Add( $self->{sizer_5}, 1, wxEXPAND, 0 );
    $self->{grid_sizer_3}->AddGrowableRow(2);
    $self->{grid_sizer_3}->AddGrowableCol(0);
    $self->{sizer_4}->Add( $self->{grid_sizer_3},  1, wxALL | wxEXPAND, 10 );
    $self->{sizer_4}->Add( $self->{static_line_2}, 0, wxEXPAND,         0 );
    $self->{sizer_4}->Add( $self->{close_btn}, 0,
        wxTOP | wxBOTTOM | wxALIGN_CENTER_HORIZONTAL, 10 );
    $self->SetSizer( $self->{sizer_4} );
    $self->Layout();
    $self->Centre();
}

1;

