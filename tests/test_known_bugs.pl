#!/usr/bin/perl
# Test suite for KNOWN BUGS in COF suggestion ranking algorithm
#
# IMPORTANT: This test suite documents ACTUAL COF behavior including bugs.
# These are NOT ideal behaviors, but they represent the historical behavior
# of COF and serve as a record of known issues in the codebase.
#
# BUG DOCUMENTED: Non-deterministic suggestion ordering
# ------------------------------------------------------
# When multiple suggestions have the same frequency AND the same Levenshtein
# distance, their relative order is NON-DETERMINISTIC due to Perl hash
# iteration order being undefined.
#
# Root Cause (in COF::SpellChecker::suggest_raw, lines 189-200):
#   for my $p ( keys %$list ) {  # ← Hash iteration order is undefined!
#       push( @parole_trovate, $p );
#   }
#   @parole_trovate = COF::Data::sort_friulian(@parole_trovate);
#   foreach my $indice_parola ( 0 .. $#parole_trovate ) {
#       my $y    = $parole_trovate[$indice_parola];
#       my $vals = $list->{$y};
#       push @{ $parole_hamming{ $vals->[0] }{ $vals->[1] } }, $indice_parola;
#   }
#
# The indices stored in $parole_hamming{freq}{dist} depend on the order
# of hash iteration, which is non-deterministic. When suggest() outputs
# these indices, tied suggestions appear in random order.
#
# Impact: Words like 'scuela' produce different orderings across runs:
#   - Sometimes: [..., 'scuelai', 'scuelâi']
#   - Sometimes: [..., 'scuelâi', 'scuelai']
#
# Why This Test Exists:
# ---------------------
# This test serves as historical documentation of COF's behavior at the time
# of writing. It helps identify which suggestions have non-deterministic ordering
# and documents the root cause for future reference or potential fixes.

use strict;
use warnings;
use Test::More;
use lib 'lib';
use File::Basename qw(dirname);
use File::Spec;

# Add lib directory to include path
BEGIN {
    my $lib_path = File::Spec->catdir(dirname(__FILE__), '..', 'lib');
    unshift @INC, $lib_path;
}

use COF::Data;
use COF::SpellChecker;

# Get dictionary directory
my $dict_dir = File::Spec->catdir(dirname(__FILE__), '..', 'dict');
ok(-d $dict_dir, "Dictionary directory exists: $dict_dir") or plan skip_all => 'No dictionary directory';

my $data = eval { COF::Data->new(COF::Data::make_default_args($dict_dir)); };
if ($@ || !$data) {
    plan skip_all => 'Data not available';
}

my $spellchecker = eval { COF::SpellChecker->new($data); };
if ($@ || !$spellchecker) {
    plan skip_all => 'SpellChecker not available';
}

ok($spellchecker, 'SpellChecker available');

diag('');
diag('==========================================================================');
diag('TESTING KNOWN BUGS: Non-Deterministic Suggestion Ordering');
diag('==========================================================================');
diag('These tests document actual COF behavior including known bugs.');
diag('This serves as historical documentation of the codebase behavior.');
diag('==========================================================================');
diag('');

# Test words known to have non-deterministic ordering
my @test_words = ('scuela', 'grant');

# === TEST 1: Verify Non-Determinism Exists ===
# This test confirms that certain words produce variable ordering
{
    diag('Test 1: Detecting non-deterministic ordering across multiple runs');
    diag('');
    
    for my $word (@test_words) {
        diag("  Testing word: '$word'");
        
        my %seen_orders;
        my $iterations = 20;
        
        for my $i (1..$iterations) {
            my $sugg_ref = $spellchecker->suggest($word);
            my @top6 = @$sugg_ref[0..5];
            my $order_key = join('|', @top6);
            $seen_orders{$order_key}++;
        }
        
        my $unique_orders = scalar keys %seen_orders;
        diag("    Iterations: $iterations, Unique orderings: $unique_orders");
        
        if ($word eq 'scuela') {
            # 'scuela' is KNOWN to have non-deterministic ordering
            ok($unique_orders > 1, 
               "BUG CONFIRMED: '$word' produces multiple orderings (found $unique_orders variants)");
            
            if ($unique_orders > 1) {
                diag("    Variants detected:");
                my $count = 1;
                for my $order (sort keys %seen_orders) {
                    my @suggestions = split(/\|/, $order);
                    diag(sprintf("      Variant %d (seen %dx): %s", 
                                 $count++, $seen_orders{$order}, join(', ', @suggestions)));
                }
            }
        } elsif ($word eq 'grant') {
            # 'grant' may or may not show variability in top 6
            # (depends on which tied suggestions fall in top 6)
            diag("    Note: 'grant' has tied suggestions but may not vary in top 6");
            pass("'grant' ordering checked: $unique_orders variant(s) in top 6");
        }
        
        diag('');
    }
}

# === TEST 2: Analyze Root Cause in peso Hash ===
# This test examines the internal peso structure to identify why
# certain suggestions have non-deterministic ordering
{
    diag('Test 2: Analyzing peso hash structure for tied suggestions');
    diag('');
    
    for my $word (@test_words) {
        diag("  Analyzing '$word' peso structure:");
        
        # Call suggest_raw to get the peso structure
        my ($peso, $sugg) = $spellchecker->suggest_raw($word);
        
        # Find entries with multiple indices (cause of non-determinism)
        my @tied_groups;
        for my $f (keys %$peso) {
            for my $d (keys %{$peso->{$f}}) {
                my @indices = @{$peso->{$f}->{$d}};
                if (@indices > 1) {
                    my @words = map { $sugg->[$_] } @indices;
                    push @tied_groups, {
                        freq => $f,
                        dist => $d,
                        count => scalar(@indices),
                        indices => \@indices,
                        words => \@words
                    };
                }
            }
        }
        
        if (@tied_groups) {
            ok(1, "Found " . scalar(@tied_groups) . " peso entries with tied suggestions for '$word'");
            
            for my $group (sort { $b->{freq} <=> $a->{freq} || $a->{dist} <=> $b->{dist} } @tied_groups) {
                diag(sprintf("    peso{freq=%d, dist=%d}: %d tied suggestions", 
                            $group->{freq}, $group->{dist}, $group->{count}));
                diag(sprintf("      Words: %s", join(', ', @{$group->{words}})));
                diag("      ↑ These suggestions will have non-deterministic ordering");
            }
        } else {
            ok(1, "No tied suggestions found for '$word' (all have unique freq+dist)");
        }
        
        diag('');
    }
}

# === TEST 3: Document Expected Variants for 'scuela' ===
# Since 'scuela' is known to be non-deterministic, we document
# the possible valid orderings that COF produces
{
    diag('Test 3: Documenting valid ordering variants for scuela');
    diag('');
    
    my $word = 'scuela';
    my $sugg_ref = $spellchecker->suggest($word);
    my @suggestions = @$sugg_ref;
    
    # Known variants for positions 4-5 (0-indexed)
    # Note: Using double quotes for \xNN escape sequences (Latin-1 encoding)
    my %valid_variants = (
        'variant_a' => ["scuelai", "scuel\xE2i"],  # scuelai, scuelâi
        'variant_b' => ["scuel\xE2i", "scuelai"],  # scuelâi, scuelai
    );
    
    my @pos_4_5 = @suggestions[4, 5];
    my $found_variant = 'unknown';
    
    for my $var_name (keys %valid_variants) {
        my @expected = @{$valid_variants{$var_name}};
        if ($pos_4_5[0] eq $expected[0] && $pos_4_5[1] eq $expected[1]) {
            $found_variant = $var_name;
            last;
        }
    }
    
    if ($found_variant ne 'unknown') {
        pass("'scuela' positions 4-5 match known variant: $found_variant");
        diag("    Current order: " . join(', ', @suggestions[0..5]));
        diag("    Positions 4-5: " . join(', ', @pos_4_5));
        diag("    Both orderings are valid due to non-determinism bug");
    } else {
        fail("'scuela' positions 4-5 don't match any known variant");
        diag("    Got: " . join(', ', @pos_4_5));
        diag("    Expected either: " . join(', ', @{$valid_variants{variant_a}}) . 
             " OR " . join(', ', @{$valid_variants{variant_b}}));
    }
    
    diag('');
}

# === TEST 4: Verify First 4 Suggestions are Stable ===
# Even though positions 4-5 vary, positions 0-3 should be stable
{
    diag('Test 4: Verifying stable positions (0-3) for scuela');
    diag('');
    
    my $word = 'scuela';
    # Note: Using double quotes for \xNN escape sequences (Latin-1 encoding)
    my @expected_stable = ("scuele", "scueli", "scuel\xE2", "scuel\xE0");
    
    my %all_variations;
    for (1..10) {
        my $sugg_ref = $spellchecker->suggest($word);
        my @top4 = @$sugg_ref[0..3];
        my $key = join('|', @top4);
        $all_variations{$key}++;
    }
    
    is(scalar(keys %all_variations), 1, 
       "First 4 suggestions for 'scuela' are stable across runs");
    
    my ($stable_order) = keys %all_variations;
    my @actual = split(/\|/, $stable_order);
    is_deeply(\@actual, \@expected_stable,
              "First 4 suggestions match expected order: " . join(', ', @expected_stable));
    
    diag('');
}

done_testing();

__END__

=head1 NAME

verify_nondeterminism.pl - Test suite for KNOWN BUGS in COF suggestion ranking

=head1 DESCRIPTION

This test suite documents ACTUAL COF behavior including known bugs. These are
NOT ideal behaviors, but they represent the ground truth state of the codebase
at the time of writing, preserved for historical documentation.

=head1 KNOWN BUG: Non-Deterministic Suggestion Ordering

=head2 Description

When multiple suggestions have the same frequency AND the same Levenshtein
distance, their relative order is NON-DETERMINISTIC due to Perl hash
iteration order being undefined.

=head2 Root Cause

In COF::SpellChecker::suggest_raw (lines 189-200):

    for my $p ( keys %$list ) {  # ← Hash iteration order is undefined!
        push( @parole_trovate, $p );
    }
    @parole_trovate = COF::Data::sort_friulian(@parole_trovate);
    foreach my $indice_parola ( 0 .. $#parole_trovate ) {
        my $y    = $parole_trovate[$indice_parola];
        my $vals = $list->{$y};
        push @{ $parole_hamming{ $vals->[0] }{ $vals->[1] } }, $indice_parola;
    }

The indices stored in C<$parole_hamming{freq}{dist}> depend on the order
of hash iteration, which is non-deterministic. When suggest() outputs
these indices, tied suggestions appear in random order.

=head2 Impact

Words like 'scuela' produce different orderings across runs:

    Sometimes: [..., 'scuelai', 'scuelâi']
    Sometimes: [..., 'scuelâi', 'scuelai']

=head2 Affected Words

Known affected words (have tied suggestions):
- B<scuela>: positions 4-5 swap between 'scuelai' and 'scuelâi'
- B<grant>: multiple tied groups (usually beyond top 6)

=head2 Why This Matters

This test documents the exact behavior (including bugs) at the time of writing.
If COF is ever modified or fixed, this test will fail, alerting us to changes
in the codebase behavior that may need documentation updates.

=head2 Test Strategy

1. Detect non-determinism by running multiple iterations
2. Analyze peso structure to identify tied suggestions
3. Document valid variants for known affected words
4. Verify stable positions remain stable

=head1 SEE ALSO

L<test_suggestion_ranking.pl> - Main suggestion ranking tests

L<COF::SpellChecker> - Suggestion engine with the documented bug

=cut
