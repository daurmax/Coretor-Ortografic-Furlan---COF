#!/usr/bin/env perl
# Test core functionality con COF::DataCompat - versione compatibile
use strict;
use warnings;
use utf8;
use Test::More;
use FindBin;
use File::Spec;
use lib File::Spec->catdir($FindBin::Bin, '..', 'lib');

# Utilizza la versione compatibile invece di COF::Data originale
use COF::DataCompat;
use COF::Utils qw(get_dict_dir);

diag('Testing core functionality with COF::DataCompat - compatible version without DB_File');

# === Database Compatibility Tests ===
{
    diag('Testing database compatibility without DB_File dependency');
    
    # Test 1: Check if dictionary directory exists and is accessible
    my $dict_dir = get_dict_dir();
    ok(-d $dict_dir, "Dictionary directory exists: $dict_dir");
    
    # Check for required database files
    my @required_files = qw(words.db words.rt elisions.db errors.db frec.db);
    for my $file (@required_files) {
        my $full_path = File::Spec->catfile($dict_dir, $file);
        ok(-f $full_path, "Required database file exists: $file");
        ok(-r $full_path, "Database file is readable: $file");
    }
}

# === COF::DataCompat Object Creation Tests ===
{
    diag('Testing COF::DataCompat object creation');
    
    my $dict_dir = get_dict_dir();
    my %args = COF::DataCompat::make_default_args($dict_dir);
    
    my $data_obj;
    eval {
        $data_obj = COF::DataCompat->new(%args);
    };
    
    is($@, '', 'COF::DataCompat object creation without errors');
    isa_ok($data_obj, 'COF::DataCompat', 'Created object is correct type');
    
    # Test methods availability
    can_ok($data_obj, qw(has_radix_tree get_radix_tree has_rt_checker get_rt_checker));
    
    # Test radix tree loading (doesn't require DB_File)
    if ($data_obj->has_radix_tree()) {
        pass('RadixTree loaded successfully');
        ok($data_obj->has_rt_checker(), 'RT_Checker available');
    } else {
        diag('RadixTree not available - words.rt file may be missing');
    }
    
    # Test user dict (should be disabled in compat version)
    is($data_obj->has_user_dict(), 0, 'User dict correctly disabled in compat version');
}

# === Basic Phonetic Algorithm Test ===
{
    diag('Testing basic phonetic algorithm functionality (detailed tests in test_phonetic_algorithm.pl)');
    
    # Basic functionality test - just verify the method works
    my ($p1, $s1) = COF::DataCompat::phalg_furlan('furlan');
    ok(defined($p1) && defined($s1), 'phalg_furlan returns defined values');
    ok(length($p1) > 0 && length($s1) > 0, 'phalg_furlan returns non-empty hashes for valid input');
    
    # Test edge cases
    is_deeply([COF::DataCompat::phalg_furlan('')], ['', ''], 'Empty string handling');
    is_deeply([COF::DataCompat::phalg_furlan('   ')], ['', ''], 'Whitespace-only string handling');
}

# === Performance and Stability Tests ===
{
    diag('Testing performance and stability');
    
    # Test multiple calls
    my $word = 'furlan';
    my ($p1, $s1) = COF::DataCompat::phalg_furlan($word);
    my ($p2, $s2) = COF::DataCompat::phalg_furlan($word);
    
    is($p1, $p2, 'Consistent results - primo');
    is($s1, $s2, 'Consistent results - secondo');
    
    # Test with special characters
    my ($pa, $sa) = COF::DataCompat::phalg_furlan('àèìòù');
    ok(length($pa) > 0, 'Handles accented characters');
    ok(length($sa) > 0, 'Handles accented characters - secondo');
}

# === Compatibility Warning Tests ===
{
    diag('Testing compatibility warnings and limitations');
    
    my $dict_dir = get_dict_dir();
    my %args = COF::DataCompat::make_default_args($dict_dir);
    my $data_obj = COF::DataCompat->new(%args);
    
    # These should return default values or warnings
    is($data_obj->change_user_dict(), 1, 'change_user_dict returns compatibility placeholder');
    is($data_obj->delete_user_dict(), 1, 'delete_user_dict returns compatibility placeholder');
}

done_testing();

__END__

=head1 NAME

test_core_functionality_compat.pl - Test compatibilità core COF senza DB_File

=head1 DESCRIPTION

Questo test verifica la funzionalità core di COF utilizzando COF::DataCompat,
la versione compatibile che non richiede BerkeleyDB/DB_File.

=head2 TEST INCLUSI

=over 4

=item * Creazione oggetti COF::DataCompat

=item * Algoritmo fonetico completo (identico all'originale)

=item * Gestione RadixTree (se disponibile)

=item * Test compatibilità e limitazioni

=item * Test performance e stabilità

=back

=cut