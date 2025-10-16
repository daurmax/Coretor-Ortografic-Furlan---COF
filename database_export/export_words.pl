#!/usr/bin/env perl

use strict;
use warnings;
use utf8;
use DB_File;
use JSON::PP;
use Encode qw/decode/;

binmode(STDOUT, ":utf8");

print "=== COF Database Export: words.db → JSON ===\n\n";

my $db_path = "../dict/words.db";
my $output_path = "./output/words.json";

# Open BerkeleyDB with COF encoding filters
print "Opening $db_path...\n";
my $dbh = tie(my %words, "DB_File", $db_path, O_RDONLY, 0666)
    or die "Cannot open $db_path: $!\n";

# Apply COF's exact encoding filters (from COF::Data)
$dbh->filter_fetch_key(sub { $_ = decode("iso-8859-1", $_); });
$dbh->filter_fetch_value(sub { $_ = decode("iso-8859-1", $_); });

# Export to hash
print "Exporting entries...\n";
my %export;
my $count = 0;
my $total = scalar(keys %words);

for my $phonetic_hash (keys %words) {
    my $words_list = $words{$phonetic_hash};
    $export{$phonetic_hash} = $words_list;
    
    $count++;
    if ($count % 5000 == 0) {
        printf("  Progress: %d/%d (%.1f%%)\n", $count, $total, ($count/$total)*100);
    }
}

untie %words;

# Write JSON
print "\nWriting JSON to $output_path...\n";
my $json = JSON::PP->new->utf8->pretty->canonical->encode(\%export);
open(my $fh, ">:utf8", $output_path) or die "Cannot write to $output_path: $!\n";
print $fh $json;
close($fh);

# Statistics
my $file_size = -s $output_path;
my $size_mb = $file_size / (1024 * 1024);

print "\n=== EXPORT COMPLETE ===\n";
print "Total phonetic hashes exported: $count\n";
print "Output file: $output_path\n";

# Verification: Show some sample entries
print "\n=== VERIFICATION (Sample Phonetic Hashes) ===\n";
my @sample_hashes = (sort keys %export)[0..9];
for my $hash (@sample_hashes) {
    my $words = $export{$hash};
    my @word_list = split(/,/, $words);
    my $word_count = scalar(@word_list);
    printf("  %s -> %d words (%s...)\n", 
           $hash, 
           $word_count, 
           join(", ", @word_list[0..($word_count > 3 ? 2 : $word_count-1)]));
}

# Count statistics
my $total_words = 0;
my $single_word_hashes = 0;
my $multi_word_hashes = 0;
for my $hash (keys %export) {
    my @words = split(/,/, $export{$hash});
    my $count = scalar(@words);
    $total_words += $count;
    if ($count == 1) {
        $single_word_hashes++;
    } else {
        $multi_word_hashes++;
    }
}

print "\n=== STATISTICS ===\n";
print "Total phonetic hashes: $count\n";
print "Total words indexed: $total_words\n";
print "Hashes with single word: $single_word_hashes\n";
print "Hashes with multiple words: $multi_word_hashes\n";
printf("JSON file size: %.2f MB\n", $size_mb);

print "\n✅ Export successful!\n";
