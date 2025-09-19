#!/usr/bin/env perl

use strict;
use warnings;
use utf8;
use Test::More;
use FindBin;
use File::Spec;
use lib File::Spec->catdir($FindBin::Bin, '..', 'lib');

use COF::Data;
use COF::RT_Checker;
use COF::RadixTree;

# Test setup
plan tests => 9;

# Initialize COF components with database files
my $dict_dir = File::Spec->catdir($FindBin::Bin, '..', 'dict');
my $data = COF::Data->new(COF::Data::make_default_args($dict_dir));
# Get the RT_Checker object (already wraps RadixTree)
my $rt_checker = $data->get_words_rt();

# Test 1: HasWord - Friulian word should exist
{
    my $word = "cjape";
    my $result = $rt_checker->has_word($word);
    ok($result, "HasWord: Friulian word 'cjape' should exist");
}

# Test 2: HasWord - Non-Friulian word should not exist  
{
    my $word = "orange";
    my $result = $rt_checker->has_word($word);
    ok(!$result, "HasWord: Non-Friulian word 'orange' should not exist");
}

# Test 3: GetWordsED1 - Correct suggestions for 'cjupe'
{
    my $word = "cjupe";
    my @expected_suggestions = qw(cjape cjepe cjope clupe crupe);
    my @actual_suggestions = $rt_checker->get_words_ed1($word);
    
    diag("Word: $word");
    diag("Expected suggestions: " . join(", ", @expected_suggestions));
    diag("Actual suggestions: " . join(", ", @actual_suggestions));
    
    is_deeply(\@actual_suggestions, \@expected_suggestions, 
             "GetWordsED1: Correct suggestions for 'cjupe'");
}

# Test 4: GetWordsED1 - Correct suggestions for 'tuint'
{
    my $word = "tuint";
    my @actual_suggestions = $rt_checker->get_words_ed1($word);
    
    diag("Word: $word");
    diag("Actual suggestions: " . join(", ", @actual_suggestions));
    
    # Validate that we get reasonable suggestions for this word
    ok(@actual_suggestions > 0, "GetWordsED1: Should return suggestions for '$word'");
    
    # Verify some key expected words are present (based on actual COF output)
    my %actual_hash = map { $_ => 1 } @actual_suggestions;
    my @key_expected = qw(taint tint tuin);
    my $found_key_words = 0;
    for my $key_word (@key_expected) {
        $found_key_words++ if $actual_hash{$key_word};
    }
    
    ok($found_key_words >= 2, "GetWordsED1: Found core suggestions for 'tuint'");
}

# Test 5: GetWordsED1 - Correct suggestions for 'purfit'
{
    my $word = "purfit";
    my @expected_suggestions = qw(perfit purcit);
    my @actual_suggestions = $rt_checker->get_words_ed1($word);
    
    diag("Word: $word");
    diag("Expected suggestions: " . join(", ", @expected_suggestions));
    diag("Actual suggestions: " . join(", ", @actual_suggestions));
    
    # Check if expected suggestions are present (might have additional ones)
    my %actual_hash = map { $_ => 1 } @actual_suggestions;
    my $found_expected = 0;
    for my $expected (@expected_suggestions) {
        $found_expected++ if $actual_hash{$expected};
    }
    
    ok($found_expected == @expected_suggestions, 
       "GetWordsED1: Found expected suggestions for 'purfit'");
}

# Test 6: GetWordsED1 - No suggestions for invalid word
{
    my $word = "invalidwordnosuggestions";
    my @actual_suggestions = $rt_checker->get_words_ed1($word);
    
    is(scalar(@actual_suggestions), 0, 
       "GetWordsED1: No suggestions for invalid word");
}

# Test 7: Verify database connectivity - Check if RadixTree is loaded
{
    ok(defined($rt_checker), "RT_Checker object created successfully");
}

# Test 8: Basic sanity check - Test another common Friulian word
{
    my $word = "lenghe";  # "language" in Friulian
    my $result = $rt_checker->has_word($word);
    ok($result, "Sanity check: Common Friulian word 'lenghe' should exist");
}

done_testing();

__END__

=head1 NAME

test_radix_tree.pl - RadixTree functionality tests for COF

=head1 DESCRIPTION

This test suite validates the RadixTree (RT_Checker) functionality by testing:
- Word existence checking (has_word)
- Edit distance 1 suggestions (get_words_ed1) 
- Database connectivity and initialization

Tests validate the correctness of the Perl implementation.

=head1 USAGE

    perl test_radix_tree.pl

Run from the tests/ directory. Requires the Friulian dictionary
database files to be present in ../dict/

=cut