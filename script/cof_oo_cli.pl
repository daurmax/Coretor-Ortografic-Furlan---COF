#!/usr/bin/env perl

use strict;
use warnings;
use utf8;

use Try::Tiny;
use Carp::Always;

use COF::Data;
use COF::SpellChecker;
use COF::Utils qw/log_error get_dict_dir/;

use FindBin;
use File::Spec::Functions;

use Getopt::Std;

try {
    my %opts = ();
    getopt( 'cn', \%opts );
    my $codifica = $opts{'c'} || 'utf8';
    $codifica = Encode::resolve_alias($codifica)
      || die("Codifiche no supuartade: $codifica\n");
    binmode( STDIN,  ":encoding($codifica)" );
    binmode( STDOUT, ":encoding($codifica)" );
    binmode( STDERR, ":encoding($codifica)" );
    my $maxsug = int( $opts{'n'} || 10 );

    my $data = COF::Data->new( COF::Data::make_default_args( get_dict_dir() ) );
    my $speller = COF::SpellChecker->new($data);

    $| = 1;

    while ( my $line = <STDIN> ) {
        chomp($line);
        my ( $command, $word ) = split /\s/, $line;
        if ( !$command ) {
            print "err\n";
        }
        elsif ( $command eq 'q' ) { last;
        }
        elsif ( !$word ) {
            print "err\n";
        }
        elsif ( $command eq 'c' ) { my $answer = $speller->check_word($word);
            if (   !$answer->{'ok'}
                && ( length($word) > 1 )
                && ( substr( $word, -1 ) eq '.' ) )
            {
                $answer = $speller->check_word( substr( $word, 0, -1 ) );
            }
            print $answer->{'ok'} ? "ok\n" : "no\n";
        }
        elsif ( $command eq 's' )
        { my $end_point =
              ( length($word) > 1 ) && ( substr( $word, -1 ) eq '.' );
            my $answer = $speller->check_word($word);
            if ( !$answer->{'ok'} && $end_point ) {
                $answer = $speller->check_word( substr( $word, 0, -1 ) );
            }
            if ( $answer->{'ok'} ) {
                print "ok\n";
            }
            else {
                my @sugg_ord = @{ $speller->suggest($word) };

                if ( !@sugg_ord && $end_point ) {
                    @sugg_ord =
                      @{ $speller->suggest( substr( $word, 0, -1 ) ) };
                }
                if ( @sugg_ord && $end_point ) {
                    for my $sugg (@sugg_ord) {
                        if (   ( length($word) > 1 )
                            && ( substr( $sugg, -1 ) eq '.' ) )
                        {
                            $sugg = substr( $sugg, 0, -1 );
                        }
                    }
                }

                $#sugg_ord = $maxsug - 1 if $maxsug && @sugg_ord >= $maxsug;
                print "no\t", join( ",", @sugg_ord ), "\n";
            }
        }
        else { print "err\n";
        }
    }
}
catch {
    my $err = $_;
    my ($err_msg) = split /\n/, $err, 2;
    print STDERR $err_msg, "\n";
    log_error( $err, 'cof_oo_cli' );
    exit(1);
};
