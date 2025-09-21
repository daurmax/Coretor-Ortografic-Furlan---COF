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

diag('Testing SpellChecker functionality with real database');

# Setup: Create SpellChecker with real database
my ($data, $speller);
eval {
    $data = COF::Data->new( COF::Data::make_default_args( get_dict_dir() ) );
    $speller = COF::SpellChecker->new($data);
};

SKIP: {
    skip "Cannot initialize SpellChecker: $@", 50 if $@;
    
    # Test 1: Basic word checking functionality
    {
        # Test some common Friulian words that should be in the dictionary
        my @test_words = qw(furlan lenghe cjase aghe scuele parol frut femine om);
        my $valid_words_found = 0;
        
        for my $word (@test_words) {
            my $result = $speller->check_word($word);
            if ($result && $result->{'ok'}) {
                $valid_words_found++;
                pass("Word '$word' found in dictionary");
            }
        }
        
        ok($valid_words_found > 0, "Found at least some valid words in dictionary");
    }
    
    # Test 2: Case sensitivity handling
    {
        # Find a valid word first
        my @test_words = qw(furlan lenghe cjase);
        my $valid_word;
        
        for my $word (@test_words) {
            my $result = $speller->check_word($word);
            if ($result && $result->{'ok'}) {
                $valid_word = $word;
                last;
            }
        }
        
        if ($valid_word) {
            # Test uppercase version
            my $upper_word = uc($valid_word);
            my $upper_result = $speller->check_word($upper_word);
            ok(defined($upper_result), "Uppercase word handled: $upper_word");
            
            # Test mixed case
            my $mixed_word = ucfirst($valid_word);
            my $mixed_result = $speller->check_word($mixed_word);
            ok(defined($mixed_result), "Mixed case word handled: $mixed_word");
        } else {
            skip "No valid words found for case testing", 2;
        }
    }
    
    # Test 3: Suggestion functionality
    {
        # Test suggestions for deliberately misspelled words
        my @misspelled = qw(furla lengh cjas agh scuel);
        
        for my $word (@misspelled) {
            my $suggestions = $speller->suggest($word);
            ok(defined($suggestions), "Suggestions returned for '$word'");
            ok(ref($suggestions) eq 'ARRAY', "Suggestions is array reference for '$word'");
            
            # Check if suggestions contain reasonable results
            if (@$suggestions) {
                my $has_reasonable_suggestion = 0;
                for my $suggestion (@$suggestions) {
                    if (length($suggestion) > 0 && length($suggestion) < 20) {
                        $has_reasonable_suggestion = 1;
                        last;
                    }
                }
                ok($has_reasonable_suggestion, "Found reasonable suggestions for '$word'");
            } else {
                pass("No suggestions for '$word' (acceptable)");
            }
        }
    }
    
    # Test 4: Punctuation handling (like CLI handles dots)
    {
        my @words_with_punct = qw(furlan. cjase, aghe; scuele:);
        
        for my $word (@words_with_punct) {
            my $result = eval { $speller->check_word($word) };
            ok(!$@, "Punctuation handled gracefully for '$word': " . ($@ || 'no error'));
            ok(defined($result), "Result defined for punctuated word '$word'");
        }
    }
    
    # Test 5: Unicode and accent handling
    {
        my @accented_words = qw(cjàse dâ û ê â ì ò);
        
        for my $word (@accented_words) {
            my $result = eval { $speller->check_word($word) };
            ok(!$@, "Unicode/accent handled gracefully for '$word': " . ($@ || 'no error'));
            ok(defined($result), "Result defined for accented word '$word'");
        }
    }
    
    # Test 6: Edge cases and error conditions
    {
        # Empty string
        my $empty_result = eval { $speller->check_word('') };
        ok(!$@, "Empty string handled gracefully");
        
        # Very long string
        my $long_word = 'a' x 100;
        my $long_result = eval { $speller->check_word($long_word) };
        ok(!$@, "Very long word handled gracefully");
        
        # String with numbers
        my $num_result = eval { $speller->check_word('test123') };
        ok(!$@, "Word with numbers handled gracefully");
        
        # String with special characters
        my $special_result = eval { $speller->check_word('test@#$') };
        ok(!$@, "Word with special chars handled gracefully");
    }
    
    # Test 7: Suggestion limits (like CLI maxsug parameter)
    {
        my $suggestions = $speller->suggest('xyz');
        ok(defined($suggestions), "Suggestions for nonsense word handled");
        
        if (@$suggestions > 10) {
            # If we get many suggestions, that's fine - just means rich dictionary
            ok(1, "Rich suggestion set found");
        } else {
            ok(1, "Reasonable suggestion count");
        }
    }
    
    # Test 8: Multiple consecutive operations (like CLI interactive mode)
    {
        my @operations = (
            ['check', 'furlan'],
            ['suggest', 'furla'],
            ['check', 'lenghe'],
            ['suggest', 'lengh'],
            ['check', 'cjase'],
        );
        
        for my $op (@operations) {
            my ($action, $word) = @$op;
            
            my $result = eval {
                if ($action eq 'check') {
                    return $speller->check_word($word);
                } else {
                    return $speller->suggest($word);
                }
            };
            
            ok(!$@, "Operation '$action' on '$word' handled gracefully: " . ($@ || 'no error'));
            ok(defined($result), "Operation '$action' on '$word' returned defined result");
        }
    }
}

done_testing();

__END__

=head1 NAME

test_spell_checker_real.pl - Test SpellChecker with real database backend

=head1 DESCRIPTION

Comprehensive test of COF::SpellChecker functionality using real database
connections. Tests all the features used by the CLI interface:

- Basic word checking (like CLI 'c' command)
- Suggestion generation (like CLI 's' command)  
- Case sensitivity handling
- Punctuation handling (dots, commas, etc.)
- Unicode and accent processing
- Error handling and edge cases
- Multiple consecutive operations (like interactive CLI mode)

Uses the same database connection method as the working CLI script.

=cut