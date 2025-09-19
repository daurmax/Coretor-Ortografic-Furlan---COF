#!/usr/bin/env perl

use strict;
use warnings;
use utf8;
use Test::More;
use FindBin;
use File::Spec;
use lib File::Spec->catdir($FindBin::Bin, '..', 'lib');

use COF::Data;

# Test setup
plan tests => 47;

# Initialize COF components with database files
my $dict_dir = File::Spec->catdir($FindBin::Bin, '..', 'dict');

# Test cases with expected results extracted from actual COF behavior
my @test_cases = (
    # Basic Friulian words
    ["cjatâ", "A696", "c7696"],
    ["'savote", "A6v897", "E6v897"],
    ["çavatis", "A6v6AA", "þ6v697E"],
    ["diretamentri", "I7r79O", "Er79O"],
    ["sdrumâ", "A9r856", "E9r856"],
    ["rinfuarçadis", "r75fYA697A", "r75fYþ6EE"],
    ["marilenghe", "527X7", "527X7"],
    ["mandi", "56597", "56597"],
    ["dindi", "I7597", "E597"],
    
    # Consonant clusters and special handling
    ["gjat", "g769", "E69"],
    ["fuee", "f87", "f87"],
    ["cjjar", "A2", "c72"],
    ["fuje", "f877", "f877"],
    ["che", "A", "c7"],
    ["sciençe", "A75A7", "E775c7"],
    
    # Diphthongs and vowel sequences
    ["ai", "6", "6"],
    ["ei", "7", "7"],
    ["ou", "8", "8"],
    ["oi", "8", "8"],
    ["vu", "8", "8"],
    
    # Consonant variations
    ["tane", "H657", "H657"],
    ["dane", "I657", "I657"],
    ["bat", "b69", "b69"],
    ["bad", "b69", "b69"],
    
    # Special transformations
    ["leng", "X", "X"],
    ["lingu", "X", "X"],
    ["amentri", "O", "O"],
    ["ementi", "O", "O"],
    ["uintri", "W", "W"],
    ["ontra", "W", "W"],
    ["ur", "Y", "Y"],
    ["uar", "Y", "Y"],
    ["or", "Y", "Y"],
    
    # Apostrophes and special characters
    ["'s", "A", "E"],
    ["'n", "5", "5"],
    
    # Endings and consonant clusters
    ["ins", "1", "1"],
    ["in", "1", "1"],
    ["mn", "5", "5"],
    ["nm", "5", "5"],
    ["m", "5", "5"],
    ["n", "5", "5"],
    ["er", "2", "2"],
    ["ar", "2", "2"],
    ["colegb", "A8l7g3", "c8l7E3"],
    ["stopp", "A983", "E983"],
    ["altrev", "6l9r74", "6l9r74"],
    ["altref", "6l9r74", "6l9r74"],
);

# Run tests for each case
for my $i (0..$#test_cases) {
    my ($word, $expected_hash1, $expected_hash2) = @{$test_cases[$i]};
    
    my ($actual_hash1, $actual_hash2) = COF::Data::phalg_furlan($word);
    
    diag("Word: $word");
    diag("Expected: ($expected_hash1, $expected_hash2)");
    diag("Actual: ($actual_hash1, $actual_hash2)");
    
    is($actual_hash1, $expected_hash1, "Phonetic hash1 for '$word'");
}

done_testing();

__END__

=head1 NAME

test_phonetic_perl.pl - Phonetic algorithm tests for COF

=head1 DESCRIPTION

This test suite validates the phonetic algorithm (phalg_furlan) functionality by testing:
- Basic Friulian word transformations
- Consonant clusters and special character handling
- Diphthongs and vowel sequences
- Special transformations and edge cases
- Apostrophes and ending patterns

Tests validate the correctness of the Perl implementation using extracted COF results as expected values.

=head1 USAGE

    perl test_phonetic_perl.pl

Run from the tests/ directory. Tests the phonetic algorithm implementation
without requiring dictionary database files.

=cut