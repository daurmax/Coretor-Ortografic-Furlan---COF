#!/usr/bin/env perl
use strict;
use warnings;
use utf8;
use FindBin;
use File::Spec;
use BerkeleyDB;
use Encode qw(encode decode);

binmode(STDOUT, ":encoding(utf8)");

my $dict_dir = File::Spec->catdir($FindBin::Bin, '..', 'dict');
my $output_dir = $ARGV[0] || File::Spec->catdir(
    $FindBin::Bin, '..', '..', 'FurlanSpellChecker', 'data', 'databases', 'tsv_export'
);

unless (-d $output_dir) {
    mkdir $output_dir or die "Cannot create $output_dir: $!";
}

print "Exporting COF databases to TSV format...\n";
print "Source: $dict_dir\n";
print "Output: $output_dir\n\n";

# Export words.db (phonetic hash -> words) - ISO-8859-1 encoded!
export_hash_db("$dict_dir/words.db", "$output_dir/words.tsv", "phonetic", 0, 'iso-8859-1');

# Export frec.db (word -> frequency) - UTF-8 encoded, values are packed bytes
export_hash_db("$dict_dir/frec.db", "$output_dir/frequencies.tsv", "frequency", 1, 'utf-8');

# Export errors.db (error -> correction) - check encoding
export_hash_db("$dict_dir/errors.db", "$output_dir/errors.tsv", "errors", 0, 'utf-8');

# Export elisions.db (word -> 1) - check encoding
export_hash_db("$dict_dir/elisions.db", "$output_dir/elisions.tsv", "elisions", 0, 'utf-8');

print "\nExport complete!\n";

sub export_hash_db {
    my ($db_path, $output_path, $name, $value_is_packed_byte, $source_encoding) = @_;

    print "Exporting $name: $db_path -> $output_path (source: $source_encoding)\n";

    my %hash;
    tie %hash, 'BerkeleyDB::Hash', -Filename => $db_path, -Flags => DB_RDONLY
        or die "Cannot open $db_path: $BerkeleyDB::Error";

    open(my $fh, '>:raw', $output_path)
        or die "Cannot open $output_path: $!";

    my $count = 0;
    while (my ($key, $value) = each %hash) {
        my ($key_out, $value_out);
        
        if ($source_encoding eq 'iso-8859-1') {
            # Convert from ISO-8859-1 to UTF-8
            $key_out = encode('utf-8', decode('iso-8859-1', $key));
            if ($value_is_packed_byte) {
                $value_out = unpack("C", $value);
            } else {
                $value_out = encode('utf-8', decode('iso-8859-1', $value));
            }
        } else {
            # Already UTF-8, use as-is
            $key_out = $key;
            if ($value_is_packed_byte) {
                $value_out = unpack("C", $value);
            } else {
                $value_out = $value;
            }
        }

        # Escape tabs and newlines to keep TSV intact (only for string values)
        unless ($value_is_packed_byte) {
            $value_out =~ s/\t/\\t/g;
            $value_out =~ s/\n/\\n/g;
        }
        $key_out =~ s/\t/\\t/g;
        $key_out =~ s/\n/\\n/g;

        print $fh "$key_out\t$value_out\n";
        $count++;
    }

    close($fh);
    untie %hash;

    print "  Done: $count entries\n";
}
