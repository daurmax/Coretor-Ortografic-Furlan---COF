#!/usr/bin/env perl

# DEBUG VERSION of cof_oo_cli.pl
# This version outputs timestamped diagnostic logs to STDERR
# Useful for debugging performance issues and identifying hang points.
#
# Log format: [TIMESTAMP] [TAG] message
# Example: [2025-11-28 10:15:30.123] [INIT] COF::Data loaded successfully

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
use Time::HiRes qw(gettimeofday tv_interval time);
use POSIX qw(strftime);

# Progress counter for batch operations
my $command_count = 0;
my $progress_interval = 100;  # Log every N commands

sub debug_log {
    my ($tag, $message) = @_;
    my ($sec, $usec) = gettimeofday();
    my $timestamp = strftime("%Y-%m-%d %H:%M:%S", localtime($sec));
    $timestamp .= sprintf(".%03d", int($usec / 1000));
    print STDERR "[$timestamp] [$tag] $message\n";
    # Force flush STDERR
    select STDERR; $| = 1; select STDOUT;
}

sub elapsed_ms {
    my ($start_time) = @_;
    return sprintf("%.1f", (time() - $start_time) * 1000);
}

try {
    debug_log("STARTUP", "cof_oo_cli_debug.pl starting...");
    my $startup_time = time();

    my %opts = ();
    getopt( 'cn', \%opts );
    my $codifica = $opts{'c'} || 'utf8';
    $codifica = Encode::resolve_alias($codifica)
      || die("Codifiche no supuartade: $codifica\n");
    binmode( STDIN,  ":encoding($codifica)" );
    binmode( STDOUT, ":encoding($codifica)" );
    binmode( STDERR, ":encoding($codifica)" );
    my $maxsug = int( $opts{'n'} || 10 );

    debug_log("CONFIG", "encoding=$codifica, max_suggestions=$maxsug");

    # Load COF::Data (this is often slow)
    debug_log("INIT", "Loading COF::Data...");
    my $data_start = time();
    my $data = COF::Data->new( COF::Data::make_default_args( get_dict_dir() ) );
    debug_log("INIT", "COF::Data loaded in " . elapsed_ms($data_start) . "ms");

    # Create SpellChecker
    debug_log("INIT", "Creating COF::SpellChecker...");
    my $speller_start = time();
    my $speller = COF::SpellChecker->new($data);
    debug_log("INIT", "COF::SpellChecker created in " . elapsed_ms($speller_start) . "ms");

    debug_log("READY", "Initialization complete in " . elapsed_ms($startup_time) . "ms. Waiting for commands...");

    $| = 1;

    while ( my $line = <STDIN> ) {
        chomp($line);
        $command_count++;
        
        my ( $command, $word ) = split /\s/, $line;
        
        # Log progress every N commands
        if ($command_count % $progress_interval == 0) {
            debug_log("PROGRESS", "Processed $command_count commands");
        }
        
        if ( !$command ) {
            print "err\n";
        }
        elsif ( $command eq 'q' ) {
            debug_log("CMD", "Quit command received after $command_count commands");
            last;
        }
        elsif ( !$word ) {
            print "err\n";
        }
        elsif ( $command eq 'c' ) {
            my $answer = $speller->check_word($word);
            if (   !$answer->{'ok'}
                && ( length($word) > 1 )
                && ( substr( $word, -1 ) eq '.' ) )
            {
                $answer = $speller->check_word( substr( $word, 0, -1 ) );
            }
            print $answer->{'ok'} ? "ok\n" : "no\n";
        }
        elsif ( $command eq 's' ) {
            my $suggest_start = time();
            
            my $end_point =
              ( length($word) > 1 ) && ( substr( $word, -1 ) eq '.' );
            my $answer = $speller->check_word($word);
            if ( !$answer->{'ok'} && $end_point ) {
                $answer = $speller->check_word( substr( $word, 0, -1 ) );
            }
            if ( $answer->{'ok'} ) {
                print "ok\n";
                debug_log("SUGGEST", "word='$word' result=ok (correct) time=" . elapsed_ms($suggest_start) . "ms");
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
                my $num_suggestions = scalar(@sugg_ord);
                print "no\t", join( ",", @sugg_ord ), "\n";
                debug_log("SUGGEST", "word='$word' result=no suggestions=$num_suggestions time=" . elapsed_ms($suggest_start) . "ms");
            }
        }
        else {
            print "err\n";
        }
    }
    
    debug_log("SHUTDOWN", "Exiting after processing $command_count total commands");
}
catch {
    my $err = $_;
    my ($err_msg) = split /\n/, $err, 2;
    debug_log("ERROR", "Exception: $err_msg");
    print STDERR $err_msg, "\n";
    log_error( $err, 'cof_oo_cli_debug' );
    exit(1);
};
