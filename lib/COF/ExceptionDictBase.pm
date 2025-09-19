
use Wx 0.15;
use strict;
use Wx::Perl::ListCtrl;

package COF::ExceptionDictBase;

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
    $self->{label_2} =
      Wx::StaticText->new( $self, wxID_ANY, "Sostitu\xecs", wxDefaultPosition,
        wxDefaultSize, );
    $self->{label_3} =
      Wx::StaticText->new( $self, wxID_ANY, "cun:", wxDefaultPosition,
        wxDefaultSize, );
    $self->{error_word_tc} =
      Wx::TextCtrl->new( $self, wxID_ANY, "", wxDefaultPosition, wxDefaultSize,
      );
    $self->{correct_word_tc} =
      Wx::TextCtrl->new( $self, wxID_ANY, "", wxDefaultPosition, wxDefaultSize,
      );
    $self->{add_btn} = Wx::Button->new( $self, wxID_ANY, "&Zonte" );
    $self->{list} = Wx::Perl::ListCtrl->new(
        $self,
        wxID_ANY,
        wxDefaultPosition,
        wxDefaultSize,
        wxLC_REPORT | wxLC_SINGLE_SEL | wxLC_VRULES | wxLC_HRULES |
          wxLC_NO_HEADER
    );
    $self->{change_btn} = Wx::Button->new( $self, wxID_ANY, "&Cambie" );
    $self->{delete_btn} = Wx::Button->new( $self, wxID_ANY, "C&ancele" );
    $self->{label_4} = Wx::StaticText->new( $self, wxID_ANY, "Tot peraulis:",
        wxDefaultPosition, wxDefaultSize, );
    $self->{word_count_lab} =
      Wx::StaticText->new( $self, wxID_ANY, "0", wxDefaultPosition,
        wxDefaultSize, );
    $self->{static_line_1} =
      Wx::StaticLine->new( $self, wxID_ANY, wxDefaultPosition, wxDefaultSize, );
    $self->{close_btn} = Wx::Button->new( $self, wxID_CLOSE, "&Siere" );

    $self->__set_properties();
    $self->__do_layout();

    return $self;

}

sub __set_properties {
    my $self = shift;
    $self->SetTitle("Gjestion des ecezions");
    $self->SetSize( Wx::Size->new( 600, 450 ) );
    $self->{close_btn}->SetDefault();
}

sub __do_layout {
    my $self = shift;
    $self->{sizer_1}      = Wx::BoxSizer->new(wxVERTICAL);
    $self->{grid_sizer_1} = Wx::FlexGridSizer->new( 3, 2, 5, 5 );
    $self->{sizer_3}      = Wx::BoxSizer->new(wxVERTICAL);
    $self->{sizer_6}      = Wx::BoxSizer->new(wxHORIZONTAL);
    $self->{sizer_2}      = Wx::BoxSizer->new(wxHORIZONTAL);
    $self->{sizer_2}->Add( $self->{label_2}, 1, 0, 0 );
    $self->{sizer_2}->Add( $self->{label_3}, 1, 0, 0 );
    $self->{grid_sizer_1}->Add( $self->{sizer_2}, 1, wxEXPAND, 0 );
    $self->{grid_sizer_1}->Add( 20, 20, 0, 0, 0 );
    $self->{sizer_6}
      ->Add( $self->{error_word_tc}, 1, wxALIGN_CENTER_VERTICAL, 0 );
    $self->{sizer_6}
      ->Add( $self->{correct_word_tc}, 1, wxALIGN_CENTER_VERTICAL, 0 );
    $self->{grid_sizer_1}->Add( $self->{sizer_6}, 0, wxEXPAND, 0 );
    $self->{grid_sizer_1}
      ->Add( $self->{add_btn}, 0, wxALIGN_CENTER_VERTICAL, 0 );
    $self->{grid_sizer_1}->Add( $self->{list}, 1, wxEXPAND, 0 );
    $self->{sizer_3}->Add( $self->{change_btn}, 0, 0, 0 );
    $self->{sizer_3}->Add( $self->{delete_btn}, 0, wxTOP | wxBOTTOM, 5 );
    $self->{sizer_3}->Add( 20, 20, 1, wxEXPAND, 0 );
    $self->{sizer_3}->Add( $self->{label_4},        0, wxLEFT, 5 );
    $self->{sizer_3}->Add( $self->{word_count_lab}, 0, wxLEFT, 5 );
    $self->{grid_sizer_1}->Add( $self->{sizer_3}, 1, wxEXPAND, 0 );
    $self->{grid_sizer_1}->AddGrowableRow(2);
    $self->{grid_sizer_1}->AddGrowableCol(0);
    $self->{sizer_1}
      ->Add( $self->{grid_sizer_1}, 1, wxLEFT | wxRIGHT | wxTOP | wxEXPAND,
        10 );
    $self->{sizer_1}->Add( $self->{static_line_1}, 0, wxTOP | wxEXPAND, 10 );
    $self->{sizer_1}->Add( $self->{close_btn}, 0,
        wxTOP | wxBOTTOM | wxALIGN_CENTER_HORIZONTAL, 10 );
    $self->SetSizer( $self->{sizer_1} );
    $self->Layout();
    $self->Centre();
}

1;

