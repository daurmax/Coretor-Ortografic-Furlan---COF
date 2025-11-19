#!/usr/bin/env perl

=head1 NAME

word_lookup_utils.pl - COF word lookup and metadata inspection utility

=head1 SYNOPSIS

    perl util/word_lookup_utils.pl --word WORD [options]
    perl util/word_lookup_utils.pl --batch FILE [options]

=head1 DESCRIPTION

Utility for querying the COF database to check if specific words exist and retrieve
their associated metadata (frequency, phonetic code, suggestions, etc.).

Useful for:
- Debugging why specific words appear/don't appear in suggestions
- Comparing database content between COF and Python implementations
- Verifying word frequencies and phonetic codes
- Investigating ranking differences

=head1 OPTIONS

    --help, -h          Show this help message
    --word, -w WORD     Look up a single word
    --batch, -b FILE    Look up words from file (one per line)
    --suggest, -s       Include suggestions for the word
    --phonetic, -p      Include phonetic code
    --similar, -m       Include similar words (within edit distance 1-2)
    --json              Output in JSON format
    --verbose, -v       Verbose output with all metadata

=head1 EXAMPLES

    # Basic word lookup
    perl util/word_lookup_utils.pl --word Cjas
    
    # Detailed lookup with suggestions and phonetic
    perl util/word_lookup_utils.pl --word cjasa --suggest --phonetic
    
    # Check multiple words
    perl util/word_lookup_utils.pl --batch words_to_check.txt
    
    # Full metadata with similar words
    perl util/word_lookup_utils.pl --word furla --verbose --similar
    
    # JSON output for scripting
    perl util/word_lookup_utils.pl --word cjase --json

=head1 OUTPUT

For each word, displays:
- Existence in dictionary (radix tree)
- Frequency value (if exists)
- Phonetic code (if requested)
- Suggestions (if requested)
- Similar words (if requested)

=head1 AUTHOR

COF Development Team

=cut

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
use COF::Utils qw(get_dict_dir);

binmode(STDOUT, ":encoding(utf8)");
binmode(STDERR, ":encoding(utf8)");

# Parse command line options
my $help = 0;
my $word = '';
my $batch_file = '';
my $show_suggest = 0;
my $show_phonetic = 0;
my $show_similar = 0;
my $json_output = 0;
my $verbose = 0;

GetOptions(
    'help|h'        => \$help,
    'word|w=s'      => \$word,
    'batch|b=s'     => \$batch_file,
    'suggest|s'     => \$show_suggest,
    'phonetic|p'    => \$show_phonetic,
    'similar|m'     => \$show_similar,
    'json'          => \$json_output,
    'verbose|v'     => \$verbose,
) or die "Invalid options. Use --help for usage information.\n";

if ($help) {
    exec("perldoc", $0);
    exit;
}

# Require at least one word source
unless ($word || $batch_file) {
    die "Error: Must specify --word or --batch\nUse --help for usage information.\n";
}

# If verbose, enable all metadata
if ($verbose) {
    $show_suggest = 1;
    $show_phonetic = 1;
    $show_similar = 1;
}

# Initialize COF::Data
my $dict_dir = get_dict_dir();
unless (-d $dict_dir) {
    die "Error: Dictionary directory not found: $dict_dir\n";
}

my $data = eval { COF::Data->new( COF::Data::make_default_args($dict_dir) ) };
if ($@ || !$data) {
    die "Error: Cannot initialize COF::Data: $@\n";
}

my $speller = eval { COF::SpellChecker->new($data) };
if ($@ || !$speller) {
    die "Error: Cannot initialize COF::SpellChecker: $@\n";
}

# Process words
my @words_to_check;
if ($word) {
    push @words_to_check, $word;
}
if ($batch_file) {
    open my $fh, '<:encoding(utf8)', $batch_file 
        or die "Error: Cannot open batch file '$batch_file': $!\n";
    while (my $line = <$fh>) {
        chomp $line;
        $line =~ s/^\s+|\s+$//g;  # trim
        push @words_to_check, $line if $line;
    }
    close $fh;
}

# Output results
if ($json_output) {
    my @results;
    for my $w (@words_to_check) {
        push @results, lookup_word_json($w);
    }
    print JSON::PP->new->utf8->pretty->encode(\@results);
} else {
    for my $w (@words_to_check) {
        lookup_word_text($w);
        print "\n" if @words_to_check > 1;
    }
}

# === SUBROUTINES ===

sub lookup_word_text {
    my ($w) = @_;
    
    print "=" x 70, "\n";
    print "WORD LOOKUP: '$w'\n";
    print "=" x 70, "\n\n";
    
    # Check if word is correct (no suggestions needed)
    my $is_correct = eval { $speller->check_word($w)->{ok} };
    print "Correct spelling: " . ($is_correct ? "YES ✓" : "NO ✗") . "\n";
    
    # Get frequency
    my $freq_db = $data->get_freq;
    my $frequency = $freq_db->{$w} || 0;
    print "Frequency: $frequency\n";
    
    # Phonetic code
    if ($show_phonetic) {
        my ($ph1, $ph2) = eval { COF::Data::phalg_furlan($w) };
        if ($ph1 || $ph2) {
            print "Phonetic codes: ";
            print "[$ph1]" if $ph1;
            print " " if $ph1 && $ph2;
            print "[$ph2]" if $ph2;
            print "\n";
        } else {
            print "Phonetic codes: (none)\n";
        }
    }
    
    # Get suggestions if word is misspelled
    if ($show_suggest) {
        print "\nSuggestions:\n";
        my $suggestions = eval { $speller->suggest($w) };
        if ($@ || !$suggestions || @$suggestions == 0) {
            print "  (none)\n";
        } else {
            my $max_show = $verbose ? scalar(@$suggestions) : 10;
            for my $i (0 .. min($max_show - 1, $#$suggestions)) {
                my $sugg = $suggestions->[$i];
                my $sugg_freq = $freq_db->{$sugg} || 0;
                printf "  %2d. %-20s (frequency: %d)\n", $i+1, $sugg, $sugg_freq;
            }
            if (@$suggestions > $max_show) {
                printf "  ... and %d more\n", scalar(@$suggestions) - $max_show;
            }
        }
    }
    
    # Find similar words (edit distance 1-2)
    if ($show_similar) {
        print "\nSimilar words in dictionary:\n";
        my @similar = find_similar_words($w);
        if (@similar == 0) {
            print "  (none found)\n";
        } else {
            for my $i (0 .. min(19, $#similar)) {
                my $sim = $similar[$i];
                my $sim_freq = $freq_db->{$sim} || 0;
                printf "  %-20s (frequency: %d)\n", $sim, $sim_freq;
            }
            if (@similar > 20) {
                printf "  ... and %d more\n", scalar(@similar) - 20;
            }
        }
    }
    
    print "=" x 70, "\n";
}

sub lookup_word_json {
    my ($w) = @_;
    
    my $is_correct = eval { $speller->check_word($w)->{ok} } || 0;
    my $frequency = $data->get_freq->{$w} || 0;
    
    my %result = (
        word => $w,
        correct_spelling => $is_correct ? JSON::PP::true : JSON::PP::false,
        frequency => $frequency,
    );
    
    if ($show_phonetic) {
        my ($ph1, $ph2) = eval { COF::Data::phalg_furlan($w) };
        $result{phonetic_codes} = [];
        push @{$result{phonetic_codes}}, $ph1 if $ph1;
        push @{$result{phonetic_codes}}, $ph2 if $ph2;
    }
    
    if ($show_suggest) {
        my $suggestions = eval { $speller->suggest($w) };
        $result{suggestions} = $suggestions || [];
    }
    
    if ($show_similar) {
        $result{similar_words} = [find_similar_words($w)];
    }
    
    return \%result;
}

sub find_similar_words {
    my ($w) = @_;
    
    # Use the spellchecker's internal suggestion mechanism
    # to find words within edit distance 1-2
    my $lc_w = COF::Data::lc_word($w);
    my $suggestions = eval { $speller->suggest($lc_w) };
    
    return () unless $suggestions && @$suggestions;
    
    # Return first 20 suggestions as "similar" words
    my @similar = @$suggestions;
    return @similar[0 .. min(19, $#similar)];
}

sub min {
    my ($a, $b) = @_;
    return $a < $b ? $a : $b;
}

__END__

=head1 SEE ALSO

L<COF::Data>, L<COF::SpellChecker>, L<database_utils.pl>

=head1 COPYRIGHT

Copyright (C) 2025 COF Development Team

=cut
