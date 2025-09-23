#!/usr/bin/env perl
# COF Spell Checker Utilities - Unified version with compatibility support
# Supports both COF::Data (if available) and COF::DataCompat (fallback)
use strict;
use warnings;
use utf8;
use FindBin;
use File::Spec;
use lib File::Spec->catdir($FindBin::Bin, '..', 'lib');

use Getopt::Long qw(GetOptions);
use JSON::PP;
use Encode qw(encode);

# Check for special --generate-hashes flag before processing other options
if (@ARGV && $ARGV[0] eq '--generate-hashes') {
    handle_generate_hashes();
    exit 0;
}

my $help = 0;
my $word;
my $phonetic = '';
my $suggest = '';
my $from_file = '';
my $format = 'list';   # list | array | json
my $list_only = 0;
my $use_compat = 0;

GetOptions(
    'help|h'       => \$help,
    'word|w=s'     => \$word,
    'phonetic|p=s' => \$phonetic,
    'suggest|s=s'  => \$suggest,
    'file|f=s'     => \$from_file,
    'format=s'     => \$format,
    'list'         => \$list_only,
    'compat'       => \$use_compat,
) or die "Invalid options\n";

if ($help) {
    print_help();
    exit;
}

# Auto-detect compatible mode if COF::Data doesn't work
my ($data_module, $data_obj, $spellchecker);

if ($use_compat) {
    print STDERR "Modalità compatibilità forzata (--compat)\n";
    load_compat_mode();
} else {
    # Try original COF::Data first
    eval {
        require COF::Data;
        require COF::SpellChecker;
        
        my $dict_dir = get_dict_dir();
        my %args = COF::Data::make_default_args($dict_dir);
        $data_obj = COF::Data->new(%args);
        $spellchecker = COF::SpellChecker->new($data_obj);
        $data_module = 'COF::Data';
        
        print STDERR "✓ Usando COF::Data originale\n";
    };
    
    if ($@) {
        print STDERR "⚠ COF::Data non disponibile: $@\n";
        print STDERR "→ Passando a modalità compatibile...\n";
        load_compat_mode();
    }
}



# Processing
if ($word) {
    process_single_word($word);
} elsif ($phonetic) {
    process_phonetic($phonetic);
} elsif ($suggest) {
    process_suggest($suggest);
} elsif ($from_file) {
    process_file($from_file);
} else {
    print "Specificare --word, --phonetic, --suggest o --file\n";
    print_help();
    exit 1;
}

sub handle_generate_hashes {
    shift @ARGV;  # Remove --generate-hashes flag
    
    # Check for format option
    my $gen_format = 'text';
    if (@ARGV && $ARGV[0] =~ /^--format=(.+)/) {
        $gen_format = $1;
        shift @ARGV;
    }
    
    my @words = @ARGV;
    
    if (!@words) {
        print "Usage: $0 --generate-hashes [--format=python|perl|text] word1 word2 ...\n";
        exit 1;
    }
    
    # Initialize COF modules
    my ($data_module, $data_obj);
    
    # Always use compat mode for hash generation (simpler)
    eval {
        require COF::DataCompat;
        my $dict_dir = get_dict_dir();
        my %args = COF::DataCompat::make_default_args($dict_dir);
        $data_obj = COF::DataCompat->new(%args);
        $data_module = 'COF::DataCompat';
    };
    
    if ($@) {
        die "Errore caricamento COF::DataCompat: $@\n";
    }
    
    # Generate hashes
    print "# Generated phonetic test cases:\n";
    foreach my $word (@words) {
        my ($p1, $p2) = eval { COF::DataCompat::phalg_furlan($word) };
        
        if ($@) {
            warn "Error processing word '$word': $@";
            next;
        }
        
        if ($gen_format eq 'python') {
            print "('$word', '$p1', '$p2'),\n";
        } elsif ($gen_format eq 'perl') {
            print "['$word', '$p1', '$p2'],\n";
        } else {
            print "$word -> '$p1', '$p2'\n";
        }
    }
}

sub load_compat_mode {
    eval {
        require COF::DataCompat;
        
        my $dict_dir = get_dict_dir();
        my %args = COF::DataCompat::make_default_args($dict_dir);
        $data_obj = COF::DataCompat->new(%args);
        $spellchecker = undef;  # Full spell checker not available in compat mode
        $data_module = 'COF::DataCompat';
        
        print STDERR "✓ Usando COF::DataCompat (modalità compatibile)\n";
    };
    
    if ($@) {
        die "Errore caricamento COF::DataCompat: $@\n";
    }
}

sub process_single_word {
    my $word = shift;
    print "Parola: $word (modalità: $data_module)\n";
    
    # Test phonetic algorithm (always available)
    if ($data_module eq 'COF::Data') {
        my ($primo, $secondo) = COF::Data::phalg_furlan($word);
        print "  Fonetica: $primo | $secondo\n";
    } else {
        my ($primo, $secondo) = COF::DataCompat::phalg_furlan($word);
        print "  Fonetica: $primo | $secondo\n";
    }
    
    # Test spell checker (only with COF::Data)
    if ($spellchecker) {
        my @suggestions = $spellchecker->suggest($word);
        if (@suggestions) {
            print "  Suggerimenti: " . join(', ', @suggestions) . "\n";
        } else {
            print "  Suggerimenti: nessuno\n";
        }
        
        if ($spellchecker->check($word)) {
            print "  Controllo: ✓ parola corretta\n";
        } else {
            print "  Controllo: ✗ parola non riconosciuta\n";
        }
    } else {
        print "  Spell checker: non disponibile in modalità compatibile\n";
    }
    
    # Test RadixTree if available
    if ($data_obj->has_rt_checker()) {
        my $rt_checker = $data_obj->get_rt_checker();
        if ($rt_checker) {
            print "  ✓ RadixTree disponibile per controllo strutturale\n";
        }
    } else {
        print "  ✗ RadixTree non disponibile\n";
    }
}

sub process_phonetic {
    my $word = shift;
    print "Test fonetico per: $word\n";
    
    my ($primo, $secondo);
    if ($data_module eq 'COF::Data') {
        ($primo, $secondo) = COF::Data::phalg_furlan($word);
    } else {
        ($primo, $secondo) = COF::DataCompat::phalg_furlan($word);
    }
    
    if ($format eq 'json') {
        my $result = {
            word => $word,
            phonetic_primo => $primo,
            phonetic_secondo => $secondo,
            engine => $data_module
        };
        print JSON::PP->new->pretty->encode($result);
    } elsif ($format eq 'array') {
        print "[$primo, $secondo]\n";
    } else {
        print "$primo|$secondo\n";
    }
}

sub process_suggest {
    my $word = shift;
    
    if (!$spellchecker) {
        print "Suggerimenti non disponibili in modalità compatibile.\n";
        print "Usa --word per analisi fonetica o rimuovi --compat per spell checker completo.\n";
        return;
    }
    
    print "Suggerimenti per: $word\n";
    my @suggestions = $spellchecker->suggest($word);
    
    if ($format eq 'json') {
        my $result = {
            word => $word,
            suggestions => \@suggestions,
            engine => $data_module
        };
        print JSON::PP->new->pretty->encode($result);
    } else {
        if (@suggestions) {
            print join("\n", @suggestions) . "\n";
        } else {
            print "(nessun suggerimento)\n";
        }
    }
}

sub process_file {
    my $filename = shift;
    
    open my $fh, '<:utf8', $filename or die "Impossibile aprire $filename: $!\n";
    
    while (my $line = <$fh>) {
        chomp $line;
        next if $line =~ /^\s*$/ || $line =~ /^#/;
        
        my ($primo, $secondo);
        if ($data_module eq 'COF::Data') {
            ($primo, $secondo) = COF::Data::phalg_furlan($line);
        } else {
            ($primo, $secondo) = COF::DataCompat::phalg_furlan($line);
        }
        
        if ($format eq 'json') {
            my $result = {
                word => $line,
                phonetic_primo => $primo,
                phonetic_secondo => $secondo,
                engine => $data_module
            };
            print JSON::PP->new->encode($result) . "\n";
        } else {
            print "$line\t$primo\t$secondo\n";
        }
    }
    
    close $fh;
}

sub get_dict_dir {
    my $base_dir = File::Spec->catdir($FindBin::Bin, '..');
    return File::Spec->catdir($base_dir, 'dict');
}

sub print_help {
    print <<'EOF';
COF Spell Checker Utils - Versione Unificata con Compatibilità

UTILIZZO:
    spellchecker_utils.pl [OPZIONI]

OPZIONI:
    --help, -h          Mostra questo help
    --word, -w WORD     Analizza singola parola (fonetica + spell check)
    --phonetic, -p WORD Test solo algoritmo fonetico  
    --suggest, -s WORD  Ottieni suggerimenti spelling (solo modalità completa)
    --file, -f FILE     Elabora file (una parola per riga)
    --format FORMAT     Formato output: list|array|json (default: list)
    --list              Solo lista (compatibilità)
    --compat            Forza modalità compatibile (COF::DataCompat)

MODALITÀ:
    Automatica:    Prova COF::Data, fallback su COF::DataCompat se necessario
    Compatibile:   Usa COF::DataCompat (senza dipendenze BerkeleyDB)

ESEMPI:
    # Test single word (automatic mode)
    perl spellchecker_utils.pl --word furlan
    
    # Force compatible mode
    perl spellchecker_utils.pl --compat --word furlan
    
    # Test phonetic with JSON format
    perl spellchecker_utils.pl --phonetic cjase --format json
    
    # Spelling suggestions (only if COF::Data available)
    perl spellchecker_utils.pl --suggest parol
    
    # Process file
    perl spellchecker_utils.pl --file wordlist.txt

NOTE:
    - Modalità automatica prova COF::Data originale, poi COF::DataCompat
    - Modalità compatibile usa solo COF::DataCompat (no BerkeleyDB)
    - Spell checker completo disponibile solo con COF::Data
    - Algoritmo fonetico disponibile in entrambe le modalità

EOF
}

#
# Generate phonetic hashes for a list of words - utility function for testing
#
sub generate_phonetic_hashes {
    my @words = @_;
    
    print "# Generated phonetic test cases:\n";
    foreach my $word (@words) {
        my ($p1, $p2) = eval { 
            if ($data_module eq 'COF::DataCompat') {
                COF::DataCompat::phalg_furlan($word);
            } else {
                $data_obj->phalg_furlan($word);
            }
        };
        
        if ($@) {
            warn "Error processing word '$word': $@";
            next;
        }
        
        if ($format eq 'python') {
            print "('$word', '$p1', '$p2'),\n";
        } elsif ($format eq 'perl') {
            print "['$word', '$p1', '$p2'),\n";
        } else {
            print "$word -> '$p1', '$p2'\n";
        }
    }
}



__END__

=head1 NAME

spellchecker_utils.pl - COF Spell Checker Utilities con supporto compatibilità

=head1 DESCRIPTION

Utility unificata per spell checking e analisi fonetica Furlan con supporto
automatico per compatibilità quando BerkeleyDB/DB_File non è disponibile.

=head2 MODALITÀ

=over 4

=item * Modalità automatica: Prova COF::Data, fallback su COF::DataCompat

=item * Modalità compatibile: Usa direttamente COF::DataCompat  

=item * Algoritmo fonetico disponibile in entrambe

=item * Spell checker completo solo con COF::Data

=back

=head1 SEE ALSO

L<COF::Data>, L<COF::DataCompat>, L<COF::SpellChecker>

=cut