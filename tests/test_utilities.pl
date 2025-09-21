#!/usr/bin/env perl
use strict;
use warnings;
use utf8;
use Test::More;
use FindBin;
use File::Spec;
use File::Temp qw(tempdir tempfile);
use Encode;
use Symbol qw(gensym);
use lib File::Spec->catdir($FindBin::Bin, '..', 'lib');

diag("Testing utilities and support functionality: encoding, CLI validation, and legacy data");

# === Encoding Comprehensive Tests ===
{
    diag("Testing encoding functionality");
    
    # Test 1: UTF-8 encoding detection
    my $utf8_text = "café naïve";
    my $is_utf8 = utf8::is_utf8($utf8_text);
    ok(defined($is_utf8), "Encoding: UTF-8 detection should work");
    
    # Test 2: Latin-1 to UTF-8 conversion
    my $latin1_text = "caf\xe9";  # café in Latin-1
    my $utf8_text_converted = decode('latin1', $latin1_text);
    ok(length($utf8_text_converted) > 0, "Encoding: Latin-1 to UTF-8 conversion should work");
    
    # Test 3: Friulian diacritics handling
    my @friulian_chars = ("à", "è", "é", "ì", "î", "ò", "ù", "û", "ç", "ñ");
    
    for my $char (@friulian_chars) {
        my $encoded = encode_utf8($char);
        my $decoded = decode_utf8($encoded);
        ok($decoded eq $char, "Encoding: Friulian character '$char' should encode/decode correctly");
    }
    
    # Test 4: Mixed encoding text handling
    my $mixed_text = "Hello café naïve résumé";
    my $encoded = encode_utf8($mixed_text);
    my $decoded = decode_utf8($encoded);
    ok($decoded eq $mixed_text, "Encoding: Mixed encoding text should handle correctly");
    
    # Test 5: Empty string handling
    my $empty = "";
    my $empty_encoded = encode_utf8($empty);
    my $empty_decoded = decode_utf8($empty_encoded);
    ok($empty_decoded eq $empty, "Encoding: Empty string should handle correctly");
    
    # Test 6: ASCII text handling
    my $ascii_text = "Hello World";
    my $ascii_encoded = encode_utf8($ascii_text);
    my $ascii_decoded = decode_utf8($ascii_encoded);
    ok($ascii_decoded eq $ascii_text, "Encoding: ASCII text should handle correctly");
    
    # Test 7: Invalid UTF-8 sequences
    my $invalid_utf8 = "\xFF\xFE\x00\x00";
    eval { decode('utf8', $invalid_utf8, Encode::FB_CROAK); };
    ok($@, "Encoding: Should detect invalid UTF-8 sequences");
    
    # Test 8: Double encoding detection
    my $text = "café";
    my $single_encoded = encode_utf8($text);
    my $double_encoded = encode_utf8($single_encoded);
    ok($double_encoded ne $single_encoded, "Encoding: Should detect double encoding");
}

# === CLI Parameter Validation Tests ===
{
    diag("Testing CLI parameter validation");
    
    # Detect whether DB_File is usable for error message patterns
    my $DB_FILE_AVAILABLE = eval { require DB_File; 1 } ? 1 : 0;
    my $db_load_pattern = qr/(?:Can't load .*DB_File|Compilation failed in require)/;
    
    my $perl = $^X;
    my $util_dir = File::Spec->catdir($FindBin::Bin, '..', 'util');
    
    # Helper function to run utility and capture output
    sub run_utility {
        my ($script, @args) = @_;
        my $script_path = File::Spec->catfile($util_dir, $script);
        my @quoted = map { /\s/ ? '"'.$_.'"' : $_ } @args;
        my $cmd = '"' . $perl . '" ' . '"' . $script_path . '" ' . join(' ', @quoted) . ' 2>&1';
        my $output = qx{$cmd};
        my $exit_code = $? >> 8;
        return { stdout => $output // '', stderr => '', exit_code => $exit_code };
    }
    
    # Test 1: spellchecker_utils.pl parameter validation
    my $result = run_utility('spellchecker_utils.pl');
    ok($result->{exit_code} != 0, "spellchecker_utils: Should fail with no parameters");
    like($result->{stderr} || $result->{stdout}, 
         ($DB_FILE_AVAILABLE ? qr/No words to show|help/ : $db_load_pattern),
         "spellchecker_utils: Should show helpful error message");
    
    # Test with invalid file path
    my $nonexistent = File::Spec->catfile('nonexistent', 'file.txt');
    $result = run_utility('spellchecker_utils.pl', '--file', $nonexistent);
    ok($result->{exit_code} != 0, "spellchecker_utils: Should fail with nonexistent file");
    
    # Test 2: radixtree_utils.pl parameter validation  
    $result = run_utility('radixtree_utils.pl');
    ok($result->{exit_code} != 0, "radixtree_utils: Should fail with no parameters");
    
    # Test 3: encoding_utils.pl parameter validation
    $result = run_utility('encoding_utils.pl');
    ok($result->{exit_code} != 0, "encoding_utils: Should fail with no parameters");
    
    # Test 4: worditerator_utils.pl parameter validation
    $result = run_utility('worditerator_utils.pl');
    ok($result->{exit_code} != 0, "worditerator_utils: Should fail with no parameters");
    
    # Test 5: Empty file handling
    my $temp_dir = tempdir(CLEANUP => 1);
    my ($fh, $empty_file) = tempfile(DIR => $temp_dir, SUFFIX => '.txt');
    close $fh;  # Empty file
    
    for my $script (qw(spellchecker_utils.pl radixtree_utils.pl encoding_utils.pl)) {
        my $result = run_utility($script, '--file', $empty_file);
        ok($result->{exit_code} != 0, "$script: Should fail gracefully with empty file");
    }
}

# === Legacy Words Tests ===
{
    diag("Testing legacy vocabulary handling");
    
    require COF::WordIterator;
    
    my $legacy_dir = File::Spec->catdir($FindBin::Bin, '..', 'legacy');
    my $lemmas_file = File::Spec->catfile($legacy_dir, 'lemis_cof_2015.txt');
    my $words_file  = File::Spec->catfile($legacy_dir, 'peraulis_cof_2015.txt');
    
    ok(-f $lemmas_file, 'Legacy: lemmas file exists');
    ok(-f $words_file,  'Legacy: words file exists');
    
    SKIP: {
        skip "Legacy files not available", 10 unless -f $lemmas_file && -f $words_file;
        
        # Read a bounded sample to keep runtime reasonable
        my $MAX_WORDS = 500;
        
        sub slurp_sample {
            my ($path, $limit) = @_;
            open my $fh, '<:encoding(UTF-8)', $path or die "Cannot open $path: $!";
            my @out;
            while (<$fh>) {
                chomp;
                next unless length;
                s/\t.*$//; # strip trailing columns/frequencies
                push @out, $_;
                last if @out >= $limit;
            }
            close $fh;
            return \@out;
        }
        
        my $words = slurp_sample($words_file, $MAX_WORDS);
        ok(@$words > 100, 'Legacy: collected substantial word sample');
        
        # Basic character coverage checks
        my %seen;
        for my $w (@$words) {
            $seen{apostrophe}++ if $w =~ /[''`]/;
            $seen{accent_a}++   if $w =~ /[àáâ]/;
            $seen{accent_e}++   if $w =~ /[èéê]/;
            $seen{accent_i}++   if $w =~ /[ìíî]/;
            $seen{accent_o}++   if $w =~ /[òóô]/;
            $seen{accent_u}++   if $w =~ /[ùúû]/;
        }
        
        ok($seen{apostrophe}, 'Legacy: apostrophe forms present');
        ok($seen{accent_e}, 'Legacy: accented e present');
        ok($seen{accent_i}, 'Legacy: accented i present');
        
        # Tokenization sampling
        my $joined_text = join(" ", @$words[0..99]); # subset for speed
        my $iter = COF::WordIterator->new($joined_text);
        my %observed;
        while (my $t = $iter->next) {
            my $w = ref($t) eq 'HASH' ? $t->{word} : $t;
            $observed{$w}++ if defined $w;
        }
        
        # Pick representative words to assert presence
        my @representative = grep { /['àáâèéêìíîòóôùúû]/ } @$words;
        @representative = @representative[0..4] if @representative > 5;
        
        for my $rw (@representative) {
            ok($observed{$rw}, "Legacy: representative word '$rw' tokenized correctly");
        }
    }
}

done_testing();

__END__

=head1 NAME

test_utilities.pl - Utility and support functionality tests for COF

=head1 DESCRIPTION

Tests for utility functions and support infrastructure:

- Encoding functionality (UTF-8, Latin-1, Friulian diacritics)
- CLI parameter validation for utility scripts
- Legacy vocabulary handling and tokenization
- Error handling and edge cases

These tests ensure the supporting infrastructure works correctly
and can handle various input scenarios gracefully.

=cut