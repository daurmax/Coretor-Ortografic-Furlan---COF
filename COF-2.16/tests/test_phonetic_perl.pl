#!/usr/bin/perl
use strict;
use warnings;
use lib './lib';
use COF::Data;

# Test cases ported from Python/C# tests plus additional comprehensive cases
my @test_cases = (
    # Original test cases from Python
    "cjatâ",
    "'savote", 
    "çavatis",
    "diretamentri",
    "sdrumâ",
    "rinfuarçadis",
    "marilenghe",
    "mandi",
    "dindi",
    
    # Additional test cases to cover edge cases
    "gjat",           # j handling
    "fuee",           # vowel sequences  
    "ai",             # diphthong ai
    "ei",             # diphthong ei
    "ou",             # diphthong ou
    "oi",             # diphthong oi
    "vu",             # vu sequence
    "tane",           # start with t
    "dane",           # start with d
    "bat",            # internal t
    "bad",            # internal d
    "cjjar",          # multiple j
    "fuje",           # j in middle
    "che",            # che -> chi
    "sciençe",        # sci handling
    "leng",           # leng -> X
    "lingu",          # lingu -> X
    "amentri",        # amentri -> O
    "ementi",         # ementi -> O
    "uintri",         # uintri -> W
    "ontra",          # ontra -> W
    "ur",             # ur -> Y
    "uar",            # uar -> Y
    "or",             # or -> Y
    "'s",             # apostrophe s
    "'n",             # apostrophe n
    "ins",            # ins ending
    "in",             # in ending
    "mn",             # mn -> 5
    "nm",             # nm -> 5
    "m",              # m -> 5
    "n",              # n -> 5
    "er",             # er -> 2
    "ar",             # ar -> 2
    "colegb",         # b ending -> 3
    "stopp",          # p ending -> 3
    "altrev",         # v ending -> 4
    "altref",         # f ending -> 4
);

print "# Perl Phonetic Algorithm Test Results\n";
print "# Format: word -> (hash1, hash2)\n";
print "\n";

foreach my $word (@test_cases) {
    my ($hash1, $hash2) = COF::Data::phalg_furlan($word);
    printf "%-20s -> (\"%s\", \"%s\")\n", $word, $hash1, $hash2;
}

print "\n# Test completed\n";