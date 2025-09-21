package COF::Utils;

use strict;
use warnings;
use utf8;

use File::Spec;

# Optional dependency - gracefully handle if not available
our $HAS_HOMEDIR = 0;
BEGIN {
    eval { require File::HomeDir; File::HomeDir->import(); $HAS_HOMEDIR = 1; };
}

use parent qw(Exporter);
our @EXPORT_OK =
  qw(get_dict_dir get_res_dir get_user_dir log_error get_log_file);
our @EXPORT = qw(get_dict_dir get_res_dir get_user_dir log_error);

my $BASE_DICT_DIR = 'dict';
my $dict_dir;

my $BASE_RES_DIR = 'res';
my $res_dir;

my $BASE_USER_DIR = 'COF2';
my $user_dir;

my $LOG_FILE = 'log.txt';

sub get_dict_dir {
    if ( !defined $dict_dir ) {
        $dict_dir =
          File::Spec->catdir( $FindBin::RealBin, '..', $BASE_DICT_DIR );
    }
    return $dict_dir;
}

sub get_res_dir {
    if ( !defined $res_dir ) {
        $res_dir = File::Spec->catdir( $FindBin::RealBin, '..', $BASE_RES_DIR );
    }

    return $res_dir;
}

sub get_user_dir {
    my $no_die = shift;
    if ( !defined $user_dir ) {
        if ( $HAS_HOMEDIR && (my $path_prefix = File::HomeDir->my_data) ) {
            $user_dir = File::Spec->catdir( $path_prefix, $BASE_USER_DIR );
            if ( !-e $user_dir ) {
                if ( !mkdir($user_dir) ) {
                    die("No rivi a creâ la directory pai dâts utent\n")
                      if !$no_die;
                    $user_dir = undef;
                }
            }
        }
        else {
            die "La directory pai dâts utent no esist\n" if !$no_die;
        }
    }

    return $user_dir;
}

sub log_error {
    my ( $msg, $component ) = @_;
    $component ||= '';
    my $time = localtime;
    if ( my $log_file = get_log_file() ) {
        if ( open( my $fh, ">>:encoding(UTF-8)", $log_file ) ) {
            print $fh <<EOT;
[$time] ($component): $msg\n			
EOT
            close($fh);
        }
    }
}

sub get_log_file {
    if ( my $dir = get_user_dir(1) ) {
        my $log_file = File::Spec->catdir( $dir, $LOG_FILE );
        return File::Spec->catdir( $dir, $LOG_FILE );
    }
    else {
        return;
    }
}

1;
