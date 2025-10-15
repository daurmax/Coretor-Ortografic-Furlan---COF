#!/usr/bin/perl
use strict;
use warnings;
use Getopt::Long;

=head1 NAME

nondeterminism_utils.pl - Detect non-deterministic suggestion ordering in COF

=head1 SYNOPSIS

    perl nondeterminism_utils.pl [options] word1 [word2 ...]
    
    Options:
        --iterations N      Number of iterations per word (default: 20)
        --top N            Number of top suggestions to check (default: 10)
        --verbose          Show all iterations (default: summary only)
        --help             Show this help message

=head1 DESCRIPTION

This utility detects non-deterministic ordering in COF suggestion lists.
Non-determinism occurs when multiple suggestions have the same frequency
AND Levenshtein distance, causing their order to depend on Perl's random
hash iteration order.

The script runs multiple iterations for each word and reports:
- Whether suggestions are deterministic or vary across runs
- Which positions show variation
- All unique orderings found
- Statistics on variant frequencies

=head1 EXAMPLES

    # Check a single word with default settings (20 iterations)
    perl nondeterminism_utils.pl scuela
    
    # Check multiple words with verbose output
    perl nondeterminism_utils.pl --verbose scuela prossim grant
    
    # Run 50 iterations and check top 15 suggestions
    perl nondeterminism_utils.pl --iterations 50 --top 15 scuela

=head1 ROOT CAUSE

Non-determinism is caused by hash iteration order in COF::SpellChecker::suggest_raw
(lines 189-200). When building the peso structure, indices are stored based on
hash key iteration order, which is undefined in Perl.

=head1 SEE ALSO

L<test_known_bugs.pl> - Test suite documenting known non-deterministic cases

=cut

BEGIN {
    use File::Basename qw(dirname);
    use File::Spec;
    my $lib_path = File::Spec->catdir(dirname(__FILE__), '..', 'lib');
    unshift @INC, $lib_path;
}

use COF::Data;
use COF::SpellChecker;

# === Command-line Options ===
my $iterations = 20;
my $top_n = 10;
my $verbose = 0;
my $help = 0;

GetOptions(
    'iterations=i' => \$iterations,
    'top=i'        => \$top_n,
    'verbose'      => \$verbose,
    'help'         => \$help,
) or die "Error in command line arguments\n";

if ($help || @ARGV == 0) {
    print_usage();
    exit 0;
}

sub print_usage {
    print <<'USAGE';
Usage: nondeterminism_utils.pl [options] word1 [word2 ...]

Options:
    --iterations N      Number of iterations per word (default: 20)
    --top N            Number of top suggestions to check (default: 10)
    --verbose          Show all iterations (default: summary only)
    --help             Show this help message

Examples:
    perl nondeterminism_utils.pl scuela
    perl nondeterminism_utils.pl --verbose --iterations 50 scuela prossim
USAGE
}

# === Initialize COF ===
my $dict_dir = File::Spec->catdir(dirname(__FILE__), '..', 'dict');
my $data = COF::Data->new(COF::Data::make_default_args($dict_dir));
my $sc = COF::SpellChecker->new($data);

print "Non-Determinism Detector for COF Suggestion Ordering\n";
print "=" x 70 . "\n";
print "Iterations per word: $iterations\n";
print "Top suggestions checked: $top_n\n";
print "\n";

# === Process Each Word ===
for my $word (@ARGV) {
    analyze_word($word);
}

sub analyze_word {
    my ($word) = @_;
    
    print "Analyzing: '$word'\n";
    print "-" x 70 . "\n";
    
    # Collect all orderings
    my @all_orderings;
    my %unique_orderings;
    
    for my $run (1..$iterations) {
        my $sugg_ref = $sc->suggest($word);
        my @suggestions = @$sugg_ref;
        
        # Take only top N
        my @top_suggestions = @suggestions[0 .. (($top_n - 1 < $#suggestions) ? $top_n - 1 : $#suggestions)];
        
        push @all_orderings, \@top_suggestions;
        
        # Create a string key for uniqueness
        my $key = join('|', @top_suggestions);
        $unique_orderings{$key}++;
        
        if ($verbose) {
            print "  Run $run: " . join(', ', @top_suggestions) . "\n";
        }
    }
    
    # Analyze results
    my $variant_count = scalar keys %unique_orderings;
    
    if ($variant_count == 1) {
        print "Result: DETERMINISTIC (all $iterations runs produced identical ordering)\n";
        print "Order: " . join(', ', @{$all_orderings[0]}) . "\n";
    } else {
        print "Result: NON-DETERMINISTIC ($variant_count unique orderings found)\n";
        print "\n";
        
        # Show all unique orderings with frequency
        my $variant_num = 1;
        for my $key (sort { $unique_orderings{$b} <=> $unique_orderings{$a} } keys %unique_orderings) {
            my $count = $unique_orderings{$key};
            my $percentage = sprintf("%.1f%%", ($count / $iterations) * 100);
            print "  Variant $variant_num ($count/$iterations = $percentage):\n";
            print "    " . join(', ', split(/\|/, $key)) . "\n";
            $variant_num++;
        }
        
        # Identify which positions vary
        print "\n";
        print "  Position Analysis:\n";
        my @position_variants;
        for my $pos (0 .. $#{$all_orderings[0]}) {
            my %values_at_pos;
            for my $ordering (@all_orderings) {
                $values_at_pos{$ordering->[$pos]}++ if defined $ordering->[$pos];
            }
            
            if (keys %values_at_pos > 1) {
                my @values = sort keys %values_at_pos;
                print "    Position $pos: " . scalar(@values) . " variants: " . 
                      join(', ', map { "'$_'" } @values) . "\n";
                push @position_variants, $pos;
            }
        }
        
        if (@position_variants) {
            print "\n";
            print "  Varying Positions: " . join(', ', @position_variants) . "\n";
            print "  Stable Positions: ";
            my @stable = grep { my $p = $_; !grep { $_ == $p } @position_variants } (0 .. $#{$all_orderings[0]});
            print((@stable ? join(', ', @stable) : 'none') . "\n");
        }
    }
    
    print "\n";
}

__END__

=head1 OUTPUT FORMAT

For each word, the script reports:

=over 4

=item * B<DETERMINISTIC>: All iterations produced identical ordering

=item * B<NON-DETERMINISTIC>: Multiple unique orderings found

=back

For non-deterministic cases, it shows:

=over 4

=item * All unique variants with their frequency

=item * Position-by-position analysis showing which positions vary

=item * List of stable vs varying positions

=back

=head1 TYPICAL NON-DETERMINISTIC CASES

Known words with non-deterministic ordering:

=over 4

=item * B<scuela>: positions 4-5 swap between 'scuelâi' and 'scuelai'

=item * B<prossim>: positions 4-5 swap between 'prossimÔ' and 'prossimÓ'

=item * B<grant>: multiple tied groups (usually beyond top 6)

=back

=head1 AUTHOR

COF Development Team

=head1 COPYRIGHT

Copyright (c) 2025 COF Project. All rights reserved.

=cut
