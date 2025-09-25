#!/usr/bin/env perl
use strict;
use warnings;
use utf8;
use FindBin;
use File::Spec;
use lib File::Spec->catdir($FindBin::Bin, '..', 'lib');

use COF::Data;
use COF::Utils qw(get_dict_dir);

binmode(STDOUT, ":encoding(utf8)");

print "=== COF Database Content Investigation ===\n\n";

my $dict_dir = get_dict_dir();
my $data = COF::Data->new( COF::Data::make_default_args($dict_dir) );

# === ERRORS DATABASE INVESTIGATION ===
print "=== ERRORS DATABASE ===\n";
my $errors_db = $data->get_errors;
my @error_keys = keys %$errors_db;
print "Total entries in errors.db: " . scalar(@error_keys) . "\n";

if (@error_keys > 0) {
    print "First 20 error patterns:\n";
    for my $i (0..19) {
        last if $i >= @error_keys;
        my $key = $error_keys[$i];
        my $value = $errors_db->{$key};
        print "  '$key' -> '$value'\n";
    }
    
    # Look for specific patterns we tested
    print "\nLooking for specific test patterns:\n";
    my @test_patterns = qw(furla scuela lengha cjasa ostaria);
    for my $pattern (@test_patterns) {
        if (exists $errors_db->{$pattern}) {
            print "  FOUND: '$pattern' -> '$errors_db->{$pattern}'\n";
        } else {
            print "  NOT FOUND: '$pattern'\n";
        }
    }
}

# === ELISIONS DATABASE INVESTIGATION ===
print "\n=== ELISIONS DATABASE ===\n";
my $elisions_db = $data->get_elisions;
my @elision_keys = keys %$elisions_db;
print "Total entries in elisions.db: " . scalar(@elision_keys) . "\n";

if (@elision_keys > 0) {
    print "First 20 elision patterns:\n";
    for my $i (0..19) {
        last if $i >= @elision_keys;
        my $key = $elision_keys[$i];
        my $value = $elisions_db->{$key};
        print "  '$key' -> '$value'\n";
    }
    
    # Look for specific elision patterns
    print "\nLooking for specific elision patterns:\n";
    my @test_elisions = qw(aghe ore ale int erbis);
    for my $word (@test_elisions) {
        my $has_elision = $data->word_has_elision($word);
        if ($has_elision) {
            print "  FOUND: '$word' -> '$has_elision'\n";
        } else {
            print "  NOT FOUND: '$word'\n";
        }
    }
}

# === FREQUENCY DATABASE INVESTIGATION ===
print "\n=== FREQUENCY DATABASE ===\n";
my $freq_db = $data->get_freq;
my @freq_keys = keys %$freq_db;
print "Total entries in frec.db: " . scalar(@freq_keys) . "\n";

if (@freq_keys > 0) {
    print "Sample frequency data (first 20):\n";
    for my $i (0..19) {
        last if $i >= @freq_keys;
        my $key = $freq_keys[$i];
        my $value = $freq_db->{$key};
        print "  '$key' -> $value\n";
    }
    
    # Show highest frequency words
    print "\nTop 10 most frequent words:\n";
    my @sorted_by_freq = sort { $freq_db->{$b} <=> $freq_db->{$a} } @freq_keys;
    for my $i (0..9) {
        last if $i >= @sorted_by_freq;
        my $word = $sorted_by_freq[$i];
        my $freq = $freq_db->{$word};
        print "  $word ($freq)\n";
    }
}

print "\n=== DATABASE USAGE IN SPELLCHECKER ===\n";
use COF::SpellChecker;
my $speller = COF::SpellChecker->new($data);

# Test how errors database is used
print "Testing error correction mechanisms:\n";
my @error_tests = qw(furla scuela lengha);
for my $wrong_word (@error_tests) {
    my $suggestions = $speller->suggest($wrong_word);
    if (@$suggestions > 0) {
        print "  '$wrong_word' -> " . join(', ', @$suggestions[0..2]) . "\n";
    } else {
        print "  '$wrong_word' -> (no suggestions)\n";
    }
}

# Test how elisions work
print "\nTesting elision handling:\n";
my @elision_tests = ("l'aghe", "un'ore", "dal'int");
for my $elision_word (@elision_tests) {
    my $suggestions = $speller->suggest($elision_word);
    if (@$suggestions > 0) {
        print "  '$elision_word' -> " . join(', ', @$suggestions[0..2]) . "\n";
    } else {
        print "  '$elision_word' -> (no suggestions)\n";
    }
}

print "\n=== END INVESTIGATION ===\n";