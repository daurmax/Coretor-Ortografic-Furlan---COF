#!/usr/bin/perl

# Test suite for Friulian phonetic algorithm (COF::DataCompat)
# Tests the phonetic hash generation algorithm for comprehensive coverage
# of Friulian linguistic patterns and edge cases

use strict;
use warnings;
use Test::More;
use lib '../lib';
use COF::DataCompat;

# Test data for Friulian phonetic algorithm
# Expected format: [word, expected_first_hash, expected_second_hash]
my @phonetic_test_cases = (
    # Core regression tests from original COF
    ['furlan', 'fYl65', 'fYl65'],
    ['cjase', 'A6A7', 'c7E7'],
    ['lenghe', 'X7', 'X7'],
    ['scuele', 'AA87l7', 'Ec87l7'],
    ['mandrie', '5659r77', '5659r77'],
    ['barcon', 'b2A85', 'b2c85'],
    ['nade', '5697', '5697'],
    ['specifiche', 'Ap7Af7A7', 'Ep7c7f7c7'],
    
    # From legacy phonetic tests (consolidated)
    ['çavatis', 'A6v6AA', 'ç6v697E'],
    ['cjatâ', 'A696', 'c7696'],
    ['diretamentri', 'I7r79O', 'Er79O'],
    ['sdrumâ', 'A9r856', 'E9r856'],
    ['aghe', '6g7', '6E7'],
    ['çucjar', 'A8A2', 'ç8c72'],
    ['çai', 'A6', 'ç6'],
    ['cafè', 'A6f7', 'c6f7'],
    ['cjanditi', 'A6597A', 'c765E97'],
    ['gjobat', 'g78b69', 'E8b69'],
    ['glama', 'gl656', 'El656'],
    ['gnûf', 'g584', 'E584'],
    ['savetât', 'A6v7969', 'E6v7969'],
    ['parol', 'p28l', 'p28l'],
    ['frut', 'fr89', 'fr89'],
    ['femine', 'f75757', 'f75757'],
    
    # Single characters and vowels
    ['a', '6', '6'],
    ['e', '7', '7'],
    ['i', '7', '7'],
    ['o', '8', '8'],
    ['u', '8', '8'],
    
    # Short words (1-2 syllables)
    ['me', '57', '57'],
    ['no', '58', '58'],
    ['sì', 'A', 'E7'],
    ['là', 'l6', 'l6'],
    
    # Basic words and common patterns
    ['nuie', '587', '587'],
    ['mote', '5897', '5897'],
    
    # Words with 'ç' consonant
    ['çarve', 'A2v7', 'ç2v7'],
    ['braç', 'br6A', 'br6ç'],
    ['piçul', 'p7A8l', 'p7ç8l'],
    ['çûç', 'A8A', 'ç8ç'],
    ['çucule', 'A8A8l7', 'ç8c8l7'],
    ['çuple', 'A8pl7', 'ç8pl7'],
    ['çurì', 'AY7', 'çY7'],
    ['çuse', 'A8A7', 'ç8E7'],
    ['çusse', 'A8A7', 'ç8E7'],
    
    # Words with 'gj' digraphs
    ['gjat', 'g769', 'E69'],
    ['bragje', 'br6g77', 'br6E7'],
    ['gjaldi', 'g76l97', 'E6l97'],
    ['gjalde', 'g76l97', 'E6l97'],
    ['gjenar', 'g7752', 'E752'],
    ['gjessis', 'g77AA', 'E7E7E'],
    ['gjetâ', 'g7796', 'E796'],
    ['gjoc', 'g78A', 'E80'],
    
    # Words with 'cj' digraphs
    ['cjalç', 'A6lA', 'c76lç'],
    ['ancje', '65A7', '65c77'],
    ['vecje', 'v7A7', 'v7c77'],
    ['cjandùs', 'A6598A', 'c76598E'],
    
    # Words with 'h' letter combinations
    ['ghe', 'g7', 'E7'],
    ['ghi', 'g7', 'E'],
    ['chê', 'A', 'c7'],
    ['schei', 'AA7', 'Ec7'],
    
    # Consonant clusters and complex sequences
    ['struc', 'A9r8A', 'E9r80'],
    ['spès', 'Ap7A', 'Ep7E'],
    ['blanc', 'bl65A', 'bl650'],
    ['spirt', 'Ap7r9', 'Ep7r9'],
    ['sdrume', 'A9r857', 'E9r857'],
    ['strucâ', 'A9r8A6', 'E9r8c6'],
    ['blave', 'bl6v7', 'bl6v7'],
    ['cnît', 'A579', 'c579'],
    
    # Words with apostrophes (common in Friulian)
    ["l'aghe", 'l6g7', 'l6E7'],
    ["d'àcue", 'I6A87', 'I6c87'],
    ["n'omp", '5853', '5853'],
    
    # Words with accented vowels
    ['gòs', 'g8A', 'E8E'],
    ['pôc', 'p8A', 'p80'],
    ['crês', 'Ar7A', 'cr7E'],
    ['fûc', 'f8A', 'f80'],
    ['nobèl', '58b7l', '58b7l'],
    ['babèl', 'b6b7l', 'b6b7l'],
    ['bertòs', 'b298A', 'b298E'],
    ['corfù', 'AYf8', 'cYf8'],
    ['epicûr', '7p7AY', '7p7cY'],
    ['maiôr', '56Y', '56Y'],
    ['nîf', '574', '574'],
    ['nîl', '57l', '57l'],
    ['nît', '579', '579'],
    ['mûf', '584', '584'],
    ['mûr', '5Y', '5Y'],
    ['mûs', '58A', '58E'],
    
    # Double consonants
    ['mame', '5657', '5657'],
    ['sasse', 'A6A7', 'E6E7'],
    ['puarte', 'pY97', 'pY97'],
    ['nissun', '57A85', '57E85'],
    
    # Words with specific endings
    ['prins', 'pr1', 'pr1'],
    ['gjenç', 'g775A', 'E75ç'],
    ['mont', '5859', '5859'],
    ['viert', 'v729', 'v729'],
    
    # Complex and longer words
    ['diretament', 'I7r7965759', 'Er7965759'],
    ['incjamarade', '75A652697', '75c7652697'],
    ['straçonarie', 'A9r6A85277', 'E9r6ç85277'],
);

# Plan number of tests
plan tests => scalar(@phonetic_test_cases) * 2 + 13; # 2 tests per word + enhanced robustness tests

# === TEST EXECUTION ===

diag("Testing COF::DataCompat Friulian phonetic algorithm");
diag("Total words tested: " . scalar(@phonetic_test_cases));

# Main phonetic algorithm tests
foreach my $test (@phonetic_test_cases) {
    my ($word, $expected_primo, $expected_secondo) = @$test;
    
    my ($primo, $secondo) = COF::DataCompat::phalg_furlan($word);
    
    is($primo, $expected_primo, "Word '$word' - first hash matches expected");
    is($secondo, $expected_secondo, "Word '$word' - second hash matches expected");
}

# Additional robustness tests
{
    diag("Robustness tests for phonetic algorithm");
    
    # Test empty string
    my ($e1, $e2) = COF::DataCompat::phalg_furlan('');
    is($e1, '', 'Empty string returns empty first hash');
    is($e2, '', 'Empty string returns empty second hash');
    
    # Test that both hashes are defined for valid words
    my ($t1, $t2) = COF::DataCompat::phalg_furlan('test');
    ok(defined($t1) && defined($t2), 'Valid word returns defined hashes');
    
    # Test consistency - same input should give same output
    my ($c1a, $c2a) = COF::DataCompat::phalg_furlan('consistency');
    my ($c1b, $c2b) = COF::DataCompat::phalg_furlan('consistency');
    ok($c1a eq $c1b && $c2a eq $c2b, 'Algorithm is consistent - same input gives same output');
    
    # Test non-empty hashes for non-empty input
    my ($nv1, $nv2) = COF::DataCompat::phalg_furlan('nonempty');
    ok(length($nv1) > 0 && length($nv2) > 0, 'Non-empty word produces non-empty hashes');
    
    # Test accented characters
    my ($acc1, $acc2) = COF::DataCompat::phalg_furlan('àèìòù');
    ok(defined($acc1) && defined($acc2), 'Accented characters handled properly');
    
    # Test apostrophes (common in Friulian)
    my ($apo1, $apo2) = COF::DataCompat::phalg_furlan("l'om");
    ok(defined($apo1) && defined($apo2), 'Apostrophes handled properly');
    
    # Test accent normalization
    my ($acc_a1, $acc_a2) = COF::DataCompat::phalg_furlan('cjatâ');
    my ($un_a1, $un_a2) = COF::DataCompat::phalg_furlan('cjata');
    is($acc_a1, $un_a1, 'Accented and unaccented versions produce same first hash');
    is($acc_a2, $un_a2, 'Accented and unaccented versions produce same second hash');
    
    # Test whitespace handling
    my ($ws1, $ws2) = COF::DataCompat::phalg_furlan('   ');
    is($ws1, '', 'Whitespace-only string returns empty first hash');
    is($ws2, '', 'Whitespace-only string returns empty second hash');
    
    # Test case insensitivity 
    my ($upper1, $upper2) = COF::DataCompat::phalg_furlan('FURLAN');
    my ($lower1, $lower2) = COF::DataCompat::phalg_furlan('furlan');
    is($upper1, $lower1, 'Uppercase and lowercase produce same first hash');
    is($upper2, $lower2, 'Uppercase and lowercase produce same second hash');
}

done_testing();

print "\n# Friulian phonetic algorithm tests completed\n";
print "# Total tests executed: " . (scalar(@phonetic_test_cases) * 2 + 13) . "\n";