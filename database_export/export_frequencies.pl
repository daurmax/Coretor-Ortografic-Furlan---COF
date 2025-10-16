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
my $frec_db = "$dict_dir/frec.db";
my $output_json = "$output_dir/frequencies.json";

print "=== COF Database Export: frec.db → JSON ===\n\n";

# Check if frec.db exists
die "ERROR: Cannot find $frec_db\n" unless -f $frec_db;

# Create output directory if it doesn't exist
unless (-d $output_dir) {
    mkdir $output_dir or die "Cannot create output directory: $!\n";
    print "Created output directory: $output_dir\n";
}

# Open frec.db with the same filters as COF/lib/COF/Data.pm
print "Opening $frec_db...\n";
tie(my %frec, "DB_File", $frec_db, O_RDONLY, 0666)
    or die("Cannot open '$frec_db': $!\n");

my $dbh = tied %frec;
# Keys are already UTF-8 encoded in the database
# Use UTF-8 decoding for keys (as per COF/lib/COF/Data.pm line 82)
$dbh->filter_fetch_key( sub { utf8::decode($_) } );
$dbh->filter_store_key( sub { utf8::encode($_) } );
# Unpack byte value to integer (as per COF/lib/COF/Data.pm line 84)
$dbh->filter_fetch_value( sub { $_ = unpack("C", $_) } );

# Export all entries
print "Exporting entries...\n";
my %frequencies;
my $count = 0;
my $total = scalar keys %frec;

foreach my $word (keys %frec) {
    my $freq = $frec{$word};
    $frequencies{$word} = $freq;
    $count++;
    
    # Progress indicator
    if ($count % 10000 == 0) {
        printf "  Progress: %d/%d (%.1f%%)\n", $count, $total, ($count/$total)*100;
    }
}

untie %frec;

# Write JSON output
print "\nWriting JSON to $output_json...\n";
open(my $fh, '>:utf8', $output_json) 
    or die "Cannot write to $output_json: $!\n";

# Don't use ->utf8 flag when filehandle is already :utf8
my $json = JSON::PP->new->pretty->canonical;
print $fh $json->encode(\%frequencies);
close $fh;

# Statistics
print "\n=== EXPORT COMPLETE ===\n";
print "Total entries exported: $count\n";
print "Output file: $output_json\n";

# Verify some accented words
print "\n=== VERIFICATION (Sample Accented Words) ===\n";
my @test_words = qw(fûr à furlane a ur);
foreach my $word (@test_words) {
    if (exists $frequencies{$word}) {
        printf "  %-10s -> %d\n", $word, $frequencies{$word};
    } else {
        printf "  %-10s -> NOT FOUND\n", $word;
    }
}

# Count accented words
my $accented = 0;
my $non_accented = 0;
foreach my $word (keys %frequencies) {
    if ($word =~ /[ûàèìòùâêîôç]/) {
        $accented++;
    } else {
        $non_accented++;
    }
}

print "\n=== STATISTICS ===\n";
print "Words with accents: $accented\n";
print "Words without accents: $non_accented\n";
print "Total: " . ($accented + $non_accented) . "\n";

my $file_size = -s $output_json;
printf "JSON file size: %.2f MB\n", $file_size / (1024 * 1024);

print "\n✅ Export successful!\n";
