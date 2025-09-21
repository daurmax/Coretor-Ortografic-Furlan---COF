#!/usr/bin/env perl
use strict;
use warnings;
use utf8;
use Test::More;
use FindBin;
use File::Spec;
use lib File::Spec->catdir($FindBin::Bin, '..', 'lib');

# This test does NOT depend on DB_File; it only exercises tokenization
# and Unicode handling across a broad sample of historical words.

require COF::WordIterator;

my $legacy_dir = File::Spec->catdir($FindBin::Bin, '..', 'legacy');
my $lemmas_file = File::Spec->catfile($legacy_dir, 'lemis_cof_2015.txt');
my $words_file  = File::Spec->catfile($legacy_dir, 'peraulis_cof_2015.txt');

ok(-f $lemmas_file, 'Legacy: lemmas file exists');
ok(-f $words_file,  'Legacy: words file exists');

# Read a bounded sample to keep runtime reasonable
my $MAX_LEMMAS = 400;   # small slice for structure variety
my $MAX_WORDS  = 1200;  # broader slice for surface forms

sub slurp_sample {
    my ($path, $limit) = @_;
    open my $fh, '<:encoding(UTF-8)', $path or die "Cannot open $path: $!";
    my @out;
    while (<$fh>) {
        chomp;
        next unless length;
        s/\t.*$//; # strip trailing columns/frequencies
        push @out, $_;
        last if @out >= $limit;
    }
    close $fh;
    return \@out;
}

my $lemmas = slurp_sample($lemmas_file, $MAX_LEMMAS);
my $words  = slurp_sample($words_file,  $MAX_WORDS);

ok(@$lemmas > 100, 'Legacy: collected >100 lemma entries');
ok(@$words  > 300, 'Legacy: collected >300 word entries');

# Basic character coverage checks (apostrophes variants, accented vowels)
my %seen;
for my $w (@$words) {
    $seen{apostrophe}++ if $w =~ /['’`]/;
    $seen{accent_a}++   if $w =~ /[àáâ]/;
    $seen{accent_e}++   if $w =~ /[èéê]/;
    $seen{accent_i}++   if $w =~ /[ìíî]/;
    $seen{accent_o}++   if $w =~ /[òóô]/;
    $seen{accent_u}++   if $w =~ /[ùúû]/;
}

ok($seen{apostrophe}, 'Legacy: apostrophe forms present');
ok($seen{accent_a},    'Legacy: accented a present');
ok($seen{accent_e},    'Legacy: accented e present');
ok($seen{accent_i},    'Legacy: accented i present');
ok($seen{accent_o},    'Legacy: accented o present');
ok($seen{accent_u},    'Legacy: accented u present');

# Tokenization sampling: ensure WordIterator yields all words un-mangled
my $joined_text = join(" ", @$words[0..299]); # subset for speed
my $iter = COF::WordIterator->new($joined_text);
my %observed;
while (my $t = $iter->next) {
    my $w = ref($t) eq 'HASH' ? $t->{word} : $t;
    $observed{$w}++ if defined $w;
}

# Pick 10 representative words (covering diacritics) to assert presence
my @representative = grep { /['àáâèéêìíîòóôùúû]/ } @$words;
@representative = @representative[0..9] if @representative > 10;
# Dynamic count: rely on done_testing() only (previous early ok() calls already emitted)

for my $rw (@representative) {
    ok($observed{$rw}, "Legacy: representative word '$rw' tokenized");
}

done_testing();
