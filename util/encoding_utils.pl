#!/usr/bin/perl
use strict;
use warnings;
use utf8;
use Encode qw(encode);
use Getopt::Long qw(GetOptions);
use Pod::Usage;
use FindBin;
use File::Spec;
use lib File::Spec->catdir($FindBin::Bin, '..', 'lib');
use COF::Data;
use COF::SpellChecker;

binmode(STDOUT, ':utf8');

my $help = 0;
my $word;
my $suggest = '';
my $from_file = '';
my $show_hex = 1;
my $show_unicode = 1;
my $show_index = 1;
my $list_only = 0;    # if true, prints only the words

GetOptions(
    'help|h'       => \$help,
    'word|w=s'     => \$word,
    'suggest|s=s'  => \$suggest,   # run spellchecker suggestions for this word
    'file|f=s'     => \$from_file,  # read words (one per line)
    'nohex'        => sub { $show_hex = 0 },
    'nounicode'    => sub { $show_unicode = 0 },
    'noindex'      => sub { $show_index = 0 },
    'list'         => sub { $list_only = 1 },
) or pod2usage(2);

pod2usage(1) if $help;

my @words;
if ($from_file) {
    open my $fh, '<:encoding(UTF-8)', $from_file or die "Cannot open file '$from_file': $!";
    while (my $line = <$fh>) {
        chomp $line;
        next unless length $line;
        push @words, $line;
    }
    close $fh;
}

if ($suggest) {
    my $dict_dir = File::Spec->catdir($FindBin::Bin, '..', 'dict');
    my $data = COF::Data->new(COF::Data::make_default_args($dict_dir));
    my $sc = COF::SpellChecker->new($data);
    my $sug_ref = $sc->suggest($suggest);
    @words = $sug_ref ? @$sug_ref : ();
}

push @words, $word if defined $word && length $word;

pod2usage("No words provided. Use --help for usage.") unless @words;

if ($list_only) {
    print join("\n", @words), "\n";
    exit 0;
}

print "=== ENCODING DEBUG ===\n";
print "Items: " . scalar(@words) . "\n\n";

for my $i (0..$#words) {
    my $w = $words[$i];
    my $hex = $show_hex ? unpack('H*', encode('utf8', $w)) : '';
    my $chars = $show_unicode ? join(' ', map { sprintf("U+%04X", ord($_)) } split //, $w) : '';

    my @cols;
    push @cols, sprintf("%2d", $i+1) if $show_index;
    push @cols, sprintf("%s", $w);
    push @cols, sprintf("UTF-8: %s", $hex) if $show_hex;
    push @cols, sprintf("Unicode: %s", $chars) if $show_unicode;

    print join(' | ', @cols), "\n";
}

# Character summary for interesting characters
my %interesting = map { $_ => 1 } (qw(þ ç));
print "\n=== CHARACTER SUMMARY ===\n";
for my $w (@words) {
    for my $ch (split //, $w) {
        next unless exists $interesting{$ch};
        printf "Found in '%s': %s (U+%04X, UTF-8: %s)\n", $w, $ch, ord($ch), unpack('H*', encode('utf8', $ch));
    }
}

__END__

=head1 NAME

encoding_utils.pl - Investigate UTF-8 / Unicode encodings for words

=head1 SYNOPSIS

perl encoding_utils.pl [--suggest WORD] [--word WORD] [--file FILE] [--list] [--nohex] [--nounicode]

=head1 OPTIONS

- --suggest, -s WORD    Run spellchecker and inspect suggestions for WORD
- --word, -w WORD       Inspect the given WORD directly
- --file, -f FILE       Read words (one per line) from FILE (UTF-8)
- --list                Print only the list of words (one per line)
- --nohex               Do not show UTF-8 hex bytes
- --nounicode           Do not show Unicode code points
- --noindex             Do not show numeric index in output
- --help, -h            Show brief help

=head1 EXAMPLES

perl encoding_utils.pl --suggest cjupe
perl encoding_utils.pl --word 'þope'
perl encoding_utils.pl --file words.txt --nohex

=cut