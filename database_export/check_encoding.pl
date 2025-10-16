#!/usr/bin/env perl
use strict;
use warnings;
use utf8;
use DB_File;
use Fcntl;
use Encode qw(encode decode);

binmode STDOUT, ":utf8";

my $frec_db = "../dict/frec.db";

print "=== Checking frec.db encoding ===\n\n";

# Open WITHOUT filters first
tie(my %frec_raw, "DB_File", $frec_db, O_RDONLY, 0666)
    or die("Cannot open '$frec_db': $!\n");

print "Looking for keys with 'f', 'u', 'r' patterns:\n";
my $count = 0;
foreach my $key (keys %frec_raw) {
    if ($key =~ /f.*u.*r/i && $count < 10) {
        my $hex = unpack('H*', $key);
        my $value = unpack("C", $frec_raw{$key});
        
        # Try different decodings
        my $as_utf8 = eval { decode('UTF-8', $key, Encode::FB_CROAK) } // 'INVALID UTF-8';
        my $as_latin1 = decode('ISO-8859-1', $key);
        
        print "\n--- Entry #" . (++$count) . " ---\n";
        print "Raw bytes (hex): $hex\n";
        print "Raw key: $key\n";
        print "As UTF-8: $as_utf8\n";
        print "As ISO-8859-1: $as_latin1\n";
        print "Value: $value\n";
    }
}

untie %frec_raw;

print "\n\n=== Now checking specific known words ===\n\n";

# Open WITH UTF-8 filters
tie(my %frec_utf8, "DB_File", $frec_db, O_RDONLY, 0666)
    or die("Cannot open '$frec_db': $!\n");
my $dbh = tied %frec_utf8;
$dbh->filter_fetch_key( sub { utf8::decode($_) } );
$dbh->filter_store_key( sub { utf8::encode($_) } );
$dbh->filter_fetch_value( sub { $_ = unpack("C", $_) } );

my @test_words = ('fûr', 'fur', 'à', 'a', 'furlane', 'furlan');
foreach my $word (@test_words) {
    if (exists $frec_utf8{$word}) {
        printf "Found UTF-8: '%s' -> %d\n", $word, $frec_utf8{$word};
    } else {
        print "NOT found UTF-8: '$word'\n";
    }
}

untie %frec_utf8;

print "\n=== Searching for any key containing byte 0xFB (û in Latin1) ===\n\n";

# Open raw again and look for specific bytes
tie(my %frec_raw2, "DB_File", $frec_db, O_RDONLY, 0666)
    or die("Cannot open '$frec_db': $!\n");

my $found = 0;
foreach my $key (keys %frec_raw2) {
    # Look for 0xFB (û in ISO-8859-1) or 0xC3 0xBB (û in UTF-8)
    if ($key =~ /\xFB/ || $key =~ /\xE0/) {
        my $hex = unpack('H*', $key);
        my $value = unpack("C", $frec_raw2{$key});
        my $as_latin1 = decode('ISO-8859-1', $key);
        
        print "Key (hex): $hex\n";
        print "Key (ISO-8859-1): $as_latin1\n";
        print "Value: $value\n\n";
        
        last if ++$found >= 5;
    }
}

untie %frec_raw2;

print "Done!\n";
