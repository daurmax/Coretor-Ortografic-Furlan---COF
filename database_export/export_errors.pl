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
my $errors_db = "$dict_dir/errors.db";
my $output_json = "$output_dir/errors.json";

print "=== COF Database Export: errors.db → JSON ===\n\n";

# Check if errors.db exists
die "ERROR: Cannot find $errors_db\n" unless -f $errors_db;

# Create output directory if it doesn't exist
unless (-d $output_dir) {
    mkdir $output_dir or die "Cannot create output directory: $!\n";
    print "Created output directory: $output_dir\n";
}

# Open errors.db with the same filters as COF/lib/COF/Data.pm
print "Opening $errors_db...\n";
tie(my %errors, "DB_File", $errors_db, O_RDONLY, 0666)
    or die("Cannot open '$errors_db': $!\n");

my $dbh = tied %errors;
# Use UTF-8 decoding for keys and values (as per COF/lib/COF/Data.pm lines 82, 86)
$dbh->filter_fetch_key( sub { utf8::decode($_) } );
$dbh->filter_store_key( sub { utf8::encode($_) } );
$dbh->filter_fetch_value( sub { utf8::decode($_) } );

# Export all entries
print "Exporting entries...\n";
my %error_corrections;
my $count = 0;

foreach my $error (keys %errors) {
    my $correction = $errors{$error};
    $error_corrections{$error} = $correction;
    $count++;
}

untie %errors;

# Write JSON output
print "\nWriting JSON to $output_json...\n";
open(my $fh, '>:utf8', $output_json) 
    or die "Cannot write to $output_json: $!\n";

my $json = JSON::PP->new->utf8->pretty->canonical;
print $fh $json->encode(\%error_corrections);
close $fh;

# Statistics
print "\n=== EXPORT COMPLETE ===\n";
print "Total entries exported: $count\n";
print "Output file: $output_json\n";

# Show some examples
print "\n=== EXAMPLES (First 10 entries) ===\n";
my $shown = 0;
foreach my $error (sort keys %error_corrections) {
    printf "  %-20s -> %s\n", $error, $error_corrections{$error};
    $shown++;
    last if $shown >= 10;
}

my $file_size = -s $output_json;
printf "\nJSON file size: %.2f KB\n", $file_size / 1024;

print "\n✅ Export successful!\n";
