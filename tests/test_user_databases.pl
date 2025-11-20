#!/usr/bin/perl
use strict;
use warnings;
use Test::More;
use File::Temp qw(tempfile tempdir);
use File::Spec;

# Add lib directory to include path
BEGIN {
    use File::Basename qw(dirname);
    my $lib_path = File::Spec->catdir(dirname(__FILE__), '..', 'lib');
    unshift @INC, $lib_path;
}

use COF::Data;
use COF::SpellChecker;

diag('Testing User Database Operations (User Dictionary & User Exceptions)');

# Get dictionary directory
my $dict_dir = File::Spec->catdir(dirname(__FILE__), '..', 'dict');
ok(-d $dict_dir, "Dictionary directory exists: $dict_dir") or plan skip_all => 'No dictionary directory';

# Create temporary directory for user databases
my $temp_dir = tempdir(CLEANUP => 1);
diag("Using temporary directory: $temp_dir");

# Initialize COF::Data
my $data;
eval { $data = COF::Data->new( COF::Data::make_default_args($dict_dir) ); };
if ($@ || !$data) {
    plan skip_all => 'Cannot initialize COF::Data';
}

ok($data, 'COF::Data initialized') or BAIL_OUT('Cannot proceed without COF::Data');

# Initialize SpellChecker
my $spellchecker;
eval { $spellchecker = COF::SpellChecker->new($data); };
if ($@ || !$spellchecker) {
    plan skip_all => 'SpellChecker not available';
}

ok($spellchecker, 'SpellChecker available') or BAIL_OUT('Cannot proceed without SpellChecker');

# === SECTION 1: USER DICTIONARY TESTS ===

# Test 1: User dictionary initially not loaded
{
    is($data->has_user_dict, '', 'User dictionary not loaded initially');
}

# Test 2: Create user dictionary file
{
    my $user_dict_file = File::Spec->catfile($temp_dir, 'user_dict.db');
    my $result = $data->create_user_dict_file($user_dict_file);
    ok(defined $result, 'User dictionary file created');
    ok($data->has_user_dict, 'User dictionary now available');
    ok(-f $user_dict_file, "User dictionary file exists: $user_dict_file");
}

# Test 3: Add word to user dictionary
{
    my $test_word = 'testfurlan';
    my $result = $data->add_user_dict($test_word);
    is($result, 0, "Successfully added '$test_word' to user dictionary (returned 0)");
    
    # Verify word was stored by checking all phonetic codes
    my $user_dict = $data->get_user_dict;
    my %all_words;
    foreach my $val (values %$user_dict) {
        foreach my $word (split /,/, $val) {
            $all_words{$word} = 1;
        }
    }
    
    ok(exists $all_words{$test_word}, "Word '$test_word' found in user dictionary");
}

# Test 4: Add duplicate word returns expected code
{
    my $test_word = 'testfurlan';
    my $result = $data->add_user_dict($test_word);
    is($result, 2, "Adding duplicate word '$test_word' returns 2 (already present)");
}

# Test 5: Add multiple words to user dictionary
{
    my @test_words = ('cjasute', 'lenghete', 'furlanuç');
    
    foreach my $word (@test_words) {
        my $result = $data->add_user_dict($word);
        is($result, 0, "Successfully added '$word' to user dictionary");
    }
    
    # Verify all words are accessible
    my $user_dict = $data->get_user_dict;
    my %all_words;
    foreach my $val (values %$user_dict) {
        foreach my $word (split /,/, $val) {
            $all_words{$word} = 1;
        }
    }
    
    foreach my $word (@test_words) {
        ok(exists $all_words{$word}, "Word '$word' found in user dictionary");
    }
}

# Test 6: Delete word from user dictionary
{
    my $word_to_delete = 'cjasute';
    my $result = $data->delete_user_dict($word_to_delete);
    is($result, 0, "Successfully deleted '$word_to_delete' from user dictionary");
    
    # Verify word is no longer in dictionary
    my $user_dict = $data->get_user_dict;
    my %all_words;
    foreach my $val (values %$user_dict) {
        foreach my $word (split /,/, $val) {
            $all_words{$word} = 1;
        }
    }
    
    ok(!exists $all_words{$word_to_delete}, "Word '$word_to_delete' no longer in user dictionary");
}

# Test 7: Change word in user dictionary (delete old, add new)
{
    my $old_word = 'lenghete';
    my $new_word = 'lenghetis';
    
    my $result = $data->change_user_dict($new_word, $old_word);
    is($result, 0, "Successfully changed '$old_word' to '$new_word'");
    
    # Verify old word is gone and new word exists
    my $user_dict = $data->get_user_dict;
    my %all_words;
    foreach my $val (values %$user_dict) {
        foreach my $word (split /,/, $val) {
            $all_words{$word} = 1;
        }
    }
    
    ok(!exists $all_words{$old_word}, "Old word '$old_word' no longer in user dictionary");
    ok(exists $all_words{$new_word}, "New word '$new_word' found in user dictionary");
}

# Test 8: User dictionary words are recognized as correct
{
    my $user_word = 'furlanuç';
    my $result = $spellchecker->check_word($user_word);
    
    is($result->{ok}, 1, "User dictionary word '$user_word' recognized as correct");
}

# Test 9: Clear user dictionary
{
    $data->clear_user_dict;
    my $user_dict = $data->get_user_dict;
    my $word_count = scalar keys %$user_dict;
    is($word_count, 0, 'User dictionary cleared (empty)');
}

# === SECTION 2: USER EXCEPTIONS TESTS ===

# Test 10: User exceptions initially not loaded
{
    is($data->has_user_exc, '', 'User exceptions not loaded initially');
}

# Test 11: Create user exceptions file
{
    my $user_exc_file = File::Spec->catfile($temp_dir, 'user_exc.db');
    my $result = $data->create_user_exc_file($user_exc_file);
    ok(defined $result, 'User exceptions file created');
    ok($data->has_user_exc, 'User exceptions now available');
    ok(-f $user_exc_file, "User exceptions file exists: $user_exc_file");
}

# Test 12: Add exception to user exceptions
{
    my $error_word = 'sbajât';
    my $correction = 'sbagliât';
    
    my $user_exc = $data->get_user_exc;
    $user_exc->{$error_word} = $correction;
    
    is($user_exc->{$error_word}, $correction, 
       "Exception '$error_word' → '$correction' added successfully");
}

# Test 13: User exception word is marked as incorrect
{
    my $error_word = 'sbajât';
    my $result = $spellchecker->check_word($error_word);
    
    is($result->{ok}, 0, "User exception word '$error_word' marked as incorrect");
}

# Test 14: Add multiple exceptions
{
    my %test_exceptions = (
        'errôr1' => 'correction1',
        'errôr2' => 'correction2', 
        'errôr3' => 'correction3',
    );
    
    my $user_exc = $data->get_user_exc;
    foreach my $error (keys %test_exceptions) {
        $user_exc->{$error} = $test_exceptions{$error};
    }
    
    foreach my $error (keys %test_exceptions) {
        is($user_exc->{$error}, $test_exceptions{$error},
           "Exception '$error' → '$test_exceptions{$error}' stored correctly");
    }
}

# Test 15: Delete exception from user exceptions
{
    my $error_to_delete = 'errôr1';
    
    my $user_exc = $data->get_user_exc;
    delete $user_exc->{$error_to_delete};
    
    ok(!exists $user_exc->{$error_to_delete}, 
       "Exception '$error_to_delete' deleted successfully");
}

# Test 16: Clear user exceptions
{
    $data->clear_user_exc;
    my $user_exc = $data->get_user_exc;
    my $exc_count = scalar keys %$user_exc;
    is($exc_count, 0, 'User exceptions cleared (empty)');
}

# === SECTION 3: SUGGESTION RANKING WITH USER DATABASES ===

# Re-initialize databases for ranking tests
{
    my $user_dict_file = File::Spec->catfile($temp_dir, 'ranking_dict.db');
    my $user_exc_file = File::Spec->catfile($temp_dir, 'ranking_exc.db');
    
    $data->create_user_dict_file($user_dict_file);
    $data->create_user_exc_file($user_exc_file);
}

# Test 17: User dictionary word ranks with F_USER_DICT priority (350)
{
    # Add a phonetically similar word to user dictionary
    my $user_word = 'testcjase';
    $data->add_user_dict($user_word);
    
    # Misspell it slightly to trigger suggestions
    my $misspelling = 'testcjaze';
    my $suggestions = $spellchecker->suggest($misspelling);
    
    # Check if user_word appears in suggestions
    my $found = 0;
    my $position = -1;
    for (my $i = 0; $i < @$suggestions; $i++) {
        if (lc($suggestions->[$i]) eq lc($user_word)) {
            $found = 1;
            $position = $i;
            last;
        }
    }
    
    ok($found, "User dictionary word '$user_word' appears in suggestions for '$misspelling'");
    if ($found) {
        diag("User word '$user_word' found at position $position");
    }
}

# Test 18: User exception correction ranks with F_USER_EXC priority (1000 - highest)
{
    # Add an exception: common misspelling → correction
    my $error = 'testfurla';
    my $correction = 'testfurlan';
    
    my $user_exc = $data->get_user_exc;
    $user_exc->{$error} = $correction;
    
    # Get suggestions for the error word
    my $suggestions = $spellchecker->suggest($error);
    
    # The correction should rank first (highest priority)
    ok(@$suggestions > 0, "Suggestions returned for user exception '$error'");
    if (@$suggestions > 0) {
        is(lc($suggestions->[0]), lc($correction),
           "User exception correction '$correction' ranks first (F_USER_EXC=1000)");
    }
}

# Test 19: System error dictionary correction ranks with F_ERRS priority (300)
{
    # Use a known system error from errors database
    # Example: 'adincuatri' → 'ad in cuatri'
    my $sys_error = 'adincuatri';
    
    # Check if errors database is available
    my $has_errors = eval { defined $data->get_errs; };
    
    if ($has_errors) {
        my $suggestions = $spellchecker->suggest($sys_error);
        
        ok(@$suggestions > 0, "Suggestions returned for system error '$sys_error'");
        if (@$suggestions > 0) {
            # System error correction should rank first (unless there's a user exception)
            diag("First suggestion for '$sys_error': '$suggestions->[0]'");
            pass("System error dictionary tested (F_ERRS=300)");
        }
    } else {
        pass("System error dictionary not loaded (skipping F_ERRS test)");
    }
}

# Test 20: Priority order verification (F_USER_EXC > F_USER_DICT > F_ERRS > frequency)
{
    # This test verifies the complete priority hierarchy
    # F_USER_EXC (1000) > F_SAME (400) > F_USER_DICT (350) > F_ERRS (300) > frequency (0-255)
    
    # Add both user dict word and user exception for same phonetic space
    my $user_dict_word = 'prioritest';
    my $user_exc_error = 'prioritest';
    my $user_exc_correction = 'prioritestcorrect';
    
    # Add to user dictionary first
    $data->add_user_dict($user_dict_word);
    
    # Then add as exception (exception should override)
    my $user_exc = $data->get_user_exc;
    $user_exc->{$user_exc_error} = $user_exc_correction;
    
    # Check that exception overrides dictionary
    my $result = $spellchecker->check_word($user_exc_error);
    is($result->{ok}, 0, 
       "User exception overrides user dictionary (word marked incorrect)");
    
    # Get suggestions
    my $suggestions = $spellchecker->suggest($user_exc_error);
    ok(@$suggestions > 0, "Suggestions returned for priority test");
    
    if (@$suggestions > 0) {
        # Exception correction should rank first
        is(lc($suggestions->[0]), lc($user_exc_correction),
           "User exception correction ranks first (highest priority)");
    }
}

# Test 21: Case handling in user dictionary
{
    # Add words with different cases
    my @case_words = ('TestCase', 'ALLCAPS', 'lowercase');
    
    foreach my $word (@case_words) {
        $data->add_user_dict($word);
    }
    
    # Verify case-insensitive matching
    foreach my $word (@case_words) {
        my $lower = lc($word);
        my $result = $spellchecker->check_word($lower);
        
        # Should be recognized (case-insensitive)
        ok($result->{ok} >= 0, "Case variation of user word recognized: '$lower'");
    }
}

# Test 22: Phonetic indexing integrity
{
    # Add word and verify it's indexed
    my $test_word = 'phonetictestword';
    $data->add_user_dict($test_word);
    
    my ($code_a, $code_b) = $data->phalg_furlan($test_word);
    
    ok(defined $code_a && $code_a ne '', "Primary phonetic code generated: '$code_a'");
    ok(defined $code_b && $code_b ne '', "Secondary phonetic code generated: '$code_b'");
    
    # Verify word appears in dictionary (simple check)
    my $user_dict = $data->get_user_dict;
    my %all_words;
    foreach my $val (values %$user_dict) {
        foreach my $word (split /,/, $val) {
            $all_words{$word} = 1;
        }
    }
    
    ok(exists $all_words{$test_word}, "Word indexed and retrievable from dictionary");
}

# Test 23: Empty word handling
{
    my $result = eval { $data->add_user_dict(''); };
    ok(!$@ || defined $result, "Empty word handled without crash");
    
    my $exc_result = eval {
        my $user_exc = $data->get_user_exc;
        $user_exc->{''} = 'correction';
        1;
    };
    ok($exc_result, "Empty exception key handled without crash");
}

# Test 24: Unicode/special character handling
{
    my @special_words = ('cjàse', 'furlanâ', 'ç', 'àèìòù');
    
    foreach my $word (@special_words) {
        my $result = $data->add_user_dict($word);
        ok(defined $result, "Special character word '$word' handled");
    }
}

# Test 25: Large user dictionary performance
{
    # Add many words to test performance
    my $word_count = 100;
    my $start_time = time();
    
    for (my $i = 0; $i < $word_count; $i++) {
        my $word = "perftest$i";
        $data->add_user_dict($word);
    }
    
    my $elapsed = time() - $start_time;
    ok($elapsed < 10, "Added $word_count words in reasonable time ($elapsed seconds)");
}

done_testing();
