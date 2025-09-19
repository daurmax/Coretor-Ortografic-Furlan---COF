#!/usr/bin/env perl

use strict;
use warnings;
use utf8;
use FindBin;
use Try::Tiny;
use Carp::Always;
use Wx;

use COF::Utils qw/log_error/;
use COF::App;

try {
    my $app = COF::App->new;
    $app->MainLoop;
}
catch {
    my $err = $_;
    my ($err_msg) = split /\n/, $err, 2;
    Wx::MessageBox(
        "Erôr fatâl\n[$err_msg]\n\nIl program al vignarà sierât.",
        "Erôr", Wx::wxOK() | Wx::wxICON_ERROR() );
    log_error( $err, 'cof' );
    exit(1);
};

1;
