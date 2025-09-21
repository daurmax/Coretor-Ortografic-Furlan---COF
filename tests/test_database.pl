#!/usr/bin/env perl

use strict;
use warnings;
use utf8;
use Test::More;
use FindBin;
use File::Spec;
use File::Temp qw(tempdir tempfile);
BEGIN {
    eval { require DB_File; 1 } or do {
        require Test::More;
        Test::More::plan(skip_all => 'DB_File not available; skipping Database tests');
    };
}
use DB_File;
use Fcntl qw(:DEFAULT :flock);
use lib File::Spec->catdir($FindBin::Bin, '..', 'lib');
use COF::Data;

diag('Starting Database refactored test suite');

# === Database Failure Tests ===
{
    diag("Testing Database failure scenarios");
    
    # 1. Missing dictionary directory
    {
        my $nonexistent_dir = File::Spec->catdir($FindBin::Bin, 'THIS_PATH_DOES_NOT_EXIST');
        my $err;
        eval { COF::Data->new(COF::Data::make_default_args($nonexistent_dir)); } or $err = $@;
        like($err, qr/No rivi a vierzi diz default|No such file/i, 'Missing dir: dies with expected message');
    }

    # 2. Empty directory
    {
        my $empty_dir = tempdir(CLEANUP => 1);
        my $err;
        eval { COF::Data->new(COF::Data::make_default_args($empty_dir)); } or $err = $@;
        like($err, qr/No rivi a vierzi diz default|No such file/i, 'Empty dir: fails to open default words.db');
    }

    # 3. Corrupted words.db
    {
        my $temp_dir = tempdir(CLEANUP => 1);
        my $words_path = File::Spec->catfile($temp_dir, 'words.db');
        open my $fh, '>', $words_path or skip 'Cannot create words.db', 1;
        print $fh "CORRUPT\x00\xFF" x 50;
        close $fh;
        my $err;
        eval { COF::Data->new(COF::Data::make_default_args($temp_dir)); } or $err = $@;
        ok($err, 'Corrupted words.db: constructor dies');
    }

    # 4. Valid initialization (shared dict dir)
    {
        my $dict_dir = File::Spec->catdir($FindBin::Bin, '..', 'dict');
        ok(-d $dict_dir, 'Dict directory exists');
        my $data;
        my $err;
        eval { $data = COF::Data->new(COF::Data::make_default_args($dict_dir)); 1 } or $err = $@;
        ok(!$err && $data, 'Valid init returns object');
        ok($data->get_words_ph && %{ $data->get_words_ph } > 0, 'words_ph hash populated');
        ok($data->get_words_rt, 'words_rt (radix) object present');
    }

    # 5. Multiple instances
    {
        my $dict_dir = File::Spec->catdir($FindBin::Bin, '..', 'dict');
        my ($d1,$d2,$err);
        eval {
            $d1 = COF::Data->new(COF::Data::make_default_args($dict_dir));
            $d2 = COF::Data->new(COF::Data::make_default_args($dict_dir));
            1;
        } or $err = $@;
        ok(!$err && $d1 && $d2, 'Multiple instances can be created');
    }
}

{   # === Basic DB_File lifecycle (sanity) ===
    my $temp_dir = tempdir(CLEANUP => 1);
    my $db_file  = File::Spec->catfile($temp_dir, 'test.db');
    eval {
        tie(my %hash, 'DB_File', $db_file, O_CREAT|O_RDWR, 0644) or die $!;
        $hash{hello} = 'world';
        untie %hash;
        tie(%hash, 'DB_File', $db_file, O_RDONLY, 0644) or die $!;
        is($hash{hello}, 'world', 'DB_File: value persisted');
        untie %hash;
    };
    ok(!$@, 'DB_File lifecycle without errors');
}

{   # === Key-Value mini-store ===
    my $temp_dir = tempdir(CLEANUP => 1);
    my $test_db  = File::Spec->catfile($temp_dir, 'kv.db');
    tie(my %kv, 'DB_File', $test_db, O_CREAT|O_RDWR, 0644) or die $!;
    %kv = (word1=>'d1', word2=>'d2', word3=>'d3');
    untie %kv;
    tie(%kv, 'DB_File', $test_db, O_RDONLY, 0644) or die $!;
    is($kv{word2}, 'd2', 'KV: retrieve existing');
    ok(!defined $kv{nope}, 'KV: missing key returns undef');
    my @keys = sort keys %kv;
    ok(@keys == 3, 'KV: 3 keys stored');
    untie %kv;
}

diag('Database refactored test suite completed');

done_testing();