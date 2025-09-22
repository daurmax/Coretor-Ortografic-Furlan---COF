#!/usr/bin/perl
#
# test_phonetic_algorithm.pl - Comprehensive tests for Friulian phonetic algorithm
#
# Tests the COF::DataCompat phalg_furlan algorithm with diverse Friulian words
# Validates phonetic hash generation for accurate spell checking and word matching
#

use strict;
use warnings;
use utf8;
use Test::More;
use FindBin;
use lib "$FindBin::Bin/../lib";

# Use COF::DataCompat for compatibility across different systems
use COF::DataCompat;

# === COMPREHENSIVE TEST CASES ===

# Comprehensive test cases covering diverse Friulian phonetic patterns
my @phonetic_test_cases = (
    # Da test_core_functionality_compat.pl (corretti con COF::DataCompat)
    ['furlan', 'fYl65', 'fYl65'],
    ['cjase', 'A6A7', 'c76E7'],  
    ['lenghe', 'X7', 'X7'],
    ['scuele', 'AA87l7', 'Ec87l7'],
    ['mandrie', '5659r77', '5659r77'],
    ['barcon', 'b2A85', 'b2c85'],
    ['nade', '5697', '5697'],
    ['specifiche', 'Ap7Af7A7', 'Ep7c7f7c7'],
    
    # Da test_phonetic_perl.pl (consolidate le duplicazioni)
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
    
    # Words with ç in different positions
    # Parole con ç in posizioni diverse
    ['çarve', 'A2v7', 'ç2v7'],
    ['braç', 'br6A', 'br6ç'],
    ['piçul', 'p7A8l', 'p7ç8l'],
    
    # Parole con gj/gi
    ['gjat', 'g769', 'E69'],
    ['bragje', 'br6g77', 'br6E7'],
    ['gjaldi', 'g76l97', 'E6l97'],
    
    # Parole con cj
    ['cjalç', 'A6lA', 'c76lç'],
    ['ancje', '65A7', '65c77'],
    ['vecje', 'v7A7', 'v7c77'],
    
    # Sequenze consonantiche
    ['struc', 'A9r8A', 'E9r80'],
    ['spès', 'Ap7A', 'Ep7E'],
    ['blanc', 'bl65A', 'bl650'],
    ['spirt', 'Ap7r9', 'Ep7r9'],
    
    # Parole con h
    ['ghe', 'g7', 'E7'],
    ['ghi', 'g7', 'E'],
    ['chê', 'A', 'c7'],
    ['schei', 'AA7', 'Ec7'],
    
    # Parole con apostrofo
    ["l'aghe", 'l6g7', 'l6E7'],
    ["d'àcue", 'I6A87', 'I6c87'],
    ["n'omp", '5853', '5853'],
    
    # Vocali accentate
    ['gòs', 'g8A', 'E8E'],
    ['pôc', 'p8A', 'p80'],
    ['crês', 'Ar7A', 'cr7E'],
    ['fûc', 'f8A', 'f80'],
    ['çûç', 'A8A', 'ç8ç'],
    
    # Combinazioni particolari
    ['sdrume', 'A9r857', 'E9r857'],
    ['strucâ', 'A9r8A6', 'E9r8c6'],
    ['blave', 'bl6v7', 'bl6v7'],
    
    # Doppie consonanti
    ['mame', '5657', '5657'],
    ['sasse', 'A6A7', 'E6E7'],
    ['puarte', 'pY97', 'pY97'],
    
    # Finali particolari
    ['prins', 'pr1', 'pr1'],
    ['gjenç', 'g775A', 'E75ç'],
    ['mont', '5859', '5859'],
    ['viert', 'v729', 'v729'],
    
    # Parole corte
    ['me', '57', '57'],
    ['no', '58', '58'],
    ['sì', 'A', 'E7'],
    ['là', 'l6', 'l6'],
    
    # Longer complex words
    ['diretament', 'I7r7965759', 'Er7965759'],
    ['incjamarade', '75A652697', '75c7652697'],
    ['straçonarie', 'A9r6A85277', 'E9r6ç85277'],
);

# Plan number of tests
plan tests => scalar(@phonetic_test_cases) * 2 + 7; # 2 tests per word + robustness tests

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
}

done_testing();

print "\n# Friulian phonetic algorithm tests completed\n";
print "# Total tests executed: " . (scalar(@phonetic_test_cases) * 2 + 7) . "\n";