#!/usr/bin/perl
use strict;
use warnings;
use utf8;
use FindBin;
use File::Spec;

=head1 NAME

run_all_tests.pl - Unified COF test suite runner

=head1 DESCRIPTION

Runs every consolidated test file in this directory. This is the ONLY entrypoint
to execute the full test suite. No test runners are kept in `util/`.

Included suites:
- WordIterator (tokenization + Unicode + edge cases)
- Core Functionality (Database, SpellChecker, phonetic algorithms)
- Components (FastChecker and RTChecker components)
- RadixTree (RT structure + lookup + suggestions + performance)
- Utilities (Encoding, CLI validation, legacy data)
- Phonetic Algorithm (phalg_furlan correctness + comprehensive validation)

=head1 USAGE

From project root or from this directory:

  perl tests/run_all_tests.pl
  # or
  cd tests && perl run_all_tests.pl

Returns exit code 0 if all suites pass, 1 otherwise.

=cut

my @test_suites = (
    { file => 'test_worditerator.pl',           name => 'WordIterator',        desc => 'Iterator logic, Unicode, edge cases' },
    { file => 'test_core_functionality.pl',     name => 'Core Functionality',  desc => 'Database, SpellChecker, phonetic algorithms' },
    { file => 'test_components.pl',             name => 'Components',          desc => 'FastChecker and RTChecker components' },
    { file => 'test_radix_tree.pl',             name => 'RadixTree',           desc => 'RadixTree functionality, suggestions, performance' },
    { file => 'test_utilities.pl',              name => 'Utilities',           desc => 'Encoding, CLI validation, legacy data' },
    { file => 'test_phonetic_algorithm.pl',     name => 'Phonetic Algorithm',  desc => 'Comprehensive phonetic algorithm validation' },
);

# Ensure we are in the tests directory so relative paths resolve
my $script_dir = $FindBin::Bin; # directory of this script
chdir $script_dir or die "Cannot chdir to tests directory ($script_dir): $!";

print "=" x 70, "\n";
print "COF TEST SUITE RUNNER\n";
print "Unified execution of all consolidated test suites\n";
print "=" x 70, "\n\n";

my $total = scalar @test_suites;
my $passed = 0;
my $failed = 0;
my @failed;

for my $suite (@test_suites) {
    my ($file,$name,$desc) = @$suite{qw/file name desc/};
    print '-' x 60, "\n";
    print "Running: $name\n";
    print "File: $file\n";
    print "Description: $desc\n";
    print '-' x 60, "\n";

    if (!-f $file) {
        print "[MISSING] $file not found\n\n";
        $failed++;
        push @failed, $name;
        next;
    }

    my $exit = system($^X, $file); # use same perl
    $exit = $exit >> 8;
    if ($exit == 0) {
        print "[PASS] $name\n\n";
        $passed++;
    } else {
        print "[FAIL] $name (exit=$exit)\n\n";
        $failed++;
        push @failed, $name;
    }
}

print "=" x 70, "\n";
print "SUMMARY\n";
print "=" x 70, "\n";
print "Suites total: $total\n";
print "Passed      : $passed\n";
print "Failed      : $failed\n";

if ($failed) {
    print "Failed suites:\n";
    print "  - $_\n" for @failed;
    print "\nRESULT: SOME FAILURES\n";
    exit 1;
} else {
    print "\nRESULT: ALL PASSED ✔\n";
    exit 0;
}

__END__

=head1 NOTES

Keep any additional helper or experimental runner scripts OUTSIDE this directory
or clearly named so as not to confuse the canonical entrypoint. Avoid duplicating
logic that lives here.

=cut
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

Total test coverage: 138+ tests validating complete COF functionality including:
- Core functionality (76 original tests)
- Database robustness (8 tests)
- Encoding corruption handling (20 tests) 
- CLI parameter validation (22 tests)
- WordIterator simplified (8 tests)
- RT_Checker robustness (8 tests)
- FastChecker simplified (6 tests)

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
    # Core functionality tests (existing)
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
    },
    
    # High priority robustness tests (new)
    {
        file => 'test_database_simplified.pl',
        name => 'Database Robustness Tests',
        description => 'DB_File handling, corruption detection, UTF-8 support'
    },
    {
        file => 'test_encoding_corruption.pl',
        name => 'Encoding Corruption Tests',
        description => 'UTF-8/ISO-8859-1 conversion failures, invalid sequences'
    },
    {
        file => 'test_cli_parameter_validation.pl',
        name => 'CLI Parameter Validation Tests',
        description => 'CLI utilities error handling, invalid parameters, file I/O'
    },
    
    # Medium priority edge case tests (new)
    {
        file => 'test_worditerator_simplified.pl',
        name => 'WordIterator Simplified Tests',
        description => 'Basic functionality and edge case handling'
    },
    {
        file => 'test_rtchecker_simplified.pl',
        name => 'RT_Checker Robustness Tests',
        description => 'Performance, consistency, boundary conditions'
    },
    
    # Low priority state consistency tests (new)
    {
        file => 'test_fastchecker_simplified.pl',
        name => 'FastChecker Simplified Tests',
        description => 'Basic state structure and data handling'
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