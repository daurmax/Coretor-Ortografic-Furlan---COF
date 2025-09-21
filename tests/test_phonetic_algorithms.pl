#!/usr/bin/env perl
use strict;
use warnings;
use utf8;
use Test::More;
use FindBin;
use File::Spec;
use lib File::Spec->catdir($FindBin::Bin, '..', 'lib');

use COF::Data;

diag('Testing phonetic algorithm and utility functions');

# Test phalg_furlan algorithm (phonetic hashing for Friulian)
{
    # Test basic phonetic encoding
    my ($code1, $code2) = COF::Data::phalg_furlan('cjase');
    ok(defined $code1 && defined $code2, 'Phonetic: phalg_furlan returns two codes');
    ok(length($code1) > 0, 'Phonetic: first code is non-empty');
    
    # Test accent normalization
    my ($a1, $a2) = COF::Data::phalg_furlan('cafè');
    my ($b1, $b2) = COF::Data::phalg_furlan('cafe');
    # Should be similar due to accent normalization
    ok(defined($a1) && defined($b1), 'Phonetic: accented/unaccented both work');
    
    # Test apostrophe handling
    my ($ap1, $ap2) = COF::Data::phalg_furlan("l'aghe");
    ok(defined($ap1), 'Phonetic: apostrophe words handled');
    
    # Test empty string
    my ($e1, $e2) = COF::Data::phalg_furlan('');
    ok(defined($e1), 'Phonetic: empty string handled');
}

# Test Levenshtein distance with Friulian vowel equivalence
{
    my $dist1 = COF::Data::Levenshtein('cjase', 'cjase');
    is($dist1, 0, 'Levenshtein: identical words have distance 0');
    
    my $dist2 = COF::Data::Levenshtein('cjase', 'cjàse');
    # Note: depends on implementation if accents are normalized
    is($dist2, 0, 'Levenshtein: vowel variants have distance 0');
    
    my $dist3 = COF::Data::Levenshtein('cjase', 'gjase');
    ok($dist3 > 0, 'Levenshtein: different consonants have positive distance');
    
    my $dist4 = COF::Data::Levenshtein('', '');
    is($dist4, 0, 'Levenshtein: empty strings have distance 0');
    
    my $dist5 = COF::Data::Levenshtein('a', '');
    is($dist5, 1, 'Levenshtein: single char vs empty has distance 1');
}

# Test sort_friulian (Friulian-specific sorting)
{
    my @unsorted = qw(zeta beta alfa gamma);
    my @sorted = COF::Data::sort_friulian(@unsorted);
    is(scalar(@sorted), scalar(@unsorted), 'Sort: preserves array length');
    ok(@sorted > 0, 'Sort: returns non-empty array for non-empty input');
    
    # Test with Friulian-specific characters
    my @test_sort = qw(çà âl ê);
    my @result = COF::Data::sort_friulian(@test_sort);
    is(scalar(@result), 3, 'Sort: Friulian characters preserved');
}

# Test case conversion functions
{
    # Test ucf_word (uppercase first)
    my $ucf1 = COF::Data::ucf_word('cjase');
    is($ucf1, 'Cjase', 'Case: ucf_word capitalizes first letter');
    
    my $ucf2 = COF::Data::ucf_word('CJASE');
    ok(defined($ucf2), 'Case: ucf_word handles all caps');
    
    my $ucf3 = COF::Data::ucf_word('');
    is($ucf3, '', 'Case: ucf_word handles empty string');
    
    # Test lc_word (lowercase)
    my $lc1 = COF::Data::lc_word('CJASE');
    is($lc1, 'cjase', 'Case: lc_word converts to lowercase');
    
    my $lc2 = COF::Data::lc_word('Cjase');
    is($lc2, 'cjase', 'Case: lc_word handles mixed case');
    
    my $lc3 = COF::Data::lc_word('');
    is($lc3, '', 'Case: lc_word handles empty string');
    
    # Test first_is_uc (check if first is uppercase)
    my $is_uc1 = COF::Data::first_is_uc('Cjase');
    ok($is_uc1, 'Case: first_is_uc detects uppercase first');
    
    my $is_uc2 = COF::Data::first_is_uc('cjase');
    ok(!$is_uc2, 'Case: first_is_uc detects lowercase first');
    
    my $is_uc3 = COF::Data::first_is_uc('');
    # Empty string behavior may vary - just test it doesn't crash
    ok(defined($is_uc3), 'Case: first_is_uc handles empty string');
}

# Test error handling and edge cases
{
    # Test functions with very long strings
    my $long_word = 'a' x 1000;
    
    my $long_lev = eval { COF::Data::Levenshtein($long_word, 'short') };
    ok(!$@, 'Edge: Levenshtein handles very long strings');
    ok(defined($long_lev), 'Edge: Levenshtein returns result for long strings');
    
    my ($long_ph1, $long_ph2) = eval { COF::Data::phalg_furlan($long_word) };
    ok(!$@, 'Edge: phalg_furlan handles very long strings');
    
    my $long_ucf = eval { COF::Data::ucf_word($long_word) };
    ok(!$@, 'Edge: ucf_word handles very long strings');
    
    # Test with Unicode edge cases
    my $unicode_word = "test\x{0300}\x{0301}";  # combining characters
    
    my $unicode_lev = eval { COF::Data::Levenshtein($unicode_word, 'test') };
    ok(!$@, 'Unicode: Levenshtein handles combining characters');
    
    my ($unicode_ph1, $unicode_ph2) = eval { COF::Data::phalg_furlan($unicode_word) };
    ok(!$@, 'Unicode: phalg_furlan handles combining characters');
}

done_testing();

__END__

=head1 NAME

test_phonetic_algorithms.pl - Test phonetic and utility algorithms

=head1 DESCRIPTION

Tests the pure algorithmic functions from COF::Data that don't require
database access:

- phalg_furlan: Phonetic hashing algorithm for Friulian
- Levenshtein: Edit distance calculation with Friulian vowel equivalence  
- sort_friulian: Friulian-specific sorting algorithm
- ucf_word, lc_word, first_is_uc: Case conversion utilities

These functions are tested in isolation to verify correctness
independently of database functionality.

=cut