#!/usr/bin/env perl
use strict;
use warnings;
use utf8;
use FindBin;
use File::Spec;
use lib File::Spec->catdir($FindBin::Bin, '..', 'lib');

use Getopt::Long qw(GetOptions);
use JSON::PP;
use Encode qw(encode);

use COF::Data;
use COF::SpellChecker;

my $help = 0;
my $word;
my $suggest = '';
my $from_file = '';
my $format = 'list';   # list | array | json
my $list_only = 0;

GetOptions(
    'help|h'    => \$help,
    'word|w=s'  => \$word,
    'suggest|s=s' => \$suggest,
    'file|f=s'  => \$from_file,
    'format=s'  => \$format,
    'list'      => \$list_only,
) or die "Invalid options\n";

if ($help) {
    print "Usage: $0 --suggest WORD | --word WORD [--format list|array|json] [--file FILE]\n";
    exit 0;
}

my $dict_dir = File::Spec->catdir($FindBin::Bin, '..', 'dict');
my $data = COF::Data->new(COF::Data::make_default_args($dict_dir));
my $spell_checker = COF::SpellChecker->new($data);

my @words;
if ($from_file) {
    open my $fh, '<:encoding(UTF-8)', $from_file or die "Cannot open '$from_file': $!";
    while (my $line = <$fh>) { chomp $line; push @words, $line if length $line }
    close $fh;
}

if ($suggest) {
    my $sug_ref = $spell_checker->suggest($suggest);
    push @words, @$sug_ref if $sug_ref && ref $sug_ref eq 'ARRAY';
}

push @words, $word if defined $word;

die "No words to show, use --help\n" unless @words;

if ($list_only) {
    print join("\n", @words), "\n";
    exit 0;
}

if ($format eq 'json') {
    print JSON::PP->new->utf8->pretty->encode(\@words);
    exit 0;
}

if ($format eq 'array') {
    print "Array for test: qw(" . join(' ', @words) . ");\n";
    print "Count: " . scalar(@words) . "\n";
} else {
    print "Suggestions: " . join(', ', @words) . "\n";
    print "Count: " . scalar(@words) . "\n";
}

# small encoding debug for non-ascii
print "\n=== ENCODING DEBUG ===\n";
for my $s (@words) {
    if ($s =~ /[^\x00-\x7F]/) {
        my $hex = unpack('H*', encode('utf8', $s));
        my $chars = join(' ', map { sprintf("U+%04X", ord($_)) } split //, $s);
        printf "  %s: UTF-8=%s Unicode=%s\n", $s, $hex, $chars;
    }
}