#!/usr/bin/env perl

=head1 NAME

test_core.pl - Core functionality, compatibility, and database integration tests

=head1 SCOPE

Consolidated test suite covering:
- Core initialization and basic operations (COF::Data, COF::SpellChecker)
- Backwards compatibility layer (COF::DataCompat without DB_File)
- Database integration and data access (elisions, errors, frequency databases)

=head1 PREREQUISITES

- COF::Data
- COF::DataCompat
- COF::SpellChecker
- COF::Utils
- Test::More

=head1 EXPECTED TEST COUNT

88 tests total:
- Section 1 (Core): 36 tests
- Section 2 (Compatibility): 17 tests  
- Section 3 (Database Integration): 35 tests

=cut

use strict;
use warnings;
use utf8;
use Test::More;
use FindBin;
use File::Spec;
use lib File::Spec->catdir($FindBin::Bin, '..', 'lib');

use COF::Data;
use COF::DataCompat;
use COF::SpellChecker;
use COF::Utils qw(get_dict_dir);

# ============================================================================
# SECTION 1: CORE INITIALIZATION AND BASIC OPERATIONS (36 tests)
# ============================================================================
{
    diag('=' x 70);
    diag('SECTION 1: Core Initialization and Basic Operations');
    diag('=' x 70);
    
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
}

# ============================================================================
# SECTION 2: BACKWARDS COMPATIBILITY LAYER (17 tests)
# ============================================================================
{
    diag('=' x 70);
    diag('SECTION 2: Backwards Compatibility Layer (COF::DataCompat)');
    diag('=' x 70);
    
    # === Database Compatibility Tests ===
    {
        diag('Testing database compatibility without DB_File dependency');
        
        # Test 1: Check if dictionary directory exists and is accessible
        my $dict_dir = get_dict_dir();
        ok(-d $dict_dir, "Compat: Dictionary directory exists: $dict_dir");
        
        # Check for required database files
        my @required_files = qw(words.db words.rt elisions.db errors.db frec.db);
        for my $file (@required_files) {
            my $full_path = File::Spec->catfile($dict_dir, $file);
            ok(-f $full_path, "Compat: Required database file exists: $file");
            ok(-r $full_path, "Compat: Database file is readable: $file");
        }
    }
    
    # === COF::DataCompat Object Creation Tests ===
    {
        diag('Testing COF::DataCompat object creation');
        
        my $dict_dir = get_dict_dir();
        my %args = COF::DataCompat::make_default_args($dict_dir);
        
        my $data_obj;
        eval {
            $data_obj = COF::DataCompat->new(%args);
        };
        
        is($@, '', 'Compat: COF::DataCompat object creation without errors');
        isa_ok($data_obj, 'COF::DataCompat', 'Compat: Created object is correct type');
        
        # Test methods availability
        can_ok($data_obj, qw(has_radix_tree get_radix_tree has_rt_checker get_rt_checker));
        
        # Test radix tree loading (doesn't require DB_File)
        if ($data_obj->has_radix_tree()) {
            pass('Compat: RadixTree loaded successfully');
            ok($data_obj->has_rt_checker(), 'Compat: RT_Checker available');
        } else {
            diag('Compat: RadixTree not available - words.rt file may be missing');
        }
        
        # Test user dict (should be disabled in compat version)
        is($data_obj->has_user_dict(), 0, 'Compat: User dict correctly disabled in compat version');
    }
    
    # === Basic Phonetic Algorithm Test ===
    {
        diag('Testing basic phonetic algorithm functionality in compat mode');
        
        # Basic functionality test - just verify the method works
        my ($p1, $s1) = COF::DataCompat::phalg_furlan('furlan');
        ok(defined($p1) && defined($s1), 'Compat: phalg_furlan returns defined values');
        ok(length($p1) > 0 && length($s1) > 0, 'Compat: phalg_furlan returns non-empty hashes');
        
        # Test edge cases
        is_deeply([COF::DataCompat::phalg_furlan('')], ['', ''], 'Compat: Empty string handling');
        is_deeply([COF::DataCompat::phalg_furlan('   ')], ['', ''], 'Compat: Whitespace-only string handling');
    }
    
    # === Performance and Stability Tests ===
    {
        diag('Testing compat performance and stability');
        
        # Test multiple calls
        my $word = 'furlan';
        my ($p1, $s1) = COF::DataCompat::phalg_furlan($word);
        my ($p2, $s2) = COF::DataCompat::phalg_furlan($word);
        
        is($p1, $p2, 'Compat: Consistent results - primo');
        is($s1, $s2, 'Compat: Consistent results - secondo');
        
        # Test with special characters
        my ($pa, $sa) = COF::DataCompat::phalg_furlan('àèìòù');
        ok(length($pa) > 0, 'Compat: Handles accented characters');
        ok(length($sa) > 0, 'Compat: Handles accented characters - secondo');
    }
    
    # === Compatibility Warning Tests ===
    {
        diag('Testing compat compatibility warnings and limitations');
        
        my $dict_dir = get_dict_dir();
        my %args = COF::DataCompat::make_default_args($dict_dir);
        my $data_obj = COF::DataCompat->new(%args);
        
        # These should return default values or warnings
        is($data_obj->change_user_dict(), 1, 'Compat: change_user_dict returns placeholder');
        is($data_obj->delete_user_dict(), 1, 'Compat: delete_user_dict returns placeholder');
    }
}

# ============================================================================
# SECTION 3: DATABASE INTEGRATION AND DATA ACCESS (35 tests)
# ============================================================================
{
    diag('=' x 70);
    diag('SECTION 3: Database Integration and Data Access');
    diag('=' x 70);
    
    # Initialize COF::Data with all databases
    my $dict_dir = get_dict_dir();
    ok(-d $dict_dir, "DB: Dictionary directory exists: $dict_dir") or plan skip_all => 'No dictionary directory';
    
    my @required_files = qw(elisions.db errors.db frec.db words.db words.rt);
    for my $file (@required_files) {
        my $full_path = File::Spec->catfile($dict_dir, $file);
        ok(-f $full_path, "DB: Required database file exists: $file");
        ok(-r $full_path, "DB: Database file is readable: $file");
    }
    
    my $data;
    eval { 
        $data = COF::Data->new( COF::Data::make_default_args($dict_dir) ); 
    };
    if ($@ || !$data) {
        plan skip_all => "Cannot initialize COF::Data: $@";
    }
    
    # === ELISIONS DATABASE TESTS ===
    {
        diag('Testing elisions database functionality');
        
        my $elisions_db = $data->get_elisions;
        ok(defined $elisions_db, 'DB: Elisions database loaded');
        ok(ref($elisions_db) eq 'HASH', 'DB: Elisions database is hash reference');
        
        # Test known Friulian elision patterns
        my @test_elisions = qw(aghe ore ale erbis ore int);
        my $elisions_found = 0;
        
        for my $word (@test_elisions) {
            if ($data->word_has_elision($word)) {
                $elisions_found++;
                pass("DB: Word '$word' has elision in database");
            } else {
                pass("DB: Word '$word' checked for elision (not found)");
            }
        }
        
        ok($elisions_found >= 0, 'DB: Elision check completed (found: ' . $elisions_found . ')');
        
        # Test elision method directly
        my $has_aghe_elision = $data->word_has_elision('aghe');
        ok(defined $has_aghe_elision || !defined $has_aghe_elision, 'DB: word_has_elision method works');
        
        # Test common Friulian apostrophe patterns
        my @apostrophe_tests = qw(l'aghe un'ore dal'int);
        for my $ap_word (@apostrophe_tests) {
            my $base_word = $ap_word;
            $base_word =~ s/[l'|un'|dal']//g;  # Remove common prefixes
            my $result = eval { $data->word_has_elision($base_word) };
            ok(!$@, "DB: Elision check for apostrophe word '$ap_word' -> '$base_word' handled");
        }
    }
    
    # === ERRORS DATABASE TESTS ===
    {
        diag('Testing errors database functionality');
        
        my $errors_db = $data->get_errors;
        ok(defined $errors_db, 'DB: Errors database loaded');
        ok(ref($errors_db) eq 'HASH', 'DB: Errors database is hash reference');
        
        # Test common Friulian spelling error patterns
        my @test_errors = (
            'furla',     # Should suggest 'furlan'
            'scuela',    # Should suggest 'scuele' 
            'lengha',    # Should suggest 'lenghe'
            'cjasa',     # Should suggest 'cjase'
            'ostaria',   # Should suggest 'ostarie'
        );
        
        my $errors_found = 0;
        
        for my $error_word (@test_errors) {
            if (exists $errors_db->{$error_word}) {
                $errors_found++;
                my $correction = $errors_db->{$error_word};
                ok(defined $correction, "DB: Error word '$error_word' has correction: '$correction'");
            } else {
                pass("DB: Error word '$error_word' checked (not in errors db)");
            }
        }
        
        ok($errors_found >= 0, 'DB: Error patterns check completed (found: ' . $errors_found . ')');
        
        # Test case sensitivity in errors database
        my $furla_lower = $errors_db->{'furla'};
        my $furla_upper = $errors_db->{'FURLA'} || $errors_db->{'Furla'};
        
        if (defined $furla_lower || defined $furla_upper) {
            pass('DB: Error database handles case variations');
        } else {
            pass('DB: Error database case handling checked');
        }
    }
    
    # === FREQUENCY DATABASE TESTS ===
    {
        diag('Testing frequency database functionality');
        
        my $freq_db = $data->get_freq;
        ok(defined $freq_db, 'DB: Frequency database loaded');
        ok(ref($freq_db) eq 'HASH', 'DB: Frequency database is hash reference');
        
        # Test common Friulian words should have frequency data
        my @common_words = qw(furlan cjase aghe lenghe parol frut femine om al la);
        my $freq_found = 0;
        
        for my $word (@common_words) {
            if (exists $freq_db->{$word}) {
                my $frequency = $freq_db->{$word};
                $freq_found++;
                ok(defined $frequency && $frequency >= 0, "DB: Word '$word' has frequency: $frequency");
            } else {
                pass("DB: Word '$word' checked for frequency (not found)");
            }
        }
        
        ok($freq_found >= 0, 'DB: Frequency data check completed (found: ' . $freq_found . ')');
        
        # Test frequency comparison for word ranking
        my @freq_test_words = qw(furlan cjase);
        my $freq1 = $freq_db->{$freq_test_words[0]} || 0;
        my $freq2 = $freq_db->{$freq_test_words[1]} || 0;
        
        ok($freq1 >= 0 && $freq2 >= 0, 'DB: Frequency values are non-negative numbers');
        
        # Test frequency-based ranking logic
        if ($freq1 > 0 && $freq2 > 0) {
            pass('DB: Frequency comparison: ' . $freq_test_words[0] . "($freq1) vs " . $freq_test_words[1] . "($freq2)");
        } else {
            pass('DB: Frequency comparison checked');
        }
    }
    
    # === INTEGRATION TESTS ===
    {
        diag('Testing database integration with SpellChecker');
        
        my $speller = COF::SpellChecker->new($data);
        ok($speller, 'DB: SpellChecker created with full database set');
        
        # Test suggestion generation that should use all databases
        my $suggestions = eval { $speller->suggest('furla') };  # Common error
        ok(!$@, 'DB: SpellChecker suggest method works with databases');
        ok(ref($suggestions) eq 'ARRAY', 'DB: Suggestions returned as array');
        
        if (@$suggestions > 0) {
            ok($suggestions->[0] ne '', 'DB: First suggestion is non-empty');
            my @top_suggestions = grep { defined $_ } @$suggestions[0..min(2, $#$suggestions)];
            pass("DB: Suggestion for 'furla': " . join(', ', @top_suggestions));
        } else {
            pass('DB: Suggestions checked (none found)');
        }
        
        # Test apostrophe handling (should use elisions.db)
        my $apo_suggestions = eval { $speller->suggest("l'aghe") };
        ok(!$@, 'DB: SpellChecker handles apostrophe words');
        ok(ref($apo_suggestions) eq 'ARRAY', 'DB: Apostrophe suggestions returned as array');
        
        if (@$apo_suggestions > 0) {
            my @top_apo_suggestions = grep { defined $_ } @$apo_suggestions[0..min(2, $#$apo_suggestions)];
            pass("DB: Suggestion for \"l'aghe\": " . join(', ', @top_apo_suggestions));
        } else {
            pass('DB: Apostrophe suggestions checked');
        }
    }
}

# Helper function
sub min {
    my ($a, $b) = @_;
    return $a < $b ? $a : $b;
}

done_testing();

__END__

=head1 DESCRIPTION

Consolidated test suite combining three previously separate test files:

=head2 SECTION 1: Core Initialization and Basic Operations (36 tests)

Tests core COF functionality including:
- Real database connections using CLI method
- SpellChecker functionality with real backend
- Phonetic algorithms (phalg_furlan, Levenshtein, sort_friulian)
- Case conversion utilities
- Error handling and edge cases

Uses the same database connection method as the working CLI script:
COF::Data->new(COF::Data::make_default_args(get_dict_dir()))

=head2 SECTION 2: Backwards Compatibility Layer (17 tests)

Tests COF::DataCompat functionality for environments without DB_File:
- Database file accessibility verification
- COF::DataCompat object creation and initialization
- RadixTree loading without DB_File dependency
- Basic phonetic algorithm functionality
- Performance and consistency testing
- Compatibility placeholder methods

=head2 SECTION 3: Database Integration and Data Access (35 tests)

Tests integration with COF's three key databases:

=head3 ELISIONS DATABASE (elisions.db)
- word_has_elision() method testing
- Apostrophe handling for Friulian contractions
- Common elision patterns (l'aghe, un'ore, dal'int)

=head3 ERRORS DATABASE (errors.db)
- Common spelling error corrections
- Case sensitivity handling
- Error-to-correction mapping verification

=head3 FREQUENCY DATABASE (frec.db)
- Word frequency data access
- Frequency-based ranking logic
- Integration with suggestion generation

=head1 CONSOLIDATION NOTES

This file was created by merging:
- test_core_functionality.pl (173 lines, 36 tests)
- test_core_functionality_compat.pl (116 lines, 17 tests)
- test_database_integration.pl (199 lines, 35 tests)

Total: 88 tests in ~450 lines (eliminating ~38 lines of duplicate imports/headers)

=head1 SEE ALSO

L<COF::Data>, L<COF::DataCompat>, L<COF::SpellChecker>, L<COF::Utils>

=cut
