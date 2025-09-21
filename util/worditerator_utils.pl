#!/usr/bin/env perl
# Renamed wrapper - the actual content moved from debug_worditerator.pl
# This file preserves history; main implementation below.
use strict; use warnings; use utf8;

require File::Spec;
require FindBin;
use lib File::Spec->catdir($FindBin::Bin, '..', 'lib');

# Load the original (now renamed) script content.
# For simplicity we inline the previous logic (duplicated for atomic rename), then remove old file.

# BEGIN Original content (synchronized)
use Getopt::Long;

=head1 NAME

worditerator_utils.pl - Introspect and debug COF::WordIterator behaviour

=head1 SYNOPSIS

	perl util/worditerator_utils.pl --text "l'aghe e il cjât" [--limit 10] [--raw]

=head1 DESCRIPTION

Utility di diagnostica per osservare il comportamento di COF::WordIterator:
- Scorre i token e ne mostra il contenuto
- Mostra (se presenti) informazioni di posizione tramite get_position()
- Consente anteprima con ahead() e reset

=head1 OPTIONS

	--text STR      Testo di input (obbligatorio se non si usa --file)
	--file PATH     File di testo da leggere (UTF-8)
	--limit N       Numero massimo di token da mostrare (default: 25)
	--raw           Mostra il dump grezzo della struttura token invece del solo word
	--help          Mostra questo help e termina

=cut

my $opt = { limit => 25 };
GetOptions(
	'text=s'  => \($opt->{text}),
	'file=s'  => \($opt->{file}),
	'limit=i' => \($opt->{limit}),
	'raw'     => \($opt->{raw}),
	'help'    => \($opt->{help}),
) or die "Invalid options. Use --help.\n";

if ($opt->{help}) { print_help(); exit 0; }
if (!$opt->{text} && !$opt->{file}) { die "ERROR: Provide --text or --file (see --help)\n"; }

my $input;
if ($opt->{file}) {
	open my $fh, '<:encoding(UTF-8)', $opt->{file} or die "Cannot open file $opt->{file}: $!\n";
	local $/; $input = <$fh>; close $fh;
} else { $input = $opt->{text}; }

require COF::WordIterator;
my $iter = COF::WordIterator->new($input) or die "Failed to construct WordIterator\n";

print "# WordIterator Debug\n";
print "# Limit: $opt->{limit}\n";
print "# Raw mode: " . ($opt->{raw} ? 'on' : 'off') . "\n";

my $count = 0;
while (1) {
	last if $count >= $opt->{limit};
	my $tok = $iter->next();
	last unless $tok;
	$count++;

	my ($start,$end);
	if ($iter->can('get_position')) { ($start,$end) = $iter->get_position(); }

	if ($opt->{raw}) {
		require Data::Dumper; local $Data::Dumper::Terse = 1;
		print sprintf("[%02d] %s\n", $count, Data::Dumper::Dumper($tok));
	} else {
		my $word = ref($tok) eq 'HASH' ? ($tok->{word}//'<undef>') : $tok;
		my $pos  = defined($start)&&defined($end) ? " ($start,$end)" : '';
		print sprintf("[%02d] %s%s\n", $count, $word, $pos);
	}
}

$iter->reset();
my $peek = $iter->ahead();
if ($peek) { my $w = ref($peek) eq 'HASH' ? $peek->{word} : $peek; print "# After reset ahead(): $w\n"; }
else { print "# After reset ahead(): <none>\n"; }

exit 0;

sub print_help {
	print <<'HELP';
Usage: worditerator_utils.pl --text "STRING" [options]
			 worditerator_utils.pl --file file.txt [options]

Options:
	--text STR      Testo da analizzare
	--file PATH     File di input UTF-8
	--limit N       Numero massimo token (default 25)
	--raw           Mostra struttura token completa
	--help          Questo messaggio
HELP
}

__END__

=head1 AUTHOR

COF Utilities

=cut
# END Original content
