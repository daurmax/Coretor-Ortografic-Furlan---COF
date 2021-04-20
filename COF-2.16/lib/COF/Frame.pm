package COF::Frame;

use strict;
use warnings;
use utf8;
use List::Util qw(max);
use Try::Tiny;

use COF::Info;
use COF::Personal;
use COF::ExceptionDict;
use COF::FastChecker;
use COF::Controls;
use COF::Letters qw($FUR_APOSTROPHS);
use COF::AboutDialog;

use Wx 0.26;
use Wx::DND;
use Wx
  qw(:font :id :textctrl wxBITMAP_TYPE_BMP wxOK wxBU_EXACTFIT wxICON_INFORMATION wxICON_QUESTION wxICON_EXCLAMATION
  wxYES_NO wxYES wxNO wxSIZE_AUTO_HEIGHT wxICON_ERROR);
use Wx::Event qw(EVT_CHAR EVT_LISTBOX EVT_LISTBOX_DCLICK EVT_BUTTON
  EVT_MENU EVT_CHECKBOX EVT_TEXT);

use base qw(COF::FrameBase);

my ( $VERT, $ROS );
my $PERSONAL_DB = 'personal.db';
my $ECEZIONS_DB = 'ecezions.db';

sub new {
    my ( $class, $data ) = @_;
    my $self = $class->SUPER::new( undef, -1 );
    $self->MacSetMetalAppearance(1)
      if $self->can('MacSetMetalAppearance');

    $self->SetIcons( COF::App->get_icon );

    my $textbox = $self->{fulltext_tc};
    my $font = Wx::Font->new( 12, wxSWISS, wxNORMAL, wxNORMAL );
    $textbox->SetFont($font);

    my $cfg = Wx::ConfigBase::Get();

    my $display = COF::Display->new(
        {
            frame    => $self,
            fulltext => $textbox,
        }
    );
    my $checker = COF::FastChecker->new( $data, $display );
    $checker->set_complet( $cfg->Read( "complet", 1 ) );

    $VERT =
      Wx::Bitmap->new( COF::App->get_res_file('dv.bmp'), wxBITMAP_TYPE_BMP );
    $ROS =
      Wx::Bitmap->new( COF::App->get_res_file('dr.bmp'), wxBITMAP_TYPE_BMP );

    my $semaforo = $self->{state_bmp};
    $semaforo->SetBitmap($VERT);

    my $parzonte = $self->{add_btn};

    my $undo = $self->{undo_btn};
    $undo->Enable(0);

    my $contr         = $self->{check_btn};
    my $scanceledut   = $self->{clear_btn};
    my $getclip       = $self->{paste_btn};
    my $setclip       = $self->{copy_btn};
    my $check_complet = $self->{complete_cb};

    $check_complet->SetValue( !!$checker->get_complet );
    my $choice = $self->{suggestions_list};

    my $controls = {
        choice    => $choice,
        textfield => $self->{word_tc},
        gamb      => $self->{change_btn},
        lass      => $self->{skip_btn},
        gamb_dut  => $self->{change_all_btn},
        lass_dut  => $self->{skip_all_btn},
        add_pers  => $parzonte,
        undo      => $undo,
        complet   => $check_complet,
        clip      => {
            get   => $getclip,
            set   => $setclip,
            clear => $scanceledut,
        },
        fulltext  => $textbox,
        semaphore => $semaforo,
        check     => $contr,
    };

    my $check_font = $contr->GetFont();
    $check_font->SetPointSize( $check_font->GetPointSize() + 1 );
    $check_font->SetWeight(wxFONTWEIGHT_BOLD);
    $contr->SetFont($check_font);

    my $check_size = $contr->GetBestSize();
    $check_size->SetWidth( $check_size->GetWidth + 20 );
    $check_size->SetHeight( $check_size->GetHeight + 10 );
    $contr->SetMinSize($check_size);

    my $minSz = $self->GetBestSize;
    $self->SetSizeHints( $minSz->GetWidth(), $minSz->GetHeight() );
    $self->Fit;

    $self->SetSize( Wx::Size->new( 800, 600 ) );
    $self->Centre();

    EVT_MENU( $self, $self->{user_dict_mitem}->GetId(), \&gjestion_db_pers );
    EVT_MENU( $self, $self->{user_exc_mitem}->GetId(),  \&gjestion_er_comun );
    EVT_MENU( $self, $self->{exit_mitem}->GetId(),      sub { $self->Close } );
    EVT_MENU( $self, $self->{about_mitem}->GetId(),     \&on_about );
    EVT_MENU( $self, $self->{userdir_mitem}->GetId(),   \&on_open_user_dir );
    EVT_MENU( $self, $self->{help_mitem}->GetId(),      \&on_help );

    EVT_TEXT( $self, $textbox, \&on_text_changed );
    EVT_CHAR( $textbox, \&on_text_key );

    EVT_BUTTON( $self, $parzonte,    sub { $self->on_zonte } );
    EVT_BUTTON( $self, $contr,       sub { $self->on_check } );
    EVT_BUTTON( $self, $scanceledut, sub { $self->finish; $self->clear; } );
    EVT_BUTTON( $self, $getclip,     sub { $self->from_clipboard } );
    EVT_BUTTON( $self, $setclip,     sub { $self->to_clipboard } );

    EVT_CHAR(
        $scanceledut,
        sub {
            my ( $self, $event ) = @_;

            if (   $event->AltDown()
                && $event->ShiftDown()
                && $event->GetKeyCode() == ord('*') )
            {
                die("Chest al è un test!");
            }
        }
    );

    $self->{controls} = COF::Controls->new( $checker, $controls );

    $self->{data} = $data;
    my $personal_db = COF::App->get_user_file($PERSONAL_DB);
    if ( -e $personal_db ) {
        $self->_data->create_user_dict_file($personal_db);
    }
    my $ecezions_db = COF::App->get_user_file($ECEZIONS_DB);
    if ( -e $ecezions_db ) {
        $self->_data->create_user_exc_file($ecezions_db);
    }

    $self->{checker} = $checker;
    $self->{display} = $display;

    $self->{manual} = undef;

    $self->finish;

    return $self;
}

sub on_about {
    my ($self) = @_;
    my $dialog = COF::AboutDialog->new($self);
    $dialog->{info_label}
      ->SetLabel("Version: $COF::Info::VERSION\nFonetic: $COF::Info::TYPE");
    $dialog->{authors_label}->SetLabel(
        qq{Part informatiche
Version atuâl: Mattia Barbon, Franz Feregot
Version precedente: Dree Mistrut, Luca Peresson

Part linguistiche: Sandri Carrozzo, Carli Pup}
    );
    my $bitmap =
      Wx::Bitmap->new( COF::App->get_res_file( 'icons', 'cof48.ico' ),
        Wx::wxBITMAP_TYPE_ICO() );
    $dialog->{cof_bitmap}->SetBitmap($bitmap);

    my $cof_label  = $dialog->{cof_label};
    my $label_font = $cof_label->GetFont();
    $label_font->SetPointSize( $label_font->GetPointSize() + 1 );
    $label_font->SetWeight(wxFONTWEIGHT_BOLD);
    $cof_label->SetFont($label_font);

    for my $label ( 'infofur_hyperlink', 'arlef_hyperlink' ) {
        my $ctrl = $dialog->{$label};
        $ctrl->SetWindowStyleFlag(
            Wx::wxHL_ALIGN_LEFT | Wx::wxHL_CONTEXTMENU | Wx::wxBORDER_NONE );
    }

    $dialog->Fit();
    $dialog->ShowModal;
}

sub on_help {
    my ($self) = @_;
    require Wx::Help;

    if ( !$self->{manual} ) {

        my $h = Wx::CHMHelpController->new;
        my $f = COF::App->get_res_file('istruzions.chm');
        $h->Initialize($f);

        $self->{manual} = $h;

    }
    $self->{manual}->DisplayContents;
}

sub on_open_user_dir {
    my ($self) = @_;
    Wx::ExecuteArgs( [ 'explorer.exe', COF::App->get_user_dir ] );
}

sub on_zonte {
    my $self = shift;

    return if $self->_checker->get_finito();
    return if $self->{suggestions_list}->GetSelection() != -1;

    my $content = $self->{word_tc}->GetValue();

    return unless $content;
    return
      unless Wx::MessageBox(
        <<EOT, "Zonte", wxYES_NO | wxICON_QUESTION, $self ) == wxYES;
Zonte la peraule

$content
EOT
    if ( !$self->_data->has_user_dict ) {
        $self->_data->create_user_dict_file(
            COF::App->get_user_file($PERSONAL_DB) );
    }
    my $ok = $self->_data->add_user_dict($content);

    if ( $ok == 1 ) {
        Wx::MessageBox( "Nol è pussibil vierzi il database personâl",
            "Atenzion", wxOK | wxICON_ERROR, $self );
    }
    elsif ( $ok == 2 ) {
        Wx::MessageBox( "Peraule za presinte tal database personâl",
            "Atenzion", wxOK | wxICON_EXCLAMATION, $self );
    }

    $self->{controls}->change_all( $content, 1 );
}

sub from_clipboard {
    my $self = shift;

    my $clip_content = COF::Clipboard->get_text();
    if ($clip_content) {
        $self->finish;
        $self->clear;
        $self->{fulltext_tc}->SetValue($clip_content);
    }
}

sub to_clipboard {
    my $self = shift;

    my $clip_content = $self->{fulltext_tc}->GetValue();
    COF::Clipboard->set_text($clip_content);
}

sub on_text_key {
    my ( $self, $event ) = @_;
    my $char = uc( $event->GetKeyCode );

    if ( $char eq 'A' && $event->GetCtrlDown ) {
        $self->{copy_btn}->SetFocus();
    }
    elsif ( $char eq 'C' && $event->GetCtrlDown ) {
        $self->{copy_btn}->SetFocus();
        $self->to_clipboard;
    }
    else {
        $event->Skip;
    }
}

sub on_text_changed {
    my ( $self, $event ) = @_;
    return if $self->{display}->{changing};

    $self->finish;
}

sub finish {
    my ( $self, $show_message ) = @_;

    $self->{controls}->finish($show_message);
}

sub unfinish {
    my ($self) = @_;

    $self->{controls}->unfinish;
}

sub clear {
    my ( $self, $no_text ) = @_;

    $self->{controls}->clear;
    $self->_display->clear_text if !$no_text;
}

sub on_check {
    my $self = shift;

    my $working = COF::Working->new( $self->{state_bmp} );
    my $complet = $self->_checker->get_complet;

    my $text = $self->{fulltext_tc}->GetValue();
    unless ($text) {
        Wx::MessageBox(
            "Nissun test presint.",    "Atenzion",
            wxOK | wxICON_EXCLAMATION, $self
        );
        return;
    }

    $text =~ s/[$FUR_APOSTROPHS]/'/g;
    $self->unfinish;
    $self->_checker->set_text($text);

    $self->clear(1);

    my $busy = Wx::BusyCursor->new();

    $self->finish(1) if $self->_checker->search_phrase() == 0;

}

sub gjestion_db_pers {
    my $self = shift;
    my $window_db_pers;

    if ( !$self->_data->has_user_dict ) {
        $self->_data->create_user_dict_file(
            COF::App->get_user_file($PERSONAL_DB) );
    }
    $window_db_pers = COF::Personal->new( $self, $self->_data );
    $window_db_pers->ShowModal;

}

sub gjestion_er_comun {
    my $self = shift;
    if ( !$self->_data->has_user_exc ) {
        $self->_data->create_user_exc_file(
            COF::App->get_user_file($ECEZIONS_DB) );
    }
    my $window_er_comun = COF::ExceptionDict->new( $self, $self->_data );
    $window_er_comun->ShowModal;
}

sub _data    { $_[0]->{data} }
sub _checker { $_[0]->{checker} }
sub _display { $_[0]->{display} }

package COF::Display;

use strict;
use warnings;
use base qw(COF::BaseDisplay COF::TextDisplay);

package COF::Working;

use strict;
use warnings;

sub new {
    my ( $class, $semaforo ) = @_;
    $semaforo->SetBitmap($ROS);
    bless { semaforo => $semaforo }, __PACKAGE__;
}

sub DESTROY {
    my $self = shift;
    $self->{semaforo}->SetBitmap($VERT);
}

package COF::Progress;

use strict;
use warnings;

sub new {
    my $class = shift;
    return bless { gauge => $_[0] }, $class;
}

sub set_max {
    $_[0]->{max} = $_[1];
    $_[0]->{gauge}->SetRange( $_[1] );
}

sub set_pos {
    return unless $_[1] >= $_[0]->{max} || !( $_[1] % 100 );
    $_[0]->{gauge}->SetValue( $_[0]->{max} >= $_[1] ? $_[1] : $_[0]->{max} );
    $_[0]->{gauge}->Update;
    Wx::Yield if Wx::wxMAC || Wx::wxGTK;
}

package COF::Clipboard;

use strict;
use warnings;

use Wx qw(wxTheClipboard);

my $tdo;

sub get_text {
    return '' unless wxTheClipboard->Open;
    $tdo = Wx::TextDataObject->new;
    wxTheClipboard->UsePrimarySelection(1);

    return '' unless wxTheClipboard->IsSupported( $tdo->GetFormat );
    wxTheClipboard->GetData($tdo);
    wxTheClipboard->Close;

    return $tdo->GetText;
}

sub set_text {
    $tdo = Wx::TextDataObject->new;
    $tdo->SetText( $_[1] );

    return unless wxTheClipboard->Open;
    wxTheClipboard->UsePrimarySelection(1);
    wxTheClipboard->SetData($tdo);
    wxTheClipboard->Flush;
    wxTheClipboard->Close;
}

1;
