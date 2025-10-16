#!/usr/bin/perl
use strict;
use warnings;
use utf8;
use FindBin;
use File::Spec;

=head1 NAME

run_all_tests.pl - Unified COF test suite runner

=head1 DESCRIPTION

Runs every test file in this directory. This is the ONLY entrypoint
to execute the full test suite. No test runners are kept in `util/`.

Test Suite Structure:
- Core & Database: Core functionality, compatibility layer, database integration (129 tests)
- WordIterator: Tokenization, Unicode handling, edge cases
- Suggestions & Components: Component integration and suggestion algorithm (50 tests)
- RadixTree: RT structure, lookup, suggestions, performance
- Suggestion Ranking: Exact suggestion order validation with multi-factor ranking (50 tests)
- Utilities: Encoding, CLI validation, legacy data
- Phonetic Algorithm: phalg_furlan correctness and comprehensive validation

=head1 USAGE

From project root or from this directory:

  perl tests/run_all_tests.pl
  # or
  cd tests && perl run_all_tests.pl

Returns exit code 0 if all suites pass, 1 otherwise.

=cut

my @test_suites = (
    { file => 'test_core.pl',                      name => 'Core & Database',          desc => 'Core functionality, compatibility, database integration (88 tests + 41 file checks = 129 total)' },
    { file => 'test_worditerator.pl',              name => 'WordIterator',             desc => 'Iterator logic, Unicode, edge cases' },
    { file => 'test_suggestions.pl',               name => 'Suggestions & Components', desc => 'Component integration + suggestion algorithm (50 tests: 23 components + 27 suggestions)' },
    { file => 'test_radix_tree.pl',                name => 'RadixTree',                desc => 'RadixTree functionality, suggestions, performance' },
    { file => 'test_suggestion_ranking.pl',        name => 'Suggestion Ranking',       desc => 'Exact suggestion order validation with multi-factor ranking (51 tests)' },
    { file => 'test_utilities.pl',                 name => 'Utilities',                desc => 'Encoding, CLI validation, legacy data' },
    { file => 'test_phonetic_algorithm.pl',        name => 'Phonetic Algorithm',       desc => 'Comprehensive phonetic algorithm validation' },
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
