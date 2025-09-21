#!/usr/bin/env perl

use strict;
use warnings;
use utf8;
use Test::More;
use FindBin;
use File::Spec;
use lib File::Spec->catdir($FindBin::Bin, '..', 'lib');

BEGIN {
    # If DB_File (XS) is missing, skip the entire test file gracefully.
    eval { require DB_File; 1 } or do {
        require Test::More;
        Test::More::plan(skip_all => 'DB_File not available; skipping SpellChecker tests');
    };
}
use COF::Data;
use COF::SpellChecker;

# Test setup
plan tests => 5;

# Initialize COF components with database files
my $dict_dir = File::Spec->catdir($FindBin::Bin, '..', 'dict');
my $data = COF::Data->new(COF::Data::make_default_args($dict_dir));
my $spell_checker = COF::SpellChecker->new($data);

# Test 1: CheckWord - Correct Friulian word should return true
{
    my $word = "cjape";
    my $result = $spell_checker->check_word($word);
    ok($result->ok, "CheckWord: Correct Friulian word 'cjape' should return true");
}

# Test 2: CheckWord - Incorrect word should return false
{
    my $word = "xyzzylanguagenotfriulian";  # Obviously non-Friulian word
    my $result = $spell_checker->check_word($word);
    ok(!$result->ok, "CheckWord: Incorrect word '$word' should return false");
}

# Test 3: GetWordSuggestions - Invalid word with suggestions should return suggestions
{
    my $word = "cjupe";
    my $suggestions_ref = $spell_checker->suggest($word);
    my @actual_suggestions = $suggestions_ref ? @$suggestions_ref : ();
    
    # Expected suggestions extracted from actual COF behavior
    my @expected_suggestions = qw(cjape cope copi sope supe copii cjepe supi zupe copiii cjope clupe crupe çope zupi çopi supii zupii çopii);
    
    diag("Word: $word");
    diag("Expected suggestions: " . join(", ", @expected_suggestions));
    diag("Actual suggestions: " . join(", ", @actual_suggestions));
    
    # Check that we get exactly the expected number of suggestions
    is(scalar(@actual_suggestions), scalar(@expected_suggestions), "GetWordSuggestions: Correct number of suggestions for 'cjupe'");
    
    # Check that all expected suggestions are present in correct order
    is_deeply(\@actual_suggestions, \@expected_suggestions, "GetWordSuggestions: All expected suggestions present for 'cjupe' in correct order");
}

# Test 4: GetWordSuggestions - Invalid word with no suggestions should return empty
{
    my $word = "invalidwordnosuggestions";
    my $suggestions_ref = $spell_checker->suggest($word);
    my @suggestions = $suggestions_ref ? @$suggestions_ref : ();
    
    is(scalar(@suggestions), 0, 
       "GetWordSuggestions: Invalid word with no suggestions should return empty array");
}

done_testing();

__END__

=head1 NAME

test_spell_checker.pl - SpellChecker functionality tests for COF

=head1 DESCRIPTION

This test suite validates the SpellChecker functionality by testing:
- Word correctness checking (check_word)
- Word suggestion generation (suggest)
- Database connectivity and spell checking logic

Tests validate the correctness of the Perl implementation.

=head1 USAGE

    perl test_spell_checker.pl

Run from the tests/ directory. Requires the Friulian dictionary
database files to be present in ../dict/

=cut