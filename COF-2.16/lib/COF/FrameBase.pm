
use Wx 0.15;
use strict;

package COF::FrameBase;

use Wx qw[:everything];
use base qw(Wx::Frame);
use strict;
sub Wx::SYS_COLOUR_MENU { return wxSYS_COLOUR_MENU;
}

sub new {
    my ( $self, $parent, $id, $title, $pos, $size, $style, $name ) = @_;
    $parent = undef             unless defined $parent;
    $id     = -1                unless defined $id;
    $title  = ""                unless defined $title;
    $pos    = wxDefaultPosition unless defined $pos;
    $size   = wxDefaultSize     unless defined $size;
    $name   = ""                unless defined $name;

    $style = wxDEFAULT_FRAME_STYLE
      unless defined $style;

    $self =
      $self->SUPER::new( $parent, $id, $title, $pos, $size, $style, $name );

    $self->{frame_1_menubar} = Wx::MenuBar->new();
    my $wxglade_tmp_menu;
    $wxglade_tmp_menu = Wx::Menu->new();
    $self->{user_dict_mitem} =
      $wxglade_tmp_menu->Append( wxID_ANY, "Gjestion &dizionari person\xe2l",
        "" );
    $self->{user_exc_mitem} =
      $wxglade_tmp_menu->Append( wxID_ANY, "Gjestion &ecezions", "" );
    $self->{exit_mitem} =
      $wxglade_tmp_menu->Append( wxID_EXIT, "&Va f\xfbr", "" );
    $self->{frame_1_menubar}->Append( $wxglade_tmp_menu, "&File" );
    $wxglade_tmp_menu = Wx::Menu->new();
    $self->{help_mitem} =
      $wxglade_tmp_menu->Append( wxID_ANY, "I&struzions", "" );
    $self->{about_mitem} =
      $wxglade_tmp_menu->Append( wxID_ABOUT, "&Informazions", "" );
    $self->{userdir_mitem} =
      $wxglade_tmp_menu->Append( wxID_ANY, "D\xe2ts &Utent", "" );
    $self->{frame_1_menubar}->Append( $wxglade_tmp_menu, "&Jutori" );
    $self->SetMenuBar( $self->{frame_1_menubar} );

    $self->{fulltext_tc} =
      Wx::TextCtrl->new( $self, wxID_ANY, "", wxDefaultPosition, wxDefaultSize,
        wxTE_PROCESS_ENTER | wxTE_MULTILINE | wxTE_RICH2 );
    $self->{complete_cb} =
      Wx::CheckBox->new( $self, wxID_ANY, "co&mplet", wxDefaultPosition,
        wxDefaultSize, );
    $self->{check_btn} =
      Wx::Button->new( $self, wxID_ANY, "&Control ortografic" );
    $self->{state_bmp} =
      Wx::StaticBitmap->new( $self, wxID_ANY, wxNullBitmap, wxDefaultPosition,
        wxDefaultSize, );
    $self->{label_1} =
      Wx::StaticText->new( $self, wxID_ANY, "Peraule", wxDefaultPosition,
        wxDefaultSize, );
    $self->{word_tc} =
      Wx::TextCtrl->new( $self, wxID_ANY, "", wxDefaultPosition, wxDefaultSize,
      );
    $self->{label_2} =
      Wx::StaticText->new( $self, wxID_ANY, "Propuestis", wxDefaultPosition,
        wxDefaultSize, );
    $self->{suggestions_list} =
      Wx::ListBox->new( $self, wxID_ANY, wxDefaultPosition, wxDefaultSize, [],
      );
    $self->{change_btn} = Wx::Button->new( $self, wxID_ANY, "C&ambie" );
    $self->{change_all_btn} =
      Wx::Button->new( $self, wxID_ANY, "Cam&bie par dut" );
    $self->{skip_btn} = Wx::Button->new( $self, wxID_ANY, "&Lasse" );
    $self->{skip_all_btn} =
      Wx::Button->new( $self, wxID_ANY, "La&sse par dut" );
    $self->{add_btn}   = Wx::Button->new( $self, wxID_ANY, "&Zonte" );
    $self->{undo_btn}  = Wx::Button->new( $self, wxID_ANY, "&Inda\xfbr" );
    $self->{paste_btn} = Wx::Button->new( $self, wxID_ANY, "Incole il test" );
    $self->{copy_btn}  = Wx::Button->new( $self, wxID_ANY, "Copie il test" );
    $self->{clear_btn} = Wx::Button->new( $self, wxID_ANY, "Cancele dut" );
    $self->{sizer_13_staticbox} = Wx::StaticBox->new( $self, wxID_ANY, "Test" );

    $self->__set_properties();
    $self->__do_layout();

    return $self;

}

sub __set_properties {
    my $self = shift;
    $self->SetTitle("Coret\xf4r Ortografic Furlan");
    $self->SetBackgroundColour(
        Wx::SystemSettings::GetColour(Wx::SYS_COLOUR_MENU) );
    $self->{check_btn}->SetDefault();
    $self->{word_tc}->SetMinSize( Wx::Size->new( 250, 21 ) );
    $self->{suggestions_list}->SetMinSize( Wx::Size->new( 250, 120 ) );
    $self->{suggestions_list}->SetSelection(0);
}

sub __do_layout {
    my $self = shift;
    $self->{sizer_9}  = Wx::BoxSizer->new(wxVERTICAL);
    $self->{sizer_10} = Wx::BoxSizer->new(wxVERTICAL);
    $self->{sizer_12} = Wx::BoxSizer->new(wxHORIZONTAL);
    $self->{sizer_13_staticbox}->Lower();
    $self->{sizer_13} =
      Wx::StaticBoxSizer->new( $self->{sizer_13_staticbox}, wxVERTICAL );
    $self->{sizer_6}      = Wx::BoxSizer->new(wxVERTICAL);
    $self->{sizer_7}      = Wx::BoxSizer->new(wxHORIZONTAL);
    $self->{grid_sizer_1} = Wx::FlexGridSizer->new( 4, 2, 5, 5 );
    $self->{sizer_8}      = Wx::BoxSizer->new(wxVERTICAL);
    $self->{sizer_11}     = Wx::BoxSizer->new(wxHORIZONTAL);
    $self->{sizer_10}->Add( $self->{fulltext_tc}, 1, wxEXPAND, 0 );
    $self->{sizer_11}
      ->Add( $self->{complete_cb}, 0, wxRIGHT | wxALIGN_CENTER_VERTICAL, 14 );
    $self->{sizer_11}
      ->Add( $self->{check_btn}, 0, wxRIGHT | wxALIGN_CENTER_VERTICAL, 5 );
    $self->{sizer_11}->Add( $self->{state_bmp}, 0, wxALIGN_CENTER_VERTICAL, 0 );
    $self->{sizer_10}->Add( $self->{sizer_11}, 0,
        wxTOP | wxBOTTOM | wxALIGN_CENTER_HORIZONTAL, 8 );
    $self->{sizer_6}->Add( $self->{label_1},          0, 0,        0 );
    $self->{sizer_8}->Add( $self->{word_tc},          0, wxEXPAND, 0 );
    $self->{sizer_8}->Add( $self->{label_2},          0, wxTOP,    5 );
    $self->{sizer_8}->Add( $self->{suggestions_list}, 1, wxEXPAND, 0 );
    $self->{sizer_7}->Add( $self->{sizer_8},          1, wxEXPAND, 0 );
    $self->{grid_sizer_1}->Add( $self->{change_btn},     0, 0,        0 );
    $self->{grid_sizer_1}->Add( $self->{change_all_btn}, 0, 0,        0 );
    $self->{grid_sizer_1}->Add( $self->{skip_btn},       0, 0,        0 );
    $self->{grid_sizer_1}->Add( $self->{skip_all_btn},   0, wxEXPAND, 0 );
    $self->{grid_sizer_1}->Add( $self->{add_btn},        0, 0,        0 );
    $self->{grid_sizer_1}->Add( 20, 20, 0, 0, 0 );
    $self->{grid_sizer_1}->Add( $self->{undo_btn}, 0, 0, 0 );
    $self->{grid_sizer_1}->Add( 20, 20, 0, 0, 0 );
    $self->{sizer_7}->Add( $self->{grid_sizer_1}, 0, wxLEFT | wxEXPAND, 5 );
    $self->{sizer_6}->Add( $self->{sizer_7},      1, wxEXPAND,          0 );
    $self->{sizer_12}->Add( $self->{sizer_6}, 0, wxEXPAND, 0 );
    $self->{sizer_12}->Add( 20, 20, 1, wxEXPAND, 0 );
    $self->{sizer_13}->Add( $self->{paste_btn}, 0, wxALL | wxEXPAND, 5 );
    $self->{sizer_13}
      ->Add( $self->{copy_btn}, 0, wxLEFT | wxRIGHT | wxBOTTOM | wxEXPAND, 5 );
    $self->{sizer_13}
      ->Add( $self->{clear_btn}, 0, wxLEFT | wxRIGHT | wxBOTTOM | wxEXPAND, 5 );
    $self->{sizer_12}->Add( $self->{sizer_13}, 0, 0,        5 );
    $self->{sizer_10}->Add( $self->{sizer_12}, 0, wxEXPAND, 0 );
    $self->{sizer_9}->Add( $self->{sizer_10}, 1, wxALL | wxEXPAND, 5 );
    $self->SetSizer( $self->{sizer_9} );
    $self->{sizer_9}->Fit($self);
    $self->Layout();
}

1;

