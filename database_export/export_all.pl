#!/usr/bin/env perl
use strict;
use warnings;
use utf8;

binmode STDOUT, ":utf8";

print "=" x 60 . "\n";
print "COF Database Export Suite\n";
print "=" x 60 . "\n\n";

print "This script exports all COF databases to JSON format\n";
print "for conversion to msgpack in FurlanSpellChecker.\n\n";

my @scripts = (
    'export_words.pl',
    'export_frequencies.pl',
    'export_errors.pl',
    'export_elisions.pl'
);

my $success = 0;
my $failed = 0;

foreach my $script (@scripts) {
    print "\n" . "=" x 60 . "\n";
    print "Running: $script\n";
    print "=" x 60 . "\n";
    
    my $result = system("perl $script");
    
    if ($result == 0) {
        print "\n✅ $script completed successfully\n";
        $success++;
    } else {
        print "\n❌ $script failed with exit code: $result\n";
        $failed++;
    }
}

print "\n" . "=" x 60 . "\n";
print "EXPORT SUMMARY\n";
print "=" x 60 . "\n";
print "Successful: $success\n";
print "Failed: $failed\n";
print "Total: " . ($success + $failed) . "\n";

if ($failed == 0) {
    print "\n✅ All exports completed successfully!\n";
    print "\nOutput files in: ./output/\n";
    print "  - words.json\n";
    print "  - frequencies.json\n";
    print "  - errors.json\n";
    print "  - elisions.json\n";
    print "\nNext step: Run Python conversion scripts in FurlanSpellChecker\n";
} else {
    print "\n❌ Some exports failed. Please check errors above.\n";
    exit 1;
}
