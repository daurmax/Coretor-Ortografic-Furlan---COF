#!/usr/bin/env perl
use strict;
use warnings;
use utf8;
use DB_File;
use Fcntl;
use JSON::PP;
use Encode qw(encode);

binmode STDOUT, ":utf8";

# Paths
my $dict_dir = "../dict";
my $output_dir = "./output";
my $elisions_db = "$dict_dir/elisions.db";
my $output_json = "$output_dir/elisions.json";

print "=== COF Database Export: elisions.db → JSON ===\n\n";

# Check if elisions.db exists
die "ERROR: Cannot find $elisions_db\n" unless -f $elisions_db;

# Create output directory if it doesn't exist
unless (-d $output_dir) {
    mkdir $output_dir or die "Cannot create output directory: $!\n";
    print "Created output directory: $output_dir\n";
}

# Open elisions.db with the same filters as COF/lib/COF/Data.pm
print "Opening $elisions_db...\n";
tie(my %elisions, "DB_File", $elisions_db, O_RDONLY, 0666)
    or die("Cannot open '$elisions_db': $!\n");

my $dbh = tied %elisions;
# Use UTF-8 decoding for keys (as per COF/lib/COF/Data.pm line 82)
$dbh->filter_fetch_key( sub { utf8::decode($_) } );
$dbh->filter_store_key( sub { utf8::encode($_) } );
# Note: elisions.db is a hash where presence = true, no value needed

# Export all entries (elisions are stored as keys only, value doesn't matter)
print "Exporting entries...\n";
my @elision_words;
my $count = 0;

foreach my $word (keys %elisions) {
    push @elision_words, $word;
    $count++;
}

untie %elisions;

# Sort for consistency
@elision_words = sort @elision_words;

# Write JSON output as array (list of words)
print "\nWriting JSON to $output_json...\n";
open(my $fh, '>:utf8', $output_json) 
    or die "Cannot write to $output_json: $!\n";

my $json = JSON::PP->new->utf8->pretty->canonical;
print $fh $json->encode(\@elision_words);
close $fh;

# Statistics
print "\n=== EXPORT COMPLETE ===\n";
print "Total entries exported: $count\n";
print "Output file: $output_json\n";

# Show some examples
print "\n=== EXAMPLES (First 20 entries) ===\n";
my $shown = 0;
foreach my $word (@elision_words) {
    print "  $word\n";
    $shown++;
    last if $shown >= 20;
}

my $file_size = -s $output_json;
printf "\nJSON file size: %.2f KB\n", $file_size / 1024;

print "\n✅ Export successful!\n";
