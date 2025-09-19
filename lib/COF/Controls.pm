package COF::Controls;

use strict;
use warnings;

use utf8;

use Wx
  qw(:font :id :textctrl :sizer wxBITMAP_TYPE_BMP wxOK wxICON_INFORMATION wxICON_EXCLAMATION wxBU_EXACTFIT
  wxYES_NO wxYES wxNO);
use Wx::Event qw(EVT_CHAR EVT_LISTBOX EVT_LISTBOX_DCLICK EVT_BUTTON
  EVT_CHECKBOX EVT_TEXT);

sub new {
    my ( $class, $checker, $controls ) = @_;
    my $self = bless {
        checker  => $checker,
        controls => $controls
    }, $class;

    EVT_BUTTON( $controls->{gamb}, $controls->{gamb},
        sub { $self->change( $controls->{textfield}->GetValue ) } );
    EVT_BUTTON( $controls->{gamb_dut}, $controls->{gamb_dut},
        sub { $self->change_all( $controls->{textfield}->GetValue ) } );
    EVT_BUTTON( $controls->{lass}, $controls->{lass}, sub { $self->skip } );
    EVT_BUTTON( $controls->{lass_dut}, $controls->{lass_dut},
        sub { $self->skip_all } );
    EVT_BUTTON( $controls->{undo}, $controls->{undo}, sub { $self->undo } );
    EVT_LISTBOX( $controls->{choice}, $controls->{choice},
        sub { $self->select_choice( $_[1]->GetSelection ) } );
    EVT_LISTBOX_DCLICK(
        $controls->{choice},
        $controls->{choice},
        sub {
            $self->select_choice( $_[1]->GetSelection );
            $self->change( $controls->{textfield}->GetValue() );
        }
    );
    EVT_CHECKBOX( $controls->{complet}, $controls->{complet},
        sub { $self->complet_checked( $_[1]->IsChecked ) } );

    return $self;
}

sub finish {
    my ( $self, $show_message ) = @_;

    if ($show_message) {
        Wx::MessageBox(
            "Control ortografic finît", "",
            wxOK | wxICON_INFORMATION,   undef
        );
        $self->{'controls'}->{'frame'}->Close()
          if $self->{'controls'}->{'frame'};
    }
    $self->_checker->set_finito(1);
    $self->{controls}{$_}->Enable(0)
      foreach grep $self->{controls}{$_},
      qw(gamb lass gamb_dut lass_dut add_pers undo);
}

sub unfinish {
    my ($self) = @_;

    $self->_checker->set_finito(1);
    $self->{controls}{$_}->Enable(1)
      foreach grep $self->{controls}{$_},
      qw(gamb lass gamb_dut lass_dut add_pers);
}

sub change {
    my ( $self, $text ) = @_;

    if ( $self->_checker->get_finito ) {
        return;
    }
    if ( $text eq $self->_checker->current_error ) {
        Wx::MessageBox(
            "Selezione la propueste",  "Atenzion",
            wxOK | wxICON_EXCLAMATION, undef
        );
        return;
    }

    $self->_checker->change($text);
    $self->finish(1) if $self->_checker->get_finito;
}

sub change_all {
    my ( $self, $text, $skip_check ) = @_;

    if ( $self->_checker->get_finito ) {
        return;
    }
    if ( $text eq $self->_checker->current_error && !$skip_check ) {
        Wx::MessageBox(
            "Selezione la propueste",  "Atenzion",
            wxOK | wxICON_EXCLAMATION, undef
        );
        return;
    }

    $self->_checker->change_all($text);
    $self->finish(1) if $self->_checker->get_finito;
}

sub skip {
    my $self = shift;

    if ( $self->_checker->get_finito ) {
        return;
    }

    $self->_checker->skip;
    $self->finish(1) if $self->_checker->get_finito;
}

sub skip_all {
    my $self = shift;

    if ( $self->_checker->get_finito ) {
        return;
    }

    $self->_checker->skip_all;
    $self->finish(1) if $self->_checker->get_finito;
}

sub undo {
    my $self = shift;

    $self->_checker->undo();
}

sub select_choice {
    my ( $self, $selection ) = @_;

    return if $self->{no_choices} || $selection == -1;

    $self->{controls}{textfield}
      ->SetValue( $self->{controls}{choice}->GetString($selection) );
}

sub set_choices {
    my ( $self, $parole_trovate, $error ) = @_;

    $self->{controls}{choice}->Clear;

    my $conta_parole_result = 0;
    foreach my $parola (@$parole_trovate) {
        $self->{controls}{choice}->Append($parola);
        $conta_parole_result++;
        last if $conta_parole_result == 20;
    }

    $self->{controls}{textfield}->SetValue($error) if defined $error;
    $self->{controls}{choice}->Append("Nissune propueste")
      if !$conta_parole_result;
    $self->{no_choices} = $conta_parole_result ? 0 : 1;
}

sub set_undo {
    my ( $self, $undo ) = @_;

    $self->{controls}{undo}->Enable( $undo ? 1 : 0 );
}

sub complet_checked {
    my ( $self, $checked ) = @_;

    $self->_checker->set_complet($checked);

    my $cfg = Wx::ConfigBase::Get();
    $cfg->Write( "complet", $checked );
}

sub clear {
    my ($self) = @_;

    $self->{controls}{choice}->Clear;
    $self->{controls}{choice}->Append(" ");
    $self->{no_choices} = 1;

    $self->{controls}{textfield}->SetValue("");
    $self->{controls}{undo}->Enable(0);
}

sub no_choices { $_[0]->{no_choices} }

sub _checker { $_[0]->{checker} }

1;
