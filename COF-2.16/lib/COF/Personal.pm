package COF::Personal;

use strict;
use warnings;
use utf8;
use Wx
  qw(:sizer wxYES_NO wxYES wxNO wxOK wxICON_ERROR wxICON_EXCLAMATION wxICON_QUESTION wxCENTRE);
use Wx::Event qw(EVT_BUTTON EVT_LISTBOX EVT_UPDATE_UI EVT_CLOSE);

use base 'COF::PersonalBase';

sub new {
    my ( $class, $parent, $data ) = @_;

    my $self = $class->SUPER::new( $parent, -1 );

    $self->{my_data} = $data;

    EVT_BUTTON( $self, $self->{add_btn},    \&on_add );
    EVT_BUTTON( $self, $self->{delete_btn}, \&on_delete );
    EVT_BUTTON( $self, $self->{change_btn}, \&on_change );
    EVT_BUTTON( $self, $self->{close_btn},  sub { $self->Destroy } );
    EVT_CLOSE( $self, sub { $self->Destroy } );

    EVT_LISTBOX(
        $self,
        $self->{list},
        sub {
            return if $self->{list}->GetSelection == -1;
            $self->{word_tc}->SetValue( $self->{list}->GetStringSelection );
        }
    );

    EVT_UPDATE_UI( $self, $self->{delete_btn},
        sub { $_[1]->Enable( $self->{list}->GetSelection != -1 ) } );
    EVT_UPDATE_UI(
        $self,
        $self->{change_btn},
        sub {
            my $list_ctrl = $self->{list};
            my $word      = $self->{word_tc}->GetValue;
            $_[1]->Enable( $list_ctrl->GetSelection != -1
                  && $word
                  && $list_ctrl->GetStringSelection ne $word );
        }
    );

    $self->lei_peraulis;

    return $self;
}

sub _data { $_[0]->{my_data}; }

sub _is_dict_ok {
    my $self = shift;
    if ( !$self->_data->has_user_dict ) {
        Wx::MessageBox(
            "Il dizionari personâl nol esist.", "Erôr",
            wxOK | wxCENTRE | wxICON_ERROR,      $self
        );
        return 0;
    }
    return 1;
}

sub on_add {
    my ( $self, $event ) = @_;

    return unless $self->_is_dict_ok;

    my $text = $self->{word_tc}->GetValue();

    return unless $text;

    my $ok = $self->_data->add_user_dict($text);
    if ( $ok == 1 ) {
        Wx::MessageBox( "Nol è pussibil vierzi il database personâl.",
            "Erôr", wxOK | wxICON_ERROR, $self );
    }
    $self->lei_peraulis;
}

sub on_delete {
    my ( $self, $event ) = @_;

    return unless $self->_is_dict_ok;

    return
      if Wx::MessageBox( "Sêstu sigûr di cancelâ la peraule?",
        "Atenzion", wxYES_NO | wxICON_QUESTION, $self ) == wxNO;

    my $ok =
      $self->_data->delete_user_dict( $self->{list}->GetStringSelection );

    if ( $ok == 1 ) {
        Wx::MessageBox( "Nol è pussibil vierzi il database personâl.",
            "Erôr", wxOK | wxICON_ERROR, $self );
    }
    elsif ( $ok == 2 ) {
        Wx::MessageBox( "Peraule za presinte tal database personâl",
            "Atenzion", wxOK | wxICON_EXCLAMATION, $self );
    }

    $self->lei_peraulis;
}

sub on_change {
    my ( $self, $event ) = @_;

    return unless $self->_is_dict_ok;

    my $text = $self->{word_tc}->GetValue();
    my $item = $self->{list}->GetStringSelection;

    my $ok = $self->_data->change_user_dict( $text, $item );
    if ( $ok == 1 ) {
        Wx::MessageBox( "Nol è pussibil vierzi il database personâl.",
            "Erôr", wxOK | wxICON_ERROR, $self );
    }
    $self->lei_peraulis;

}

sub lei_peraulis {
    my ($self) = @_;

    return unless $self->_is_dict_ok;

    my $list_ctrl = $self->{list};
    my %all_parole;

    my $busy = Wx::BusyCursor->new();
    $list_ctrl->Show(0);
    $list_ctrl->Clear;

    for my $val ( values %{ $self->_data->get_user_dict } ) {
        foreach my $par ( split /,/, $val ) {
            $all_parole{$par} = 1;
        }
    }

    my $tot = scalar keys %all_parole;
    $list_ctrl->Append($_) foreach COF::Data::sort_friulian( keys %all_parole );

    $list_ctrl->Show(1);

    $self->{word_count_lab}->SetLabel("$tot");
}

1;
