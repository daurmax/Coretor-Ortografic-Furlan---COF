#!/usr/bin/perl

=head1 NAME

dataset_utils.pl - COF dataset generation utility for test cases

=head1 DESCRIPTION

This utility generates comprehensive test datasets by extracting real spell checker 
suggestions from COF for Friulian words. It's designed to create reference datasets 
for cross-platform validation and testing.

=head1 USAGE

    perl util/dataset_utils.pl [--format list|csv|json] [--output FILE]
    perl util/dataset_utils.pl --generate-test-cases
    perl util/dataset_utils.pl --help

=head1 OPTIONS

    --format FORMAT     Output format: list (default), csv, json
    --output FILE       Output to file instead of stdout  
    --generate-test-cases  Generate complete test case dataset
    --help              Show this help

=cut

use strict;
use warnings;
use utf8;
use Getopt::Long;
use FindBin;
use File::Spec;
use lib File::Spec->catdir($FindBin::Bin, '..', 'lib');

use COF::Data;
use COF::SpellChecker;
use COF::Utils qw(get_dict_dir);

binmode STDOUT, ':utf8';

# Parse command line options
my %opts = (
    format => 'list',
    output => undef,
    generate_test_cases => 0,
    help => 0,
);

GetOptions(
    'format=s' => \$opts{format},
    'output=s' => \$opts{output},
    'generate-test-cases' => \$opts{generate_test_cases},
    'help' => \$opts{help},
) or die "Error parsing command line options\n";

if ($opts{help}) {
    print_help();
    exit 0;
}

sub print_help {
    print <<'EOF';
dataset_utils.pl - COF dataset generation utility

USAGE:
    perl util/dataset_utils.pl [options]

OPTIONS:
    --format FORMAT         Output format (list, csv, json)
    --output FILE           Write to file instead of stdout
    --generate-test-cases   Generate comprehensive test dataset
    --help                  Show this help

EXAMPLES:
    # Generate test dataset in CSV format
    perl util/dataset_utils.pl --generate-test-cases --format csv

    # Save to file
    perl util/dataset_utils.pl --generate-test-cases --output test_dataset.txt

EOF
}

# Initialize COF components
my $dict_dir = get_dict_dir();
unless (-d $dict_dir) {
    die "Error: Dictionary directory not found: $dict_dir\n";
}

my $data;
eval { $data = COF::Data->new( COF::Data::make_default_args($dict_dir) ); };
if ($@ || !$data) {
    die "Error: Cannot initialize COF::Data: $@\n";
}

my $speller = COF::SpellChecker->new($data);
unless ($speller) {
    die "Error: Cannot create SpellChecker\n";
}

# Handle output redirection
my $output_fh = \*STDOUT;
if ($opts{output}) {
    open($output_fh, '>:utf8', $opts{output}) 
        or die "Error: Cannot open output file '$opts{output}': $!\n";
}

# Main execution
if ($opts{generate_test_cases}) {
    generate_test_dataset();
} else {
    print_help();
}

close($output_fh) if $opts{output};
exit 0;

# Main dataset generation function  
sub generate_test_dataset {
    if ($opts{format} eq 'csv') {
        print $output_fh "word,correct,suggestions\n";
    } elsif ($opts{format} eq 'json') {
        print $output_fh "[\n";
    } else {
        print $output_fh "COF Test Dataset Generation\n";
        print $output_fh "=" x 50, "\n\n";
    }

# Helper to get suggestions safely
sub get_suggestions {
    my ($word) = @_;
    my $result = eval { $speller->suggest($word) };
    return () if $@ || !defined $result || ref($result) ne 'ARRAY';
    return @$result;
}

# Helper to check if word is correct
sub is_correct {
    my ($word) = @_;
    my $result = eval { $speller->check($word) };
    return $result ? 1 : 0;
}

    # Friulian test word dataset (mix of correct/incorrect/variants)
    my @test_words = (
        # Common base words
        'furlan',     'furla',      'furlane',    'furlans',    'parol',      
        'parole',     'parolis',    'parolle',    
        
        # Words with accents and Friulian-specific characters
        'cjase',      'cjasa',      'gnove',      'gnòf',       'gnùf',       
        'biele',      'biel',       'bel',        'gjenar',     'genar',      
        'çucarut',    'zucarut',    'scuele',     'scuela',     
        
        # Common elisions
        "l'aghe",     "la aghe",    "d'estât",    "di estât",   "un'ore",     
        "une ore",    "l'an",       "la an",      
        
        # Hyphenated words
        'cjase-parol',    'parol-errade',   'bien-vignût',
        
        # Case variations
        'Furlan',     'FURLAN',     'FuRlAn',     'Cjase',      'CJASE',
        
        # Complex words
        'ostarie',    'ostaria',    'bicjere',    'biciere',    'formenton',
        'lenghe',     'lenghis',    'lengha',     'lenghas',    
        
        # Words that might not generate suggestions
        'xyzqwerty',  'blablabla',  'qqqqq',      'xxxyyy',
        
        # Short words
        'a',          'e',          'i',          'o',          'u',
        
        # Words with doubles and variants
        'anel',       'anell',      'piere',      'pierre',     'viere',
        'vere',       'mangjâ',     'mangja',     'mandâ',      'manda',
    );
    
    my $total = scalar(@test_words);
    my $count = 0;
    
    for my $word (@test_words) {
        $count++;
        my $correct = is_correct($word);
        my @suggestions = get_suggestions($word);
        my $sugg_str = @suggestions ? join(", ", @suggestions[0..4]) : "";  # max 5 suggestions
        
        if ($opts{format} eq 'csv') {
            # CSV format: escape quotes and format properly
            my $escaped_word = $word;
            my $escaped_sugg = $sugg_str;
            $escaped_word =~ s/"/""/g;
            $escaped_sugg =~ s/"/""/g;
            print $output_fh sprintf('"%s",%s,"%s"', $escaped_word, $correct ? 'true' : 'false', $escaped_sugg);
            print $output_fh "\n";
        } elsif ($opts{format} eq 'json') {
            # JSON format
            my $comma = ($count < $total) ? "," : "";
            print $output_fh sprintf('  {"word": "%s", "correct": %s, "suggestions": [%s]}%s', 
                $word, $correct ? 'true' : 'false',
                join(", ", map { "\"$_\"" } @suggestions[0..4]), $comma);
            print $output_fh "\n";
        } else {
            # List format (default)
            printf $output_fh "%-15s | %s | %s\n", 
                $word,
                $correct ? "CORRECT" : "WRONG  ",
                $sugg_str || "NO_SUGGESTIONS";
        }
    }
    
    if ($opts{format} eq 'json') {
        print $output_fh "]\n";
    } elsif ($opts{format} eq 'list') {
        print $output_fh "\nProcessed $total words.\n";
    }
}