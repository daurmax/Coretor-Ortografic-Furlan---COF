#!/usr/bin/env perl

use strict;
use warnings;
use utf8;
use Test::More;
use FindBin;
use File::Spec;
use lib File::Spec->catdir( $FindBin::Bin, '..', 'lib' );

use COF::Data;
use COF::SpellChecker;
use COF::Utils qw(get_dict_dir);

plan tests => 50;

my $dict_dir = get_dict_dir();
ok( -d $dict_dir, "Dictionary directory exists: $dict_dir" );

my @required_files = qw(words.db words.rt elisions.db errors.db frec.db);
for my $file (@required_files) {
    my $full_path = File::Spec->catfile( $dict_dir, $file );
    ok( -f $full_path, "Database file exists: $file" );
    ok( -r $full_path, "Database file readable: $file" );
}

my $data;
eval { $data = COF::Data->new( COF::Data::make_default_args($dict_dir) ); };
ok( !$@, 'COF::Data creation succeeded' );
ok( defined $data, 'COF::Data object defined' );
isa_ok( $data, 'COF::Data', 'COF::Data type check' );

my $spellchecker;
eval { $spellchecker = COF::SpellChecker->new($data); };
ok( !$@, 'COF::SpellChecker creation succeeded' );
ok( defined $spellchecker, 'COF::SpellChecker object defined' );
isa_ok( $spellchecker, 'COF::SpellChecker', 'COF::SpellChecker type check' );

my $furla_ref = $spellchecker->suggest('furla');
ok( defined $furla_ref, "suggest('furla') returned value" );
is( ref $furla_ref, 'ARRAY', "suggest('furla') returns array reference" );
ok( @$furla_ref > 0, "'furla' produced at least one suggestion" );
is( $furla_ref->[0], 'furlan', "First suggestion for 'furla' is 'furlan'" );

my @cjasa = suggestions_for('cjasa');
is( $cjasa[0], 'cjase', "First suggestion for 'cjasa' is 'cjase'" );

my @nonsense = suggestions_for('blablabla');
is( scalar(@nonsense), 0, "'blablabla' returns no suggestions" );

sub suggestions_for {
    my ($word) = @_;
    my $res = eval { $spellchecker->suggest($word) };
    return () if $@ || !$res || ref($res) ne 'ARRAY';
    return @$res;
}

sub first_suggestion {
    my ($word) = @_;
    my @suggestions = suggestions_for($word);
    return $suggestions[0];
}

is( first_suggestion("l'aghe"), 'la aghe', "Elision preserved for l'aghe" );
is( first_suggestion("un'ore"), 'une ore', "Elision preserved for un'ore" );
is( first_suggestion('lengha'), 'lenghe', "Phonetic correction for 'lengha'" );
is( first_suggestion('ostaria'), 'ostarie', "Phonetic correction for 'ostaria'" );
is( first_suggestion('anell'), 'anel', "Consonant doubling corrected for 'anell'" );
is( first_suggestion('cjol'), 'cjol', "Known word preserved for 'cjol'" );
is( first_suggestion('Furlan'), 'Furlan', "Case preserved for 'Furlan'" );
is( first_suggestion('FURLAN'), 'FURLAN', "Case preserved for 'FURLAN'" );
is( first_suggestion('furlan'), 'furlan', "Lowercase word kept for 'furlan'" );
is( first_suggestion('furlans'), 'furlans', "Plural preserved for 'furlans'" );
is( first_suggestion('furlane'), 'furlane', "Feminine preserved for 'furlane'" );
is( first_suggestion('furlanis'), 'furlanis', "Plural feminine preserved for 'furlanis'" );
is( first_suggestion('fur'), 'fûr', "Friulian circumflex preserved for 'fur'" );
is( first_suggestion('plui'), 'plui', "Comparative preserved for 'plui'" );
is( first_suggestion('prossim'), 'prossim', "Frequency-weighted priority for 'prossim'" );
is( first_suggestion('gjave'), 'gjave', "Friulian gj sequence handled for 'gjave'" );
is( first_suggestion('aghe'), 'aghe', "Friulian ghe cluster handled for 'aghe'" );
is( first_suggestion('bas'), 'bas', "Short base form preserved for 'bas'" );
is( first_suggestion('grant'), 'grant', "Ranking maintained for 'grant'" );
is( first_suggestion('alt'), 'alt', "Short consonant cluster preserved for 'alt'" );
is( first_suggestion('a'), 'a', "Single letter preserved for 'a'" );
is( first_suggestion('ab'), 'a', "Nearest neighbour suggested for 'ab'" );
is( first_suggestion('fu'), 'su', "Closest phonetic match for 'fu'" );
is( first_suggestion('cjase-parol'), 'cjase paron', "Hyphen decomposition handled for 'cjase-parol'" );

{
    my @cjoll = suggestions_for('cjoll');
    my $has_cjol = grep { $_ eq 'cjol' } @cjoll;
    ok( $has_cjol, "Suggestion list for 'cjoll' contains 'cjol'" );
}

{
    my @first = suggestions_for('lengha');
    my @second = suggestions_for('lengha');
    is_deeply( \@first, \@second, "Suggestions for 'lengha' are stable between calls" );
}

{
    my @first = suggestions_for('furla');
    my @second = suggestions_for('furla');
    is_deeply( \@first, \@second, "Suggestions for 'furla' are stable between calls" );
}

done_testing();
