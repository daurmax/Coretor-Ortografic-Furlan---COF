#!/usr/bin/env perl
use strict;
use warnings;
use utf8;
use FindBin;
use File::Spec;
use lib File::Spec->catdir($FindBin::Bin, '..', 'lib');

use Getopt::Long qw(GetOptions);
use JSON::PP;
use List::Util qw(shuffle);

use COF::Data;

my $help = 0;
my $word;
my $from_file = '';
my $format = 'list';  # list | array | json
my $list_only = 0;
my $generate_tests = 0;
my $sample_size = 50;

GetOptions(
    'help|h'        => \$help,
    'word|w=s'      => \$word,
    'file|f=s'      => \$from_file,
    'format=s'      => \$format,
    'list'          => \$list_only,
    'generate-tests' => \$generate_tests,
    'sample=i'      => \$sample_size,
) or die "Invalid options\n";

if ($help) { 
    print "Usage: $0 --word WORD | --file FILE [--format list|array|json]\n";
    print "       $0 --generate-tests [--sample N] [--format json|perl]\n";
    print "\n";
    print "Options:\n";
    print "  --generate-tests  Generate test dataset from legacy words\n";
    print "  --sample N        Sample size for test generation (default: 50)\n";
    exit 0;
}

my $dict_dir = File::Spec->catdir($FindBin::Bin, '..', 'dict');
my $data = COF::Data->new(COF::Data::make_default_args($dict_dir));
my $rt_checker = $data->get_words_rt();

# Handle test generation mode
if ($generate_tests) {
    generate_test_dataset($rt_checker, $sample_size, $format);
    exit 0;
}

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

sub generate_test_dataset {
    my ($rt_checker, $sample_size, $format) = @_;
    
    my $legacy_dir = File::Spec->catdir($FindBin::Bin, '..', 'legacy');
    my $words_file = File::Spec->catfile($legacy_dir, 'peraulis_cof_2015.txt');
    
    unless (-f $words_file) {
        die "Legacy words file not found: $words_file\n";
    }
    
    # Read all words from legacy file
    my @all_words;
    open my $fh, '<:encoding(UTF-8)', $words_file or die "Cannot open $words_file: $!";
    while (my $line = <$fh>) {
        chomp $line;
        next unless $line;
        
        # Extract word (first column, before tab)
        my ($word) = split /\t/, $line;
        next unless $word && length($word) > 2;  # Skip very short words
        next if $word =~ /^'/;  # Skip words starting with apostrophe
        
        push @all_words, $word;
    }
    close $fh;
    
    # Create sample that includes both valid words and misspelled variants
    my @test_cases;
    
    # Sample random valid words
    my @shuffled = shuffle @all_words;
    my @sample_words = splice @shuffled, 0, int($sample_size * 0.6);  # 60% valid words
    
    # Add some deliberately misspelled variants for the remaining 40%
    my @misspelled = generate_misspelled_variants(\@sample_words, int($sample_size * 0.4));
    push @test_cases, @sample_words, @misspelled;
    
    # Generate suggestions for all test cases
    my %results;
    for my $word (@test_cases) {
        my @suggestions = eval { $rt_checker->get_words_ed1($word) };
        next if $@;  # Skip words that cause errors
        
        $results{$word} = \@suggestions;
    }
    
    if ($format eq 'json') {
        print JSON::PP->new->utf8->pretty->canonical->encode(\%results);
    } else {
        # Default Perl test format
        print "# RadixTree test dataset generated from legacy words\n";
        print "# Total test cases: " . scalar(keys %results) . "\n\n";
        print "my \%RADIX_TEST_CASES = (\n";
        
        for my $word (sort keys %results) {
            my @suggestions = @{$results{$word}};
            my $sugs_str = join(', ', map { "'$_'" } @suggestions);
            print "    '$word' => [$sugs_str],\n";
        }
        
        print ");\n\n";
        print "\n1;  # Return true value for 'do' command\n\n";
        print "# Usage in tests:\n";
        print "# for my \$word (keys \%RADIX_TEST_CASES) {\n";
        print "#     my \@expected = \@{\$RADIX_TEST_CASES{\$word}};\n";
        print "#     my \@got = \$rt_checker->get_words_ed1(\$word);\n";
        print "#     is_deeply(\\\@got, \\\@expected, \"RadixTree suggestions for '\$word'\");\n";
        print "# }\n";
    }
}

sub generate_misspelled_variants {
    my ($words_ref, $count) = @_;
    my @variants;
    
    my @mutations = (
        sub { my $w = shift; $w =~ s/a/e/; return $w; },      # a->e substitution
        sub { my $w = shift; $w =~ s/e/a/; return $w; },      # e->a substitution  
        sub { my $w = shift; $w =~ s/i/e/; return $w; },      # i->e substitution
        sub { my $w = shift; $w =~ s/o/u/; return $w; },      # o->u substitution
        sub { my $w = shift; $w .= 'a'; return $w; },         # add suffix 'a'
        sub { my $w = shift; chop $w; return $w; },           # remove last char
        sub { my $w = shift; $w =~ s/ll/l/; return $w; },     # double->single consonant
        sub { my $w = shift; $w =~ s/ss/s/; return $w; },     # double->single consonant
    );
    
    my @shuffled_words = shuffle @$words_ref;
    
    for my $i (0 .. $count - 1) {
        last if $i >= @shuffled_words;
        
        my $original = $shuffled_words[$i];
        my $mutation = $mutations[rand @mutations];
        my $variant = $mutation->($original);
        
        # Ensure variant is different and not empty
        if ($variant ne $original && length($variant) > 1) {
            push @variants, $variant;
        }
    }
    
    return @variants;
}