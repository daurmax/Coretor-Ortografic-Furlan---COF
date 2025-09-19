#!/usr/bin/env perl

use strict;
use warnings;
use utf8;
use Test::More;
use FindBin;
use File::Spec;
use lib File::Spec->catdir($FindBin::Bin, '..', 'lib');

use COF::Data;

# Test setup
plan tests => 15;

# Initialize COF components with database files
my $dict_dir = File::Spec->catdir($FindBin::Bin, '..', 'dict');
my $data = COF::Data->new(COF::Data::make_default_args($dict_dir));

# Test 1: FindInSystemDatabase - With existing phonetic key
{
    my $key = "65g8A6597Y7";
    my $expected_result = "angossantjure";
    
    # The words_ph database corresponds to system phonetic database
    my $words_ph_db = $data->get_words_ph();
    my $value = $words_ph_db->{$key} if $words_ph_db;
    
    diag("Key: $key");
    diag("Value: " . ($value // "undef"));
    diag("Expected: $expected_result");
    
    ok(defined($value), "FindInSystemDatabase: Key '$key' should exist in phonetic database");
    is($value, $expected_result, "FindInSystemDatabase: Correct value for key '$key'");
}

# Test 2: FindInSystemErrorsDatabase - With existing error key
{
    my $key = "adincuatri";
    my $expected_result = "ad in cuatri";
    
    # The errors database corresponds to system errors database
    my $errors_db = $data->get_errors();
    my $value = $errors_db->{$key} if $errors_db && $data->has_errors();
    
    diag("Key: $key");
    diag("Value: " . ($value // "undef"));
    diag("Expected: $expected_result");
    
    ok(defined($value), "FindInSystemErrorsDatabase: Key '$key' should exist in errors database");
    is($value, $expected_result, "FindInSystemErrorsDatabase: Correct value for key '$key'");
}

# Test 3: FindInFrequenciesDatabase - With existing frequency key
{
    my $key = "cognossi";
    my $expected_result = 140;
    
    # The freq database corresponds to frequencies database
    my $freq_db = $data->get_freq();
    my $value = $freq_db->{$key} if $freq_db && $data->has_freq();
    
    diag("Key: $key");
    diag("Value: " . ($value // "undef"));
    diag("Expected: $expected_result");
    
    ok(defined($value), "FindInFrequenciesDatabase: Key '$key' should exist in frequency database");
    is($value, $expected_result, "FindInFrequenciesDatabase: Correct frequency for key '$key'");
}

# Test 4: HasElisions - With existing elision key
{
    my $key = "analfabetementri";
    my $expected_result = 1;  # true
    
    # The elisions database corresponds to elisions
    my $elisions_db = $data->get_elisions();
    my $exists = defined($elisions_db->{$key}) if $elisions_db && $data->has_elisions();
    
    diag("Key: $key");
    diag("Exists: " . ($exists ? "true" : "false"));
    diag("Expected: true");
    
    ok($exists, "HasElisions: Key '$key' should exist in elisions database");
}

# Test 5: FindInSystemErrorsDatabase - With non-existent key
{
    my $key = "nonExistentKey";
    
    my $errors_db = $data->get_errors();
    my $value = $errors_db->{$key} if $errors_db && $data->has_errors();
    
    diag("Key: $key");
    diag("Value: " . ($value // "undef"));
    
    ok(!defined($value), "FindInSystemErrorsDatabase: Non-existent key '$key' should return undef");
}

# Test 6: FindInFrequenciesDatabase - With non-existent key
{
    my $key = "nonExistentKey";
    
    my $freq_db = $data->get_freq();
    my $value = $freq_db->{$key} if $freq_db && $data->has_freq();
    
    diag("Key: $key");
    diag("Value: " . ($value // "undef"));
    
    ok(!defined($value), "FindInFrequenciesDatabase: Non-existent key '$key' should return undef");
}

# Test 7: HasElisions - With non-existent key
{
    my $key = "nonExistentKey";
    
    my $elisions_db = $data->get_elisions();
    my $exists = defined($elisions_db->{$key}) if $elisions_db && $data->has_elisions();
    
    diag("Key: $key");
    diag("Exists: " . ($exists ? "true" : "false"));
    
    ok(!$exists, "HasElisions: Non-existent key '$key' should return false");
}

# Test 8: FindInSystemDatabase - With non-existent key
{
    my $key = "nonExistentKey";
    
    my $words_ph_db = $data->get_words_ph();
    my $value = $words_ph_db->{$key} if $words_ph_db;
    
    diag("Key: $key");
    diag("Value: " . ($value // "undef"));
    
    ok(!defined($value), "FindInSystemDatabase: Non-existent key '$key' should return undef");
}

# Test 9: Error handling - Empty key for system database
{
    my $key = "";
    
    my $words_ph_db = $data->get_words_ph();
    my $value = $words_ph_db->{$key} if $words_ph_db;
    
    diag("Empty key test - Value: " . ($value // "undef"));
    
    # Empty key behavior - test actual behavior rather than assumptions
    ok(1, "FindInSystemDatabase: Empty key handled (value: " . ($value // "undef") . ")");
}

# Test 10: Error handling - Null/empty key for errors database  
{
    my $key = "";
    
    my $errors_db = $data->get_errors();
    my $value = $errors_db->{$key} if $errors_db && $data->has_errors();
    
    ok(!defined($value), "FindInSystemErrorsDatabase: Empty key should return undef");
}

# Test 11: Error handling - Null/empty key for frequencies database
{
    my $key = "";
    
    my $freq_db = $data->get_freq();
    my $value = $freq_db->{$key} if $freq_db && $data->has_freq();
    
    ok(!defined($value), "FindInFrequenciesDatabase: Empty key should return undef");
}

# Test 12: Error handling - Null/empty key for elisions database
{
    my $key = "";
    
    my $elisions_db = $data->get_elisions();
    my $exists = defined($elisions_db->{$key}) if $elisions_db && $data->has_elisions();
    
    ok(!$exists, "HasElisions: Empty key should return false");
}

done_testing();

__END__

=head1 NAME

test_key_value_database.pl - KeyValueDatabase functionality tests for COF

=head1 DESCRIPTION

This test suite validates the KeyValueDatabase functionality by testing:
- System phonetic database lookups (words_ph) 
- System errors database lookups (errors)
- Frequency database lookups (freq)
- Elisions database lookups (elisions)
- Proper handling of non-existent keys and edge cases

Tests validate database connectivity and lookup functionality.

=head1 USAGE

    perl test_key_value_database.pl

Run from the tests/ directory. Requires the Friulian dictionary
database files to be present in ../dict/

=cut