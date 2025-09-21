#!/usr/bin/env perl
use strict;
use warnings;
use utf8;
use Test::More;
use FindBin;
use File::Spec;
use lib File::Spec->catdir($FindBin::Bin, '..', 'lib');

use COF::Data;
use COF::SpellChecker;
use COF::Utils qw(get_dict_dir);

diag('Testing core functionality: database, spell checker, and phonetic algorithms');

# === Database Real Connection Tests ===
{
    diag('Testing real database connections using CLI method');
    
    # Test 1: Check if dictionary directory exists and is accessible
    my $dict_dir = get_dict_dir();
    ok(-d $dict_dir, "Dictionary directory exists: $dict_dir");
    
    # Check for required database files
    my @required_files = qw(words.db words.rt elisions.db errors.db frec.db);
    for my $file (@required_files) {
        my $full_path = File::Spec->catfile($dict_dir, $file);
        ok(-f $full_path, "Required database file exists: $file");
        ok(-r $full_path, "Database file is readable: $file");
    }
    
    # Test 2: Create COF::Data object using the exact same method as CLI
    my $data;
    eval {
        $data = COF::Data->new( COF::Data::make_default_args( get_dict_dir() ) );
    };
    
    ok(!$@, "COF::Data creation successful: " . ($@ || 'no error'));
    ok(defined($data), "COF::Data object is defined");
    isa_ok($data, 'COF::Data', "Data object has correct type");
    
    SKIP: {
        skip "Cannot create COF::Data object: $@", 10 if $@;
        
        # Test 3: Basic SpellChecker functionality with real database
        my $speller = COF::SpellChecker->new($data);
        ok(defined($speller), "SpellChecker created successfully");
        isa_ok($speller, 'COF::SpellChecker', "SpellChecker has correct type");
        
        # Test word checking (like the CLI 'c' command)
        my @test_words = qw(furlan lenghe cjase aghe scuele parol frut femine om);
        my $valid_words_found = 0;
        
        for my $word (@test_words) {
            my $result = $speller->check_word($word);
            if ($result && $result->{'ok'}) {
                $valid_words_found++;
                pass("Word '$word' found in dictionary");
                last if $valid_words_found >= 3; # Limit output
            }
        }
        
        ok($valid_words_found > 0, "Found valid words in dictionary");
        
        # Test suggestion mechanism (like CLI 's' command)
        my $suggestions = $speller->suggest('furla'); # misspelled 'furlan'
        ok(defined($suggestions), "suggest() returns defined result");
        ok(ref($suggestions) eq 'ARRAY', "suggest() returns array reference");
        
        # Test case sensitivity handling
        if ($valid_words_found > 0) {
            my $test_word = 'furlan';
            my $upper_result = $speller->check_word(uc($test_word));
            ok(defined($upper_result), "Uppercase word handled");
            
            my $mixed_result = $speller->check_word(ucfirst($test_word));
            ok(defined($mixed_result), "Mixed case word handled");
        } else {
            skip "No valid words found for case testing", 2;
        }
        
        # Test punctuation handling (like CLI handles dots)
        my $punct_result = eval { $speller->check_word('furlan.') };
        ok(!$@, "Punctuation handled gracefully: " . ($@ || 'no error'));
        
        # Test Unicode and accent handling
        my $unicode_result = eval { $speller->check_word('cjàse') };
        ok(!$@, "Unicode handled gracefully: " . ($@ || 'no error'));
        
        # Test edge cases
        my $empty_result = eval { $speller->check_word('') };
        ok(!$@, "Empty string handled gracefully");
        
        my $long_result = eval { $speller->check_word('a' x 100) };
        ok(!$@, "Very long word handled gracefully");
    }
}

# === Phonetic Algorithms Tests ===
{
    diag('Testing phonetic algorithm and utility functions');
    
    # Test phalg_furlan algorithm (phonetic hashing for Friulian)
    my ($code1, $code2) = COF::Data::phalg_furlan('cjase');
    ok(defined $code1 && defined $code2, 'Phonetic: phalg_furlan returns two codes');
    ok(length($code1) > 0, 'Phonetic: first code is non-empty');
    
    # Test accent normalization
    my ($a1, $a2) = COF::Data::phalg_furlan('cafè');
    my ($b1, $b2) = COF::Data::phalg_furlan('cafe');
    ok(defined($a1) && defined($b1), 'Phonetic: accented/unaccented both work');
    
    # Test apostrophe handling
    my ($ap1, $ap2) = COF::Data::phalg_furlan("l'aghe");
    ok(defined($ap1), 'Phonetic: apostrophe words handled');
    
    # Test empty string
    my ($e1, $e2) = COF::Data::phalg_furlan('');
    ok(defined($e1), 'Phonetic: empty string handled');
    
    # Test Levenshtein distance with Friulian vowel equivalence
    my $dist1 = COF::Data::Levenshtein('cjase', 'cjase');
    is($dist1, 0, 'Levenshtein: identical words have distance 0');
    
    my $dist2 = COF::Data::Levenshtein('cjase', 'cjàse');
    is($dist2, 0, 'Levenshtein: vowel variants have distance 0');
    
    my $dist3 = COF::Data::Levenshtein('cjase', 'gjase');
    ok($dist3 > 0, 'Levenshtein: different consonants have positive distance');
    
    my $dist4 = COF::Data::Levenshtein('', '');
    is($dist4, 0, 'Levenshtein: empty strings have distance 0');
    
    my $dist5 = COF::Data::Levenshtein('a', '');
    is($dist5, 1, 'Levenshtein: single char vs empty has distance 1');
    
    # Test sort_friulian (Friulian-specific sorting)
    my @unsorted = qw(zeta beta alfa gamma);
    my @sorted = COF::Data::sort_friulian(@unsorted);
    is(scalar(@sorted), scalar(@unsorted), 'Sort: preserves array length');
    ok(@sorted > 0, 'Sort: returns non-empty array for non-empty input');
    
    # Test case conversion functions
    my $ucf1 = COF::Data::ucf_word('cjase');
    is($ucf1, 'Cjase', 'Case: ucf_word capitalizes first letter');
    
    my $lc1 = COF::Data::lc_word('CJASE');
    is($lc1, 'cjase', 'Case: lc_word converts to lowercase');
    
    my $is_uc1 = COF::Data::first_is_uc('Cjase');
    ok($is_uc1, 'Case: first_is_uc detects uppercase first');
    
    my $is_uc2 = COF::Data::first_is_uc('cjase');
    ok(!$is_uc2, 'Case: first_is_uc detects lowercase first');
    
    # Test error handling with edge cases
    my $long_word = 'a' x 1000;
    my $long_lev = eval { COF::Data::Levenshtein($long_word, 'short') };
    ok(!$@, 'Edge: Levenshtein handles very long strings');
    
    my ($long_ph1, $long_ph2) = eval { COF::Data::phalg_furlan($long_word) };
    ok(!$@, 'Edge: phalg_furlan handles very long strings');
}

done_testing();

__END__

=head1 NAME

test_core_functionality.pl - Core functionality tests for COF

=head1 DESCRIPTION

Comprehensive test suite for core COF functionality:

- Real database connections using CLI method
- SpellChecker functionality with real backend
- Phonetic algorithms (phalg_furlan, Levenshtein, sort_friulian)
- Case conversion utilities
- Error handling and edge cases

Uses the same database connection method as the working CLI script:
COF::Data->new(COF::Data::make_default_args(get_dict_dir()))

=cut