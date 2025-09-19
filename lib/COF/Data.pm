package COF::Data;

use strict;
use warnings;
use utf8;

use Params::Validate qw/validate/;
use DB_File 1.810;
use Encode qw/encode decode/;

use COF::Letters qw($FUR_APOSTROPHS $FUR_LETTERS);

use COF::RadixTree;
use COF::RT_Checker;

use File::Spec::Functions;
use Hash::Util qw/lock_keys/;

my %HASH_VOCALI_A = ( 'a' => 1, 'à' => 1, 'á' => 1, 'â' => 1 );
my %HASH_VOCALI_E = ( 'e' => 1, 'è' => 1, 'é' => 1, 'ê' => 1 );
my %HASH_VOCALI_I = ( 'i' => 1, 'ì' => 1, 'í' => 1, 'î' => 1, 'j' => 1 );
my %HASH_VOCALI_O = ( 'o' => 1, 'ò' => 1, 'ó' => 1, 'ô' => 1 );
my %HASH_VOCALI_U = ( 'u' => 1, 'ù' => 1, 'ú' => 1, 'û' => 1 );

my $DICT       = "words.db";
my $RADIX_TREE = "words.rt";
my $ELISION_DB = "elisions.db";
my $ERR_COM    = "errors.db";
my $FREQ       = "frec.db";

sub make_default_args {
    my $dir = shift;
    return (
        words_ph => catfile( $dir, $DICT ),
        words_rt => catfile( $dir, $RADIX_TREE ),
        elisions => catfile( $dir, $ELISION_DB ),
        errors   => catfile( $dir, $ERR_COM ),
        freq     => catfile( $dir, $FREQ )
    );
}

sub new {
    my $class = shift;
    validate(
        @_,
        {
            words_ph  => 1,
            words_rt  => 1,
            elisions  => 0,
            errors    => 0,
            freq      => 0,
            user_dict => 0,
            user_exc  => 0
        }
    );
    my %args = @_;

    my $self = bless {
        words_ph  => undef,
        words_rt  => undef,
        elisions  => undef,
        errors    => undef,
        freq      => undef,
        user_dict => undef,
        user_exc  => undef
    }, $class;
    lock_keys(%$self);

    my $dbh = tie( my %words_ph, "DB_File", $args{words_ph}, O_RDONLY, 0666 )
      or die("No rivi a vierzi diz default '$args{words_ph}' $!\n");
    $dbh->filter_fetch_key( sub { $_ = decode( "iso-8859-1", $_ ); } );
    $dbh->filter_store_key( sub { $_ = encode( "iso-8859-1", $_ ); } );
    $dbh->filter_fetch_value( sub { $_ = decode( "iso-8859-1", $_ ); } );
    $self->{words_ph} = \%words_ph;

    $self->{words_rt} =
      COF::RT_Checker->new( COF::RadixTree->new( $args{words_rt} ) );

    for my $field (qw/elisions errors freq/) {
        if ( my $db_path = $args{$field} ) {
            $dbh = tie( my %db, "DB_File", $db_path, O_RDONLY, 0666 )
              or die("No rivi a vierzi db '$field' '$db_path' $!\n");
            $dbh->filter_fetch_key( sub { utf8::decode($_) } );
            $dbh->filter_store_key( sub { utf8::encode($_) } );
            if ( $field eq 'freq' ) {
                $dbh->filter_fetch_value( sub { $_ = unpack( "C", $_ ) } );
            }
            elsif ( $field eq 'errors' ) {
                $dbh->filter_fetch_value( sub { utf8::decode($_) } );
            }
            $self->{$field} = \%db;
        }
    }

    for my $field (qw/user_dict user_exc/) {
        if ( my $db_path = $args{$field} ) {
            $self->{$field} = $self->_create_file($db_path);
        }
    }

    return $self;
}

sub get_words_ph  { return $_[0]->{words_ph}; }
sub get_words_rt  { return $_[0]->{words_rt}; }
sub get_elisions  { return $_[0]->{elisions}; }
sub get_freq      { return $_[0]->{freq}; }
sub get_errors    { return $_[0]->{errors}; }
sub get_user_dict { return $_[0]->{user_dict}; }
sub get_user_exc  { return $_[0]->{user_exc}; }

sub clear_user_dict {
    my ($self) = @_;

    if ( defined $self->{user_dict} ) {
        %{ $_[0]->{user_dict} } = ();
    }
}

sub clear_user_exc {
    my ($self) = @_;

    if ( defined $self->{user_exc} ) {
        %{ $_[0]->{user_exc} } = ();
    }
}

sub _create_file {
    my ( $self, $file, $old ) = @_;

    untie %$old if $old;

    if ($file) {
        my %hash;
        my $dbh = tie %hash, "DB_File", $file, O_CREAT | O_RDWR, 0666
          or die("no rivi a creâ db '$file' $!\n");
        $dbh->filter_fetch_key( sub   { utf8::decode($_) } );
        $dbh->filter_store_key( sub   { utf8::encode($_) } );
        $dbh->filter_fetch_value( sub { utf8::decode($_) } );
        $dbh->filter_store_value( sub { utf8::encode($_) } );

        return \%hash;
    }
    else {
        return;
    }
}

sub create_user_dict_file {
    my ( $self, $file ) = @_;
    $self->{user_dict} = $self->_create_file( $file, $self->{user_dict} );
}

sub create_user_exc_file {
    my ( $self, $file ) = @_;

    $self->{user_exc} = $self->_create_file( $file, $self->{user_exc} );
}

sub has_user_dict { defined $_[0]->{user_dict} }

sub has_user_exc { defined $_[0]->{user_exc} }

sub has_errors { defined $_[0]->{errors} }

sub has_freq { defined $_[0]->{freq} }

sub has_elisions { defined $_[0]->{elisions} }

sub minimo {
    my ( $primo, $secondo, $terzo ) = @_;
    my $tmp = $primo;

    $tmp = $secondo if ( $secondo < $tmp );
    $tmp = $terzo   if ( $terzo < $tmp );

    return $tmp;
}

sub Levenshtein {

    my ( $s, $t ) = @_;
    my $cost;
    my @d;

    my $n = length($s);
    my $m = length($t);
    if ( !$n ) { return $m }
    if ( !$m ) { return $n }
    foreach my $i ( 0 .. $n ) { $d[$i][0] = $i }
    foreach my $j ( 0 .. $m ) { $d[0][$j] = $j }
    foreach my $i ( 1 .. $n ) {
        my $s_i = substr( $s, $i - 1, 1 );
        foreach my $j ( 1 .. $m ) {

            my $t_i = substr( $t, $j - 1, 1 );

            if ( $s_i eq $t_i ) { $cost = 0 }
            else {

                if (
                    !(
                           ( $HASH_VOCALI_A{$s_i} and $HASH_VOCALI_A{$t_i} )
                        or ( $HASH_VOCALI_E{$s_i} and $HASH_VOCALI_E{$t_i} )
                        or ( $HASH_VOCALI_I{$s_i} and $HASH_VOCALI_I{$t_i} )
                        or ( $HASH_VOCALI_O{$s_i} and $HASH_VOCALI_O{$t_i} )
                        or ( $HASH_VOCALI_U{$s_i} and $HASH_VOCALI_U{$t_i} )
                    )
                  )
                {

                    $cost = 1;
                }
                else {

                    $cost = 0;
                }
            }
            $d[$i][$j] = &minimo(
                $d[ $i - 1 ][$j] + 1,
                $d[$i][ $j - 1 ] + 1,
                $d[ $i - 1 ][ $j - 1 ] + $cost
            );
        }
    }
    return $d[$n][$m];
}

sub sort_friulian {
    return map { $_->[1] }
      sort     { $a->[0] cmp $b->[0] }
      map {
        my $key = $_;
        $key =~
tr{0123456789âäàáÄÁÂÀAaBCçÇDéêëèÉÊËÈEeFGHïîìíÍÎÏÌIiJKLMNôöòóÓÔÒÖOoPQRSTÚÙÛÜúûùüuUVWXYZ}
                         {\x30\x31\x32\x33\x34\x35\x36\x37\x38\x39aaaaaaaaaabcccdeeeeeeeeeefghiiiiiiiiiijklmnoooooooooopqrstuuuuuuuuuuvwxyz};
        $key =~ s/^'s/s/;
        [ $key, $_ ];
      } ( ref $_[0] ? @{ $_[0] } : @_ );
}

sub first_is_uc {
    my $word = shift;
    my $fl = substr $word, 0, 1;
    if ( $fl eq "'" ) {
        return 0 if length($word) == 1;
        $fl = substr $word, 1, 1;
    }
    return $fl eq uc_word($fl);
}

sub ucf_word {
    my $word = shift;
    if ( substr( $word, 0, 1 ) eq "'" ) {
        return $word if length($word) == 1;
        my $first_letter_ok = substr( $word, 1, 1 );
        substr( $word, 1, 1 ) = uc_word($first_letter_ok);
    }
    else {
        my $first_letter_ok = substr( $word, 0, 1 );
        substr( $word, 0, 1 ) = uc_word($first_letter_ok);
    }
    return $word;
}

sub uc_word {
    return uc $_[0];
}

sub lc_word {
    return lc $_[0];
}

sub phalg_furlan {

    my $original = $_[0];
    my $primo;
    my $secondo;
    my $word = '';

    my $slash_W = qr/[^$FUR_LETTERS$FUR_APOSTROPHS]/;

    $original =~ s/[$FUR_APOSTROPHS]/'/g;
    $original =~ s/e /'/;
    $original =~ s/\s+|\$slash_W+//g;

    $original =~ tr/\0-\377//s;

    $original = lc_word($original);

    $original =~ s/h'/K/;

    $original =~ s/à/a/g;
    $original =~ s/â/a/g;
    $original =~ s/á/a/g;
    $original =~ s/'a/a/g;

    $original =~ s/è/e/g;
    $original =~ s/ê/e/g;
    $original =~ s/é/e/g;
    $original =~ s/'e/e/g;

    $original =~ s/ì/i/g;
    $original =~ s/î/i/g;
    $original =~ s/í/i/g;
    $original =~ s/'i/i/g;

    $original =~ s/ò/o/g;
    $original =~ s/ô/o/g;
    $original =~ s/ó/o/g;
    $original =~ s/'o/o/g;

    $original =~ s/ù/u/g;
    $original =~ s/û/u/g;
    $original =~ s/ú/u/g;
    $original =~ s/'u/u/g;

    $original =~ s/çi/ci/g;
    $original =~ s/çe/ce/g;

    $original =~ s/ds$/ts/;
    $original =~ s/sci/ssi/g;
    $original =~ s/sce/se/g;

    $original =~ tr/\0-\377//s;

    $original =~ s/w//g;
    $original =~ s/y//g;
    $original =~ s/x//g;

    $original =~ s/^che/chi/g;

    $original =~ s/h//g;

    $original =~ s/leng/X/g;
    $original =~ s/lingu/X/g;

    $original =~ s/amentri/O/g;
    $original =~ s/ementri/O/g;
    $original =~ s/amenti/O/g;
    $original =~ s/ementi/O/g;

    $original =~ s/uintri/W/g;
    $original =~ s/ontra/W/g;

    $original =~ s/ur/Y/g;
    $original =~ s/uar/Y/g;
    $original =~ s/or/Y/g;

    $original =~ s/^'s/s/;
    $original =~ s/^'n/n/;

    $original =~ s/ins$/1/;
    $original =~ s/in$/1/;
    $original =~ s/ims$/1/;
    $original =~ s/im$/1/;
    $original =~ s/gns$/1/;
    $original =~ s/gn$/1/;

    $original =~ s/mn/5/g;
    $original =~ s/nm/5/g;
    $original =~ s/[mn]/5/g;

    $original =~ s/er/2/g;
    $original =~ s/ar/2/g;

    $original =~ s/b$/3/;
    $original =~ s/p$/3/;
    $original =~ s/v$/4/;
    $original =~ s/f$/4/;

    $primo = $secondo = $original;

    $primo =~ s/'c/A/g;
    $primo =~ s/c[ji]us$/A/;
    $primo =~ s/c[ji]u$/A/;
    $primo =~ s/c'/A/g;
    $primo =~ s/ti/A/g;
    $primo =~ s/ci/A/g;
    $primo =~ s/si/A/g;
    $primo =~ s/zs/A/g;
    $primo =~ s/zi/A/g;
    $primo =~ s/cj/A/g;
    $primo =~ s/çs/A/g;
    $primo =~ s/tz/A/g;
    $primo =~ s/z/A/g;
    $primo =~ s/ç/A/g;
    $primo =~ s/c/A/g;
    $primo =~ s/q/A/g;
    $primo =~ s/k/A/g;
    $primo =~ s/ts/A/g;
    $primo =~ s/s/A/g;

    $secondo =~ s/c$/0/;
    $secondo =~ s/g$/0/;

    $secondo =~ s/bs$/s/;
    $secondo =~ s/cs$/s/;
    $secondo =~ s/fs$/s/;
    $secondo =~ s/gs$/s/;
    $secondo =~ s/ps$/s/;
    $secondo =~ s/vs$/s/;

    $secondo =~ s/di(?=.)/E/g;
    $secondo =~ s/gji/E/g;
    $secondo =~ s/gi/E/g;
    $secondo =~ s/gj/E/g;
    $secondo =~ s/g/E/g;

    $secondo =~ s/ts/E/g;
    $secondo =~ s/s/E/g;
    $secondo =~ s/zi/E/g;
    $secondo =~ s/z/E/g;

    $primo =~ s/j/i/g;
    $secondo =~ s/j/i/g;

    $primo =~ tr/i/i/s;
    $secondo =~ tr/i/i/s;

    $primo =~ s/ai/6/g;
    $primo =~ s/a/6/g;
    $primo =~ s/ei/7/g;
    $primo =~ s/e/7/g;
    $primo =~ s/ou/8/g;
    $primo =~ s/oi/8/g;
    $primo =~ s/o/8/g;
    $primo =~ s/vu/8/g;
    $primo =~ s/u/8/g;
    $primo =~ s/i/7/g;

    $secondo =~ s/ai/6/g;
    $secondo =~ s/a/6/g;
    $secondo =~ s/ei/7/g;
    $secondo =~ s/e/7/g;
    $secondo =~ s/ou/8/g;
    $secondo =~ s/oi/8/g;
    $secondo =~ s/o/8/g;
    $secondo =~ s/vu/8/g;
    $secondo =~ s/u/8/g;
    $secondo =~ s/i/7/g;

    $primo =~ s/^t/H/;
    $primo =~ s/^d/I/;

    $primo =~ s/t/9/g;
    $primo =~ s/d/9/g;

    $secondo =~ s/^t/H/;
    $secondo =~ s/^d/I/;

    $secondo =~ s/t/9/g;
    $secondo =~ s/d/9/g;

    return $primo, $secondo;
}

sub change_user_dict {
    my ( $self, $text, $da_canc ) = @_;

    return unless $text;

    if ( not $self->has_user_dict ) {
        return 1;
    }

    my $hash = $self->get_user_dict;

    my ( $codeA, $codeB ) = &phalg_furlan($text);

    foreach my $code ( $codeA eq $codeB ? ($codeA) : ( $codeA, $codeB ) ) {
        if ( exists $hash->{$code} ) {
            my $ug = 0;
            my @parole = split /,/, $hash->{$code};
            foreach my $par (@parole) {
                if ( $text eq $par ) {
                    $ug = 1;
                    last;
                }
            }

            if ( !$ug ) {  $self->delete_user_dict($da_canc) if $da_canc;

                delete $hash->{$code};
                my $str = join ',',
                  ( grep { !$da_canc || $da_canc ne $_ } @parole ), $text;
                $hash->{$code} = $str;
            }
            else {
                return 2;
            }
        }
        else {
            $self->delete_user_dict($da_canc) if $da_canc;
            $hash->{$code} = $text;
        }
    }

    return 0;
}

*add_user_dict = \&change_user_dict;

sub delete_user_dict {
    my ( $self, $da_canc ) = @_;

    if ( not $self->has_user_dict ) {
        return 1;
    }

    my $hash = $self->get_user_dict;
    my ( $codeA, $codeB ) = &phalg_furlan($da_canc);

    foreach my $code ( $codeA eq $codeB ? ($codeA) : ( $codeA, $codeB ) ) {
        if ( exists $hash->{$code} ) {
            my @parole = grep { $_ ne $da_canc } split /,/, $hash->{$code};
            if (@parole) {
                my $str = join ',', @parole;
                $hash->{$code} = $str;
            }
            else {
                delete $hash->{$code};
            }
        }
    }

    return 0;
}

sub get_version {
    my $self = shift;

    return
      exists $self->{'words_ph'}{"_*v_r_s*_"}
      ? $self->{'words_ph'}{"_*v_r_s*_"}
      : undef;
}

sub word_has_elision {
    my ( $self, $word ) = @_;
    return $self->{'elisions'}->{$word};
}

1;
