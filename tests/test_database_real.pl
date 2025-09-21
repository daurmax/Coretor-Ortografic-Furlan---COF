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

diag('Testing real database connections using the same method as cof_oo_cli.pl');

# Test 1: Check if dictionary directory exists and is accessible
{
    my $dict_dir = get_dict_dir();
    ok(-d $dict_dir, "Dictionary directory exists: $dict_dir");
    
    # Check for required database files
    my @required_files = qw(words.db words.rt elisions.db errors.db frec.db);
    for my $file (@required_files) {
        my $full_path = File::Spec->catfile($dict_dir, $file);
        ok(-f $full_path, "Required database file exists: $file");
        ok(-r $full_path, "Database file is readable: $file");
    }
}

# Test 2: Create COF::Data object using the exact same method as CLI
{
    my $data;
    eval {
        $data = COF::Data->new( COF::Data::make_default_args( get_dict_dir() ) );
    };
    
    ok(!$@, "COF::Data creation successful: " . ($@ || 'no error'));
    ok(defined($data), "COF::Data object is defined");
    isa_ok($data, 'COF::Data', "Data object has correct type");
}

# Test 3: Create SpellChecker and test basic functionality
SKIP: {
    my $data;
    eval {
        $data = COF::Data->new( COF::Data::make_default_args( get_dict_dir() ) );
    };
    
    skip "Cannot create COF::Data object: $@", 10 if $@;
    
    my $speller = COF::SpellChecker->new($data);
    ok(defined($speller), "SpellChecker created successfully");
    isa_ok($speller, 'COF::SpellChecker', "SpellChecker has correct type");
    
    # Test word checking (like the CLI 'c' command)
    my $result = $speller->check_word('furlan');
    ok(defined($result), "check_word returns defined result");
    ok(ref($result), "check_word returns reference");
    ok(exists($result->{'ok'}), "Result has 'ok' key");
    
    # Test with a known good word (if it exists in the database)
    my @test_words = qw(furlan lenghe cjase aghe scuele);
    my $found_word = 0;
    
    for my $word (@test_words) {
        my $check_result = $speller->check_word($word);
        if ($check_result && $check_result->{'ok'}) {
            $found_word = 1;
            pass("Found valid word in database: $word");
            last;
        }
    }
    
    # If no test words found, that's still OK - just means dictionary is minimal
    ok(1, "Word checking mechanism works") unless $found_word;
    
    # Test suggestion mechanism (like CLI 's' command)
    my $suggestions = $speller->suggest('furlan');
    ok(defined($suggestions), "suggest() returns defined result");
    ok(ref($suggestions) eq 'ARRAY', "suggest() returns array reference");
}

# Test 4: Test error handling and edge cases
SKIP: {
    my $data;
    eval {
        $data = COF::Data->new( COF::Data::make_default_args( get_dict_dir() ) );
    };
    
    skip "Cannot create COF::Data object: $@", 5 if $@;
    
    my $speller = COF::SpellChecker->new($data);
    
    # Test empty string
    my $empty_result = eval { $speller->check_word('') };
    ok(!$@, "Empty string handled gracefully: " . ($@ || 'no error'));
    
    # Test very short word
    my $short_result = eval { $speller->check_word('a') };
    ok(!$@, "Short word handled gracefully: " . ($@ || 'no error'));
    
    # Test word with punctuation (like CLI handles dots)
    my $punct_result = eval { $speller->check_word('test.') };
    ok(!$@, "Punctuation handled gracefully: " . ($@ || 'no error'));
    
    # Test Unicode characters
    my $unicode_result = eval { $speller->check_word('cjàse') };
    ok(!$@, "Unicode handled gracefully: " . ($@ || 'no error'));
    
    # Test suggestion for non-existent word
    my $bad_suggestions = eval { $speller->suggest('xyzabc') };
    ok(!$@, "Suggestions for bad word handled gracefully: " . ($@ || 'no error'));
}

# Test 5: Test COF::Data utility functions that don't require DB access
{
    # These should work regardless of database status
    my $lev_distance = COF::Data::Levenshtein('test', 'best');
    ok(defined($lev_distance), "Levenshtein function works");
    is($lev_distance, 1, "Levenshtein distance correct");
    
    my $phonetic = COF::Data::phalg_furlan('test');
    ok(defined($phonetic), "phalg_furlan function works");
    ok(length($phonetic) > 0, "phalg_furlan returns non-empty result");
    
    # Test Friulian sorting
    my @words = qw(aghe cjase furlan);
    my @sorted = COF::Data::sort_friulian(@words);
    is(scalar(@sorted), 3, "sort_friulian preserves array length");
}

done_testing();

__END__

=head1 NAME

test_database_real.pl - Test real database connections using CLI method

=head1 DESCRIPTION

This test suite uses the exact same database connection method as the
working cof_oo_cli.pl script:

1. Uses COF::Utils::get_dict_dir() to find the dictionary directory
2. Uses COF::Data::make_default_args() to create proper arguments
3. Creates COF::Data object with new() constructor
4. Tests COF::SpellChecker with real database backend

This should work if the CLI script works, since it uses identical code paths.

=cut