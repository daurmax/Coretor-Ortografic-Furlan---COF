#!/usr/bin/env perl
use strict;
use warnings;
use utf8;
use FindBin;
use File::Spec;
use lib File::Spec->catdir($FindBin::Bin, '..', 'lib');

use Getopt::Long qw(GetOptions);
use JSON::PP;

use COF::Data;

my $help = 0;
my $word;
my $from_file = '';
my $format = 'list';  # list | array | json
my $list_only = 0;

GetOptions(
	'help|h'   => \$help,
	'word|w=s' => \$word,
	'file|f=s' => \$from_file,
	'format=s' => \$format,
	'list'     => \$list_only,
) or die "Invalid options\n";

if ($help) { print "Usage: $0 --word WORD | --file FILE [--format list|array|json] \n"; exit 0 }

my $dict_dir = File::Spec->catdir($FindBin::Bin, '..', 'dict');
my $data = COF::Data->new(COF::Data::make_default_args($dict_dir));
my $rt_checker = $data->get_words_rt();

my @words;
if ($from_file) {
	open my $fh, '<:encoding(UTF-8)', $from_file or die "Cannot open '$from_file': $!";
	while (my $line = <$fh>) { chomp $line; push @words, $line if length $line }
	close $fh;
}

push @words, $word if defined $word;

die "No word provided, use --help\n" unless @words;

my @all_suggestions;
for my $w (@words) {
	my @suggestions = $rt_checker->get_words_ed1($w);
	push @all_suggestions, map { { word => $w, suggestion => $_ } } @suggestions;
}

if ($list_only) {
	for my $rec (@all_suggestions) { print $rec->{suggestion}, "\n" }
	exit 0;
}

if ($format eq 'json') {
	print JSON::PP->new->utf8->pretty->encode(\@all_suggestions);
	exit 0;
}

if ($format eq 'array') {
	my @sugs = map { $_->{suggestion} } @all_suggestions;
	print "Array for test: qw(" . join(' ', @sugs) . ");\n";
	print "Count: " . scalar(@sugs) . "\n";
} else {
	for my $rec (@all_suggestions) {
		print "$rec->{word} => $rec->{suggestion}\n";
	}
	print "Count: " . scalar(@all_suggestions) . "\n";
}