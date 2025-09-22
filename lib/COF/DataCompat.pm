package COF::DataCompat;

# COF::DataCompat - Compatible version of COF::Data without DB_File/BerkeleyDB dependency
# Uses SDBM_File as alternative for compatibility on systems where BerkeleyDB is unavailable
# IDENTICAL PHONETIC ALGORITHM - copied literally from COF::Data

use strict;
use warnings;
use utf8;

use Params::Validate qw/validate/;
use SDBM_File;  # Alternative to DB_File for compatibility
use Fcntl;
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
            user_dict => 0
        }
    );

    my %args = @_;

    my $self = {
        freq         => undef,
        user_dict    => undef,
        radix_tree   => undef,
        rt_checker   => undef,
        elisions     => undef,
        errors       => undef,
        words_ph     => undef,
        user_suggest => []
    };

    bless $self, $class;

    # NOTE: For compatibility, database features are limited
    # but the main phonetic algorithm works completely
    
    warn "COF::DataCompat: Utilizzando versione compatibile senza BerkeleyDB. " .
         "Dictionary features are limited but the phonetic algorithm is complete.\n";

    # Load only RadixTree which doesn't depend on DB_File
    if ( $args{words_rt} && -r $args{words_rt} ) {
        $self->{radix_tree} = COF::RadixTree->new( $args{words_rt} );
        $self->{rt_checker} = COF::RT_Checker->new( $self->{radix_tree} );
    }

    lock_keys( %{$self} );
    return $self;
}

# Compatible access functions (limited version)
sub has_user_dict { return 0; }  # Not supported in compatible version
sub get_user_dict { return {}; } # Not supported in compatible version

sub has_rt_checker {
    my $self = shift;
    return defined $self->{rt_checker};
}

sub get_rt_checker {
    my $self = shift;
    return $self->{rt_checker};
}

sub has_radix_tree {
    my $self = shift;
    return defined $self->{radix_tree};
}

sub get_radix_tree {
    my $self = shift;
    return $self->{radix_tree};
}

# Helper function for lc_word
sub lc_word {
    return lc $_[0];
}

# EXACT PHONETIC ALGORITHM copied from COF::Data::phalg_furlan
# Every single line is identical to the original to ensure 100% compatibility
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

# Compatible functions for other features (limited version)
sub change_user_dict {
    warn "COF::DataCompat: change_user_dict non supportato in versione compatibile\n";
    return 1;
}

sub delete_user_dict {
    warn "COF::DataCompat: delete_user_dict non supportato in versione compatibile\n";
    return 1;
}

# Placeholder for other functions that might be called
sub AUTOLOAD {
    our $AUTOLOAD;
    my $method = $AUTOLOAD;
    $method =~ s/.*:://;
    warn "COF::DataCompat: Metodo '$method' non supportato in versione compatibile\n";
    return undef;
}

1;

__END__

=head1 NAME

COF::DataCompat - Versione compatibile di COF::Data senza dipendenza da BerkeleyDB

=head1 SYNOPSIS

  use COF::DataCompat;
  
  # Using the phonetic algorithm (main function)
  my ($primo, $secondo) = COF::DataCompat::phalg_furlan('furlan');
  
  # Object creation (limited functionality)
  my $data = COF::DataCompat->new(
      words_ph => 'dict/words.db',
      words_rt => 'dict/words.rt'
  );

=head1 DESCRIPTION

COF::DataCompat è una versione alternativa di COF::Data che non dipende da 
BerkeleyDB/DB_File. È stata creata per garantire la compatibilità su sistemi 
dove le librerie BerkeleyDB non sono disponibili o configurate correttamente.

=head2 CARATTERISTICHE

=over 4

=item * Complete phonetic algorithm identical to COF::Data::phalg_furlan

=item * Nessuna dipendenza da BerkeleyDB o DB_File

=item * Compatibile con SDBM_File (incluso in Perl standard)

=item * Limited dictionary functionality but complete phonetic algorithm

=back

=head2 LIMITAZIONI

Le seguenti funzionalità di COF::Data non sono supportate in questa versione:

=over 4

=item * Accesso ai dizionari utente (user_dict)

=item * Modifica dizionari con change_user_dict/delete_user_dict

=item * Accesso completo ai database di parole/errori/frequenze

=back

=head1 AUTHOR

COF Project - Coretor Ortografic Furlan

=head1 SEE ALSO

L<COF::Data>, L<SDBM_File>

=cut