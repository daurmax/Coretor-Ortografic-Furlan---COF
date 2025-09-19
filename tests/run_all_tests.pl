#!/usr/bin/env perl

use strict;
use warnings;
use utf8;

=head1 NAME

run_all_tests.pl - Comprehensive test runner for COF test suite

=head1 DESCRIPTION

This script runs comprehensive test suites for COF:
- RadixTree functionality tests (test_radix_tree.pl)
- SpellChecker functionality tests (test_spell_checker.pl)  
- KeyValueDatabase functionality tests (test_key_value_database.pl)

Total test coverage: 76 tests validating complete COF functionality.

=head1 USAGE

    perl run_all_tests.pl

Run from the tests/ directory. Requires the Friulian dictionary
database files to be present in ../dict/

=cut

use FindBin;
use File::Spec;

# Change to test directory
chdir $FindBin::Bin;

print "=" x 60, "\n";
print "COF COMPREHENSIVE TEST SUITE\n";
print "Complete validation framework for COF functionality\n"; 
print "=" x 60, "\n\n";

my @test_files = (
    {
        file => 'test_radix_tree.pl',
        name => 'RadixTree (RT_Checker) Tests',
        description => 'Word existence and edit-distance suggestions'
    },
    {
        file => 'test_spell_checker.pl', 
        name => 'SpellChecker Tests',
        description => 'Word validation and spelling suggestions'
    },
    {
        file => 'test_key_value_database.pl',
        name => 'KeyValueDatabase Tests',
        description => 'Database lookups for phonetics, errors, frequencies, elisions'
    },
    {
        file => 'test_phonetic_perl.pl',
        name => 'Phonetic Algorithm Tests',
        description => 'Phonetic hash algorithm validation (phalg_furlan)'
    }
);

my $total_passed = 0;
my $total_failed = 0;
my $all_passed = 1;

for my $test (@test_files) {
    print "-" x 50, "\n";
    print "Running: $test->{name}\n";
    print "Description: $test->{description}\n";
    print "-" x 50, "\n";
    
    my $result = system("perl", $test->{file});
    my $exit_code = $result >> 8;
    
    if ($exit_code == 0) {
        print "[PASS] $test->{name}\n\n";
        $total_passed++;
    } else {
        print "[FAIL] $test->{name} (exit code: $exit_code)\n\n";
        $total_failed++;
        $all_passed = 0;
    }
}

print "=" x 60, "\n";
print "TEST SUITE SUMMARY\n";
print "=" x 60, "\n";
print "Total test suites: " . (@test_files) . "\n";
print "Passed: $total_passed\n";
print "Failed: $total_failed\n";

if ($all_passed) {
    print "\nALL TESTS PASSED! COF implementation validated successfully.\n";
    print "Perl implementation working correctly.\n";
    exit 0;
} else {
    print "\nSOME TESTS FAILED. Check output above for details.\n";
    exit 1;
}

__END__