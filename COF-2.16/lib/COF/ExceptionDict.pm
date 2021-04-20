package COF::ExceptionDict;

use strict;
use warnings;
use utf8;
use Wx
  qw(wxOK wxYES_NO wxNO wxICON_ERROR wxCENTRE wxICON_EXCLAMATION wxICON_QUESTION);
use Wx::Event qw(EVT_LIST_ITEM_SELECTED EVT_BUTTON EVT_UPDATE_UI EVT_CLOSE
  EVT_SIZE);

use base 'COF::ExceptionDictBase';

sub new {
    my ( $class, $parent, $data ) = @_;

    my $self = $class->SUPER::new( $parent, -1 );
    $self->{list}->InsertColumn( 0, "Erôr" );
    $self->{list}->InsertColumn( 1, "Corezion" );

    $self->{my_data} = $data;

    EVT_SIZE( $self->{list}, \&on_listctrl_size );

    EVT_BUTTON( $self, $self->{add_btn},    \&on_add );
    EVT_BUTTON( $self, $self->{delete_btn}, \&on_delete );
    EVT_BUTTON( $self, $self->{change_btn}, \&on_change );
    EVT_BUTTON( $self, $self->{close_btn},  sub { $self->Destroy } );
    EVT_CLOSE( $self, sub { $self->Destroy } );

    EVT_LIST_ITEM_SELECTED( $self, $self->{list}, \&on_select );

    EVT_UPDATE_UI( $self, $self->{delete_btn},
        sub { $_[1]->Enable( $self->{list}->GetSelection != -1 ) } );
    EVT_UPDATE_UI(
        $self,
        $self->{change_btn},
        sub {
            my ( $error_word, $correct_word ) = (
                $self->{error_word_tc}->GetValue,
                $self->{correct_word_tc}->GetValue
            );
            $_[1]->Enable( $self->{list}->GetSelection != -1
                  && $error_word
                  && $correct_word
                  && $error_word ne $correct_word );
        }
    );

    on_listctrl_size( $self->{list} );
    $self->lei_peraulis_er_comun;

    return $self;
}

sub _data { $_[0]->{my_data}; }

sub _is_dict_ok {
    my $self = shift;
    if ( !$self->_data->has_user_exc ) {
        Wx::MessageBox(
            "Il dizionari des ecezions  nol esist.", "Erôr",
            wxOK | wxCENTRE | wxICON_ERROR,          $self
        );
        return 0;
    }
    return 1;
}

sub lei_peraulis_er_comun {
    my $self = shift;

    return unless $self->_is_dict_ok;

    my $HASH_ERR = $self->_data->get_user_exc;

    my $list_ctrl = $self->{list};
    $list_ctrl->Show(0);
    my $busy = Wx::BusyCursor->new();
    $list_ctrl->DeleteAllItems();

    my $tot = 0;
    foreach my $par ( COF::Data::sort_friulian( keys %$HASH_ERR ) ) {
        $list_ctrl->InsertStringItem( $tot, $par );
        my $cor = $HASH_ERR->{$par};
        $list_ctrl->SetItemText( $tot, 1, $cor );
        ++$tot;
    }

    $list_ctrl->Show(1);

    $self->{word_count_lab}->SetLabel("$tot");
}

sub on_listctrl_size {
    my ( $self, $event ) = @_;
    my ( $w,    $h )     = $self->GetClientSizeXY;

    my ( $wl, $wr ) = ( $w / 2, $w / 2 );

    if ($event) {
        my ( $tw, $th ) = ( $event->GetSize->x, $event->GetSize->y );
        $wl += ( $tw - $w ) / 2;
        $wr -= ( $tw - $w ) / 2;
    }

    $self->SetColumnWidth( 0, $wl );
    $self->SetColumnWidth( 1, $wr );

    $event->Skip if $event;
}

sub on_select {
    my ( $self, $event ) = @_;
    my $list_ctrl = $self->{list};
    my $sel       = $list_ctrl->GetSelection;

    $self->{error_word_tc}->SetValue( $list_ctrl->GetItemText( $sel, 0 ) );
    $self->{correct_word_tc}->SetValue( $list_ctrl->GetItemText( $sel, 1 ) );
}

sub on_add {
    my ( $self, $event ) = @_;

    return unless $self->_is_dict_ok;

    my $sostituis_er_comun = $self->{error_word_tc};
    my $cun_er_comun       = $self->{correct_word_tc};

    my $ok  = $sostituis_er_comun->GetValue;
    my $err = $cun_er_comun->GetValue;

    my $HASH_ERR = $self->_data->get_user_exc;

    if ( $ok eq '' || $err eq '' ) {
        Wx::MessageBox(
            "Scrîf la peraule falade", "Atenzion",
            wxOK | wxICON_EXCLAMATION,  $self,
        );
        return;
    }
    elsif ( exists $HASH_ERR->{$ok} ) {
        Wx::MessageBox( "Peraule falade za presinte tal database",
            "Atenzion", wxOK | wxICON_EXCLAMATION, $self );
        return;
    }
    else {
        $HASH_ERR->{$ok} = $err;

        $sostituis_er_comun->SetValue('');
        $cun_er_comun->SetValue('');
    }

    $self->lei_peraulis_er_comun;
}

sub on_delete {
    my ( $self, $event ) = @_;

    return unless $self->_is_dict_ok;

    return
      if Wx::MessageBox(
        "Sêstu sigûr di cancelâ la rie?", "Atenzion",
        wxYES_NO | wxICON_QUESTION,          $self
      ) == wxNO;

    my $HASH_ERR = $self->_data->get_user_exc;

    my $list_ctrl = $self->{list};
    my $da_canc   = $list_ctrl->GetSelection;
    delete $HASH_ERR->{ $list_ctrl->GetItemText( $da_canc, 0 ) };

    $self->{error_word_tc}->SetValue('');
    $self->{correct_word_tc}->SetValue('');

    $self->lei_peraulis_er_comun;
}

sub on_change {
    my ( $self, $event ) = @_;

    return unless $self->_is_dict_ok;

    my $HASH_ERR = $self->_data->get_user_exc;

    my $list_ctrl          = $self->{list};
    my $sostituis_er_comun = $self->{error_word_tc};
    my $cun_er_comun       = $self->{correct_word_tc};

    my $da_canc  = $list_ctrl->GetSelection;
    my $err      = $list_ctrl->GetItemText( $da_canc, 0 );
    my $err_text = $sostituis_er_comun->GetValue();

    my $ok = $list_ctrl->GetItemText( $da_canc, 1 );
    my $ok_text = $cun_er_comun->GetValue();

    if ( $err_text eq $err ) {
        if ( $ok_text eq $ok ) {
            Wx::MessageBox(
                "Nissun cambiament",       "Atenzion",
                wxOK | wxICON_EXCLAMATION, $self
            );
            return;
        }
        $HASH_ERR->{$err} = $ok_text;
    }
    else {
        delete $HASH_ERR->{$err};
        $HASH_ERR->{$err_text} = $ok_text;
    }

    $sostituis_er_comun->SetValue('');
    $cun_er_comun->SetValue('');

    $self->lei_peraulis_er_comun;
}

1;
