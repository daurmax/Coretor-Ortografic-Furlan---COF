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
use COF::SpellChecker;

binmode STDOUT, ':utf8';
binmode STDERR, ':utf8';

my $help = 0;
my $word;
my $from_file = '';
my $format = 'perl';  # perl | json
my $top_n = 10;
my $generate_tests = 0;
my $verify_encoding = 0;
my $latin1_escapes = 0;

GetOptions(
    'help|h'        => \$help,
    'word|w=s'      => \$word,
    'file|f=s'      => \$from_file,
    'format=s'      => \$format,
    'top=i'         => \$top_n,
    'generate-tests' => \$generate_tests,
    'verify-encoding' => \$verify_encoding,
    'latin1-escapes' => \$latin1_escapes,
) or die "Invalid options\n";

if ($help) { 
    print "Usage: $0 --word WORD | --file FILE [--format perl|json] [--top N]\n";
    print "       $0 --generate-tests [--format perl|json] [--top N]\n";
    print "       $0 --verify-encoding\n";
    print "\n";
    print "Options:\n";
    print "  --generate-tests    Generate test ground truth for FurlanSpellChecker\n";
    print "  --verify-encoding   Verify encoding of test cases (outputs Perl format with correct UTF-8)\n";
    print "  --latin1-escapes    Use \\xNN escapes for Latin-1 characters (for use without 'use utf8')\n";
    print "  --top N             Number of top suggestions to output (default: 10)\n";
    print "  --format            Output format: perl (default) or json\n";
    exit 0;
}

my $dict_dir = File::Spec->catdir($FindBin::Bin, '..', 'dict');
my $data = COF::Data->new(COF::Data::make_default_args($dict_dir));
my $spellchecker = COF::SpellChecker->new($data);

# Handle test generation mode
if ($generate_tests) {
    generate_suggestion_ranking_ground_truth($spellchecker, $format, $top_n);
    exit 0;
}

# Handle encoding verification mode
if ($verify_encoding) {
    verify_test_case_encoding($spellchecker, $latin1_escapes);
    exit 0;
}

my @words;
if ($from_file) {
    open my $fh, '<:encoding(UTF-8)', $from_file or die "Cannot open '$from_file': $!";
    while (my $line = <$fh>) { 
        chomp $line; 
        push @words, $line if length $line;
    }
    close $fh;
}

push @words, $word if defined $word;

die "No word provided, use --help\n" unless @words;

my %results;
for my $w (@words) {
    my $suggestions_ref = eval { $spellchecker->suggest($w) };
    if ($@) {
        warn "Error processing '$w': $@\n";
        next;
    }
    
    my @suggestions = @$suggestions_ref;
    
    # Limit to top N
    @suggestions = @suggestions[0 .. min($top_n - 1, $#suggestions)] if @suggestions > $top_n;
    
    $results{$w} = \@suggestions;
}

if ($format eq 'json') {
    print JSON::PP->new->utf8->pretty->canonical->encode(\%results);
} else {
    # Perl format
    for my $w (sort keys %results) {
        my @suggestions = @{$results{$w}};
        print "$w => [" . join(', ', map { "'$_'" } @suggestions) . "]\n";
    }
}

sub generate_suggestion_ranking_ground_truth {
    my ($spellchecker, $format, $top_n) = @_;
    $format ||= 'perl';
    $top_n ||= 10;
    
    # Test words from FurlanSpellChecker that need ranking ground truth
    my @test_words = (
        # Basic test cases
        'furla', 'lengha', 'anell', 'ostaria',
        
        # Complex cases with multiple suggestions
        'cjupe', 'cjasa', 'scuela', 'gjave', 'aghe', 'plui',
        
        # Frequency-based ranking tests
        'bon', 'grant', 'piçul', 'alt', 'bas',
        
        # Longer words
        'prossim', 'lontam',
        
        # Case variations
        'Furla', 'FURLA', 'Lengha', 'LENGHA',
        
        # Edge cases
        'a', 'ab', 'fu', 'xyz',
        
        # Friulian special characters
        'cjàse', 'furlanâ', 'çi',
        
        # Apostrophe words
        "d'aghe", "un'aghe",
        
        # Variations of same root
        'furlane', 'furlani', 'furlans', 'furlanà',
    );
    
    print "=== COF Suggestion Ranking Ground Truth Generator ===\n" unless $format eq 'json';
    print "COF SpellChecker initialized successfully\n" unless $format eq 'json';
    print "Generating ranking ground truth for " . scalar(@test_words) . " test words\n" unless $format eq 'json';
    print "Top $top_n suggestions per word\n\n" unless $format eq 'json';
    
    my %ground_truth;
    my $processed = 0;
    
    for my $word (@test_words) {
        print "Processing '$word'... " unless $format eq 'json';
        
        my $suggestions_ref = eval { $spellchecker->suggest($word) };
        if ($@) {
            print "ERROR: $@\n" unless $format eq 'json';
            $ground_truth{$word} = { 
                error => $@,
                suggestions => []
            };
        } else {
            my @all_suggestions = @$suggestions_ref;
            my @top_suggestions = @all_suggestions[0 .. min($top_n - 1, $#all_suggestions)];
            
            print "got " . scalar(@all_suggestions) . " suggestions" unless $format eq 'json';
            print " (showing top $top_n)" if @all_suggestions > $top_n && $format ne 'json';
            print "\n" unless $format eq 'json';
            
            $ground_truth{$word} = {
                suggestions => \@top_suggestions,
                total_count => scalar(@all_suggestions),
                top_n => scalar(@top_suggestions)
            };
        }
        $processed++;
    }
    
    # Output results
    if ($format eq 'json') {
        my $json = JSON::PP->new->pretty->utf8;
        print $json->encode(\%ground_truth);
    } else {
        # Human readable output for Perl test integration
        print "\n=== Ground Truth Results (Perl format) ===\n";
        print "# Generated test cases for COF test_suggestion_ranking.pl\n";
        print "# Source: FurlanSpellChecker suggestion ranking test cases\n";
        print "# Generated: " . localtime() . "\n";
        print "# Top suggestions per word: $top_n\n\n";
        
        print "my \%SUGGESTION_RANKING_GROUND_TRUTH = (\n";
        for my $word (sort keys %ground_truth) {
            my $result = $ground_truth{$word};
            if ($result->{error}) {
                print "    # '$word' => ERROR: $result->{error}\n";
            } else {
                my @suggestions = @{$result->{suggestions}};
                if (@suggestions) {
                    # Properly escape and format suggestions
                    my @escaped_suggestions;
                    for my $suggestion (@suggestions) {
                        # Escape single quotes in suggestions
                        $suggestion =~ s/'/\\'/g;
                        push @escaped_suggestions, $suggestion;
                    }
                    my $suggestions_str = join("', '", @escaped_suggestions);
                    my $comment = $result->{total_count} > $result->{top_n} 
                        ? "  # Total: $result->{total_count}, showing top $result->{top_n}"
                        : "  # Total: $result->{total_count}";
                    print "    '$word' => ['$suggestions_str'],$comment\n";
                } else {
                    print "    '$word' => [],  # No suggestions\n";
                }
            }
        }
        print ");\n\n";
        
        print "# Statistics:\n";
        my $with_suggestions = grep { @{$ground_truth{$_}->{suggestions}} > 0 } keys %ground_truth;
        my $without_suggestions = grep { @{$ground_truth{$_}->{suggestions}} == 0 } keys %ground_truth;
        my $with_errors = grep { $ground_truth{$_}->{error} } keys %ground_truth;
        
        print "# - Words with suggestions: $with_suggestions\n";
        print "# - Words without suggestions: $without_suggestions\n";
        print "# - Words with errors: $with_errors\n";
        print "# - Total processed: $processed\n";
        print "\n";
        print "# Usage in tests:\n";
        print "# for my \$word (keys \%SUGGESTION_RANKING_GROUND_TRUTH) {\n";
        print "#     my \@expected = \@{\$SUGGESTION_RANKING_GROUND_TRUTH{\$word}};\n";
        print "#     my \@got = \@{\$spellchecker->suggest(\$word)};\n";
        print "#     # Compare top N suggestions\n";
        print "#     my \@got_top = \@got[0 .. min(\$#expected, \$#got)];\n";
        print "#     is_deeply(\\\@got_top, \\\@expected, \"Suggestion ranking for '\$word'\");\n";
        print "# }\n";
    }
}

sub verify_test_case_encoding {
    my ($spellchecker, $use_escapes) = @_;
    
    print "=== Encoding Verification for Test Cases ===\n";
    print "# This output can be directly copied into test_suggestion_ranking.pl\n";
    if ($use_escapes) {
        print "# Using Latin-1 hex escapes (\\xNN) - use WITHOUT 'use utf8;' pragma\n\n";
    } else {
        print "# All characters are in correct UTF-8 encoding as produced by COF\n\n";
    }
    
    # Test cases from SUGGESTION_ORDER_TEST_CASES with expected counts
    my %test_words = (
        'furla' => 1,
        'lengha' => 2,
        'anell' => 3,
        'ostaria' => 2,
        'lontam' => 1,
        'cjupe' => 10,
        'cjasa' => 10,
        'scuela' => 6,
        'gjave' => 10,
        'aghe' => 10,
        'plui' => 8,
        'bon' => 10,
        'grant' => 10,
        'alt' => 10,
        'bas' => 10,
        'Furla' => 1,
        'FURLA' => 1,
        'Lengha' => 2,
        'LENGHA' => 2,
        'a' => 10,
        'ab' => 10,
        'fu' => 10,
    );
    
    print "my \%SUGGESTION_ORDER_TEST_CASES = (\n";
    print "    # Format: word => [ordered list of expected suggestions]\n";
    print "    # Order is critical: first suggestion is most likely, last is least likely\n";
    print "    # Ground truth generated from COF SpellChecker with correct UTF-8 encoding\n\n";
    
    # Group by category for readability
    my @basic = qw(furla lengha anell ostaria lontam);
    my @complex = qw(cjupe cjasa scuela gjave aghe plui);
    my @frequency = qw(bon grant alt bas);
    my @case = qw(Furla FURLA Lengha LENGHA);
    my @short = qw(a ab fu);
    
    print "    # Basic single or few suggestions\n";
    for my $word (@basic) {
        print_test_case($spellchecker, $word, $test_words{$word}, $use_escapes);
    }
    
    print "\n    # Complex cases with multiple suggestions in specific order\n";
    for my $word (@complex) {
        print_test_case($spellchecker, $word, $test_words{$word}, $use_escapes);
    }
    
    print "\n    # Frequency-based ranking\n";
    for my $word (@frequency) {
        print_test_case($spellchecker, $word, $test_words{$word}, $use_escapes);
    }
    
    print "\n    # Case variations (case preservation)\n";
    for my $word (@case) {
        print_test_case($spellchecker, $word, $test_words{$word}, $use_escapes);
    }
    
    print "\n    # Very short inputs\n";
    for my $word (@short) {
        print_test_case($spellchecker, $word, $test_words{$word}, $use_escapes);
    }
    
    print ");\n";
}

sub print_test_case {
    my ($spellchecker, $word, $count, $use_escapes) = @_;
    
    my $sugg_ref = eval { $spellchecker->suggest($word) };
    if ($@) {
        print "    # '$word' => ERROR: $@\n";
        return;
    }
    
    my @suggestions = @$sugg_ref;
    my $last_idx = $count - 1 < $#suggestions ? $count - 1 : $#suggestions;
    my @top = @suggestions[0 .. $last_idx];
    
    print "    '$word' => [";
    if ($use_escapes) {
        # Use double quotes for escape sequences
        print join(', ', map { 
            my $s = $_;
            # Convert to Latin-1 hex escapes for characters > 127
            $s =~ s/([^ -~])/sprintf("\\x%02X", ord($1))/ge;
            $s =~ s/\\/\\\\/g;  # Escape backslashes
            $s =~ s/"/\\"/g;    # Escape double quotes
            "\"$s\"";
        } @top);
    } else {
        # Use single quotes for UTF-8 characters
        print join(', ', map { 
            my $s = $_;
            $s =~ s/'/\\'/g;  # Escape single quotes
            "'$s'";
        } @top);
    }
    print "],\n";
}

sub min {
    my ($a, $b) = @_;
    return $a < $b ? $a : $b;
}

__END__

=head1 NAME

suggestion_ranking_utils.pl - Utility for testing and generating suggestion ranking ground truth

=head1 DESCRIPTION

This utility script helps with testing and validating the suggestion ranking
functionality of COF SpellChecker. It can:

1. Generate suggestions for individual words or word lists
2. Create ground truth data for FurlanSpellChecker compatibility tests
3. Export results in Perl or JSON format

=head1 USAGE

    # Generate suggestion ranking for a single word
    perl util/suggestion_ranking_utils.pl --word furla
    
    # Generate suggestions for words in a file
    perl util/suggestion_ranking_utils.pl --file words.txt --top 5
    
    # Generate complete ground truth for FurlanSpellChecker tests
    perl util/suggestion_ranking_utils.pl --generate-tests
    
    # Generate ground truth in JSON format
    perl util/suggestion_ranking_utils.pl --generate-tests --format json

=head1 OPTIONS

=over 4

=item --word, -w WORD

Process a single word and show its suggestions in ranked order.

=item --file, -f FILE

Process multiple words from a file (one word per line).

=item --format FORMAT

Output format: 'perl' (default) or 'json'.

=item --top N

Number of top suggestions to show (default: 10).

=item --generate-tests

Generate complete ground truth for FurlanSpellChecker test suite.

=item --help, -h

Show this help message.

=back

=head1 EXAMPLES

    # Basic usage
    perl util/suggestion_ranking_utils.pl --word cjupe --top 5
    
    # Output:
    # cjupe => ['cjape', 'cope', 'copi', 'sope', 'supe']
    
    # Generate test ground truth
    perl util/suggestion_ranking_utils.pl --generate-tests > ground_truth.txt

=head1 SEE ALSO

- test_suggestion_ranking.pl - Test suite for suggestion ranking
- COF::SpellChecker - Main suggestion engine

=cut
