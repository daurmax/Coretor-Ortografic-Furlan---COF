#!/usr/bin/env perl

=head1 NAME

database_utils.pl - COF database inspection and diagnostic utilities

=head1 SYNOPSIS

    perl util/database_utils.pl [options]

=head1 DESCRIPTION

Diagnostic tool for inspecting COF database contents (errors.db, elisions.db, frec.db).
Useful for debugging spell checker behavior and understanding database structure.

=head1 OPTIONS

    --help              Show this help message
    --errors            Inspect errors database only
    --elisions          Inspect elisions database only
    --frequency         Inspect frequency database only
    --test-word WORD    Test suggestions for specific word
    --show-top N        Show top N most frequent words (default: 10)
    --sample N          Show N sample entries per database (default: 20)

=head1 EXAMPLES

    # Full database investigation
    perl util/database_utils.pl
    
    # Inspect errors database only
    perl util/database_utils.pl --errors
    
    # Test specific word
    perl util/database_utils.pl --test-word furla
    
    # Show top 20 most frequent words
    perl util/database_utils.pl --frequency --show-top 20

=head1 AUTHOR

COF Development Team

=cut

use strict;
use warnings;
use utf8;
use FindBin;
use File::Spec;
use lib File::Spec->catdir($FindBin::Bin, '..', 'lib');
use Getopt::Long qw(GetOptions);

use COF::Data;
use COF::SpellChecker;
use COF::Utils qw(get_dict_dir);

binmode(STDOUT, ":encoding(utf8)");

# Parse command line options
my $help = 0;
my $show_errors = 0;
my $show_elisions = 0;
my $show_frequency = 0;
my $test_word = '';
my $show_top = 10;
my $sample_size = 20;

GetOptions(
    'help|h'        => \$help,
    'errors|e'      => \$show_errors,
    'elisions|l'    => \$show_elisions,
    'frequency|f'   => \$show_frequency,
    'test-word|w=s' => \$test_word,
    'show-top|t=i'  => \$show_top,
    'sample|s=i'    => \$sample_size,
) or die "Invalid options. Use --help for usage information.\n";

if ($help) {
    exec("perldoc", $0);
    exit 0;
}

# If no specific database selected, show all
my $show_all = !($show_errors || $show_elisions || $show_frequency || $test_word);

print "=" x 70, "\n";
print "COF DATABASE INVESTIGATION UTILITY\n";
print "=" x 70, "\n\n";

# Initialize COF::Data
my $dict_dir = get_dict_dir();
print "Dictionary directory: $dict_dir\n\n";

my $data;
eval {
    $data = COF::Data->new( COF::Data::make_default_args($dict_dir) );
};
if ($@ || !$data) {
    die "ERROR: Cannot initialize COF::Data: $@\n";
}

# === ERRORS DATABASE INVESTIGATION ===
if ($show_all || $show_errors) {
    print "=" x 70, "\n";
    print "ERRORS DATABASE (errors.db)\n";
    print "=" x 70, "\n";
    
    my $errors_db = $data->get_errors;
    my @error_keys = keys %$errors_db;
    print "Total entries: " . scalar(@error_keys) . "\n\n";
    
    if (@error_keys > 0) {
        print "Sample error patterns (first $sample_size):\n";
        for my $i (0..($sample_size-1)) {
            last if $i >= @error_keys;
            my $key = $error_keys[$i];
            my $value = $errors_db->{$key};
            print "  '$key' => '$value'\n";
        }
        
        # Look for specific patterns we commonly test
        print "\nCommon test patterns:\n";
        my @test_patterns = qw(furla scuela lengha cjasa ostaria anell plui);
        for my $pattern (@test_patterns) {
            if (exists $errors_db->{$pattern}) {
                print "  ✓ '$pattern' => '$errors_db->{$pattern}'\n";
            } else {
                print "  ✗ '$pattern' (not in errors.db)\n";
            }
        }
    } else {
        print "  (empty database)\n";
    }
    print "\n";
}

# === ELISIONS DATABASE INVESTIGATION ===
if ($show_all || $show_elisions) {
    print "=" x 70, "\n";
    print "ELISIONS DATABASE (elisions.db)\n";
    print "=" x 70, "\n";
    
    my $elisions_db = $data->get_elisions;
    my @elision_keys = keys %$elisions_db;
    print "Total entries: " . scalar(@elision_keys) . "\n\n";
    
    if (@elision_keys > 0) {
        print "Sample elision patterns (first $sample_size):\n";
        for my $i (0..($sample_size-1)) {
            last if $i >= @elision_keys;
            my $key = $elision_keys[$i];
            my $value = $elisions_db->{$key};
            print "  '$key' => '$value'\n";
        }
        
        # Look for specific elision patterns
        print "\nCommon Friulian elision patterns:\n";
        my @test_elisions = qw(aghe ore ale int erbis om);
        for my $word (@test_elisions) {
            my $has_elision = $data->word_has_elision($word);
            if ($has_elision) {
                print "  ✓ '$word' => '$has_elision'\n";
            } else {
                print "  ✗ '$word' (not in elisions.db)\n";
            }
        }
    } else {
        print "  (empty database)\n";
    }
    print "\n";
}

# === FREQUENCY DATABASE INVESTIGATION ===
if ($show_all || $show_frequency) {
    print "=" x 70, "\n";
    print "FREQUENCY DATABASE (frec.db)\n";
    print "=" x 70, "\n";
    
    my $freq_db = $data->get_freq;
    my @freq_keys = keys %$freq_db;
    print "Total entries: " . scalar(@freq_keys) . "\n\n";
    
    if (@freq_keys > 0) {
        print "Sample frequency data (first $sample_size):\n";
        for my $i (0..($sample_size-1)) {
            last if $i >= @freq_keys;
            my $key = $freq_keys[$i];
            my $value = $freq_db->{$key};
            print "  '$key' => $value\n";
        }
        
        # Show highest frequency words
        print "\nTop $show_top most frequent words:\n";
        my @sorted_by_freq = sort { $freq_db->{$b} <=> $freq_db->{$a} } @freq_keys;
        for my $i (0..($show_top-1)) {
            last if $i >= @sorted_by_freq;
            my $word = $sorted_by_freq[$i];
            my $freq = $freq_db->{$word};
            printf "  %2d. %-20s (frequency: %d)\n", $i+1, $word, $freq;
        }
    } else {
        print "  (empty database)\n";
    }
    print "\n";
}

# === SPELL CHECKER INTEGRATION TEST ===
if ($show_all || $test_word) {
    print "=" x 70, "\n";
    print "SPELLCHECKER INTEGRATION TEST\n";
    print "=" x 70, "\n\n";
    
    my $speller = COF::SpellChecker->new($data);
    
    # Test specific word if provided
    if ($test_word) {
        print "Testing word: '$test_word'\n";
        my $suggestions = $speller->suggest($test_word);
        if (@$suggestions > 0) {
            print "  Suggestions: " . join(', ', @$suggestions) . "\n";
        } else {
            print "  (no suggestions found)\n";
        }
        print "\n";
    }
    
    # Test error correction mechanisms
    if ($show_all) {
        print "Error correction test (common misspellings):\n";
        my @error_tests = qw(furla scuela lengha cjasa ostaria);
        for my $wrong_word (@error_tests) {
            my $suggestions = $speller->suggest($wrong_word);
            if (@$suggestions > 0) {
                my @top_suggestions = @$suggestions[0..min(2, $#$suggestions)];
                print "  '$wrong_word' => " . join(', ', @top_suggestions) . "\n";
            } else {
                print "  '$wrong_word' => (no suggestions)\n";
            }
        }
        
        print "\nElision handling test:\n";
        my @elision_tests = ("l'aghe", "un'ore", "dal'int", "d'estate");
        for my $elision_word (@elision_tests) {
            my $suggestions = $speller->suggest($elision_word);
            if (@$suggestions > 0) {
                my @top_suggestions = @$suggestions[0..min(2, $#$suggestions)];
                print "  '$elision_word' => " . join(', ', @top_suggestions) . "\n";
            } else {
                print "  '$elision_word' => (no suggestions)\n";
            }
        }
        print "\n";
    }
}

print "=" x 70, "\n";
print "END OF DATABASE INVESTIGATION\n";
print "=" x 70, "\n";

# Helper function
sub min {
    my ($a, $b) = @_;
    return $a < $b ? $a : $b;
}

__END__

=head1 SEE ALSO

L<COF::Data>, L<COF::SpellChecker>, L<COF::Utils>

=head1 COPYRIGHT

Copyright (C) 2025 COF Development Team

=cut
