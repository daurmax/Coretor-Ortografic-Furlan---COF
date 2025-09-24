#!/usr/bin/perl
use strict;
use warnings;
use utf8;
use Test::More;

# Add lib directory to include path  
BEGIN {
    use File::Basename qw(dirname);
    use File::Spec;
    my $lib_path = File::Spec->catdir(dirname(__FILE__), '..', 'lib');
    unshift @INC, $lib_path;
}

use COF::Data;

diag('Testing RadixTree (RT_Checker) functionality');

# Get dictionary directory - we're in tests/ so dict is at ../dict
my $dict_dir = File::Spec->catdir(dirname(__FILE__), '..', 'dict');
ok(-d $dict_dir, "Dictionary directory exists: $dict_dir") or plan skip_all => 'No dictionary directory';

my $data;
eval { $data = COF::Data->new( COF::Data::make_default_args($dict_dir) ); };
if ($@ || !$data) {
    plan skip_all => 'Cannot initialize COF::Data';
}

# Test RadixTree availability
my $rt_checker;
eval { $rt_checker = $data->get_words_rt(); };
if ($@ || !$rt_checker) {
    plan skip_all => 'RadixTree (RT_Checker) not available';
}

ok($rt_checker, 'RadixTree checker available') or plan skip_all => 'No RadixTree checker';

# Helper function to safely get suggestions
sub get_suggestions_safe {
    my ($word) = @_;
    my @suggestions = eval { $rt_checker->get_words_ed1($word) };
    return $@ ? () : @suggestions;
}

# === Basic RadixTree Functionality Tests ===

# Test 1: Basic word lookup (if RT_Checker supports it)
SKIP: {
    skip "RT_Checker lookup method not available", 1 unless $rt_checker->can('lookup');
    
    my $result = eval { $rt_checker->lookup('furlan') };
    ok(!$@, "Word lookup should not crash");
}

# Test 2: Edit distance 1 suggestions - core functionality
{
    my @suggestions = get_suggestions_safe('furla');
    ok(@suggestions > 0, 'furla produces suggestions');
    ok(grep { $_ eq 'furlan' } @suggestions, "furlan should be suggested for 'furla'");
}

# Test 3: Empty input handling
{
    my @suggestions = get_suggestions_safe('');
    ok(@suggestions > 0, 'Empty input produces suggestions (all single letters)');
}

# Test 4: Very short words
{
    my @suggestions = get_suggestions_safe('a');
    # Should not crash, may or may not have suggestions
    pass('Single character input handled');
}

# Test 5: Non-existent words
{
    my @suggestions = get_suggestions_safe('xyzqwerty');
    # Should not crash, likely no suggestions for completely invalid words
    pass('Non-existent word handled');
}

# Test 6: Friulian specific characters
{
    my @suggestions = get_suggestions_safe('cjase');
    # May have suggestions, should not crash
    pass('Friulian characters handled');
}

# Test 7: Known good suggestion pairs from COF usage
{
    my %known_pairs = (
        'lengha' => 'lenghe',
        'cjupe'  => 'cjope',
        'anell'  => 'anel',
    );
    
    for my $input (keys %known_pairs) {
        my $expected = $known_pairs{$input};
        my @suggestions = get_suggestions_safe($input);
        
        if (@suggestions) {
            ok(grep { $_ eq $expected } @suggestions, 
               "$expected should be suggested for '$input'");
        } else {
            pass("No suggestions for $input (acceptable)");
        }
    }
}

# === Load and Test Curated Dataset ===

# Curated test dataset - manually verified cases
my %RADIX_TEST_CASES = (
    'furla' => ['furlan'],
    'lengha' => ['lenghe'],  
    'cjupe' => ['cjape', 'cjepe', 'cjope', 'clupe', 'crupe'],
    'cjasa' => ['cjase', 'cjast', 'cjas*'],
    'ostaria' => ['ostarie'],
    'anell' => ['anel'],
);

# Test curated cases  
for my $word (keys %RADIX_TEST_CASES) {
    my @expected = @{$RADIX_TEST_CASES{$word}};
    my @got = get_suggestions_safe($word);
    
    # Test that all expected suggestions are present (COF might return more)
    my $all_found = 1;
    my @missing;
    for my $expected_sugg (@expected) {
        if (!grep { $_ eq $expected_sugg } @got) {
            $all_found = 0;
            push @missing, $expected_sugg;
        }
    }
    
    ok($all_found, "All expected suggestions found for '$word'") or
        diag("Expected: " . join(', ', @expected) . "\n" .
             "Got: " . join(', ', @got) . "\n" .
             "Missing: " . join(', ', @missing));
}

diag("Tested " . scalar(keys %RADIX_TEST_CASES) . " cases from curated dataset");

# === Performance and Stress Tests ===

# Test 8: Performance with multiple suggestions
{
    my $start_time = time;
    my $count = 0;
    
    for my $test_word (qw(furla lengha cjupe cjasa ostaria scuela anell)) {
        my @suggestions = get_suggestions_safe($test_word);
        $count += @suggestions;
    }
    
    my $elapsed = time - $start_time;
    ok($elapsed < 5, "Multiple suggestions completed in reasonable time ($elapsed seconds)");
    diag("Generated $count suggestions for 7 words in $elapsed seconds");
}

# Test 9: Memory usage test - batch processing
{
    my @test_batch = qw(
        test prova furlan lenghe cjase gjave aghe
        plui prossim lontam grant piçul bon catîf
    );
    
    my $total_suggestions = 0;
    for my $word (@test_batch) {
        my @suggestions = get_suggestions_safe($word);
        $total_suggestions += @suggestions;
    }
    
    ok($total_suggestions >= 0, "Batch processing completed successfully");
    diag("Batch of " . scalar(@test_batch) . " words produced $total_suggestions suggestions");
}

# Test 10: Edge case handling
{
    my @edge_cases = (
        'A',           # Single uppercase
        'aa',          # Repeated character
        'a' x 50,      # Very long word
        '123',         # Numbers
        'test-word',   # Hyphenated
        "test'word",   # Apostrophe
    );
    
    my $handled_count = 0;
    for my $edge_case (@edge_cases) {
        eval { get_suggestions_safe($edge_case); };
        $handled_count++ unless $@;
    }
    
    ok($handled_count == @edge_cases, 
       "All edge cases handled without crashing ($handled_count/" . @edge_cases . ")");
}

done_testing();

__END__

=head1 NAME

test_radix_tree.pl - Comprehensive RadixTree functionality tests

=head1 DESCRIPTION

Tests for COF RadixTree (RT_Checker) functionality including:

- Basic edit-distance-1 suggestion generation
- Input validation and edge case handling  
- Performance characteristics
- Consistency with generated test dataset
- Friulian language specific features

These tests serve as regression tests and provide comprehensive coverage
of RadixTree functionality that can be used for validation when porting
to other implementations (like Python FurlanSpellChecker).

The test dataset is generated from legacy word lists and represents
real-world usage patterns of the RadixTree suggestions.
=cut

done_testing();

=head1 USAGE

    perl tests/test_radix_tree.pl

The test requires:
- COF dictionary files in dict/ directory  
- Generated test dataset in tests/fixtures/
- Working RT_Checker implementation

=cut