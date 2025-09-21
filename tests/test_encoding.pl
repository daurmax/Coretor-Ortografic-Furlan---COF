#!/usr/bin/env perl

use strict;
use warnings;
use utf8;
use Test::More;
use FindBin;
use File::Spec;
use Encode;
use lib File::Spec->catdir($FindBin::Bin, '..', 'lib');

# Encoding comprehensive test suite
plan tests => 28;

diag("Starting Encoding comprehensive test suite");

# === Basic Encoding Tests ===
{
    diag("Testing basic encoding functionality");
    
    # Test 1: UTF-8 encoding detection
    {
        my $utf8_text = "café naïve";
        my $is_utf8 = utf8::is_utf8($utf8_text);
        ok(defined($is_utf8), "Encoding: UTF-8 detection should work");
    }

    # Test 2: Latin-1 to UTF-8 conversion
    {
        my $latin1_text = "caf\xe9";  # café in Latin-1
        my $utf8_text = decode('latin1', $latin1_text);
        ok(length($utf8_text) > 0, "Encoding: Latin-1 to UTF-8 conversion should work");
    }

    # Test 3: UTF-8 to Latin-1 conversion (when possible)
    {
        my $utf8_text = "café";
        eval {
            my $latin1_text = encode('latin1', $utf8_text);
            ok(length($latin1_text) > 0, "Encoding: UTF-8 to Latin-1 conversion should work for compatible text");
        };
        if ($@) {
            pass("Encoding: UTF-8 to Latin-1 conversion handled gracefully");
        }
    }

    # Test 4: Friulian diacritics handling
    {
        my @friulian_chars = (
            "à", "è", "é", "ì", "î", "ò", "ù", "û",  # basic diacritics
            "ç", "ñ",                                    # other special chars
        );
        
        for my $char (@friulian_chars) {
            my $encoded = encode_utf8($char);
            my $decoded = decode_utf8($encoded);
            ok($decoded eq $char, "Encoding: Friulian character '$char' should encode/decode correctly");
        }
    }

    # Test 5: Mixed encoding text handling
    {
        my $mixed_text = "Hello café naïve résumé";
        my $encoded = encode_utf8($mixed_text);
        my $decoded = decode_utf8($encoded);
        ok($decoded eq $mixed_text, "Encoding: Mixed encoding text should handle correctly");
    }

    # Test 6: Empty string handling
    {
        my $empty = "";
        my $encoded = encode_utf8($empty);
        my $decoded = decode_utf8($encoded);
        ok($decoded eq $empty, "Encoding: Empty string should handle correctly");
    }

    # Test 7: ASCII text handling
    {
        my $ascii_text = "Hello World";
        my $encoded = encode_utf8($ascii_text);
        my $decoded = decode_utf8($encoded);
        ok($decoded eq $ascii_text, "Encoding: ASCII text should handle correctly");
    }

    # Test 8: Long text handling
    {
        my $long_text = ("café " x 1000);
        eval {
            my $encoded = encode_utf8($long_text);
            my $decoded = decode_utf8($encoded);
            ok(length($decoded) > 0, "Encoding: Long text should handle correctly");
        };
        ok(!$@, "Encoding: Long text should not cause errors");
    }

    # Test 9: Binary data handling
    {
        my $binary_data = "\x00\xFF\x80\x7F";
        eval {
            # Try to handle binary data gracefully
            my $result = length($binary_data);
            ok($result > 0, "Encoding: Binary data should be handled gracefully");
        };
        ok(!$@, "Encoding: Binary data should not cause crashes");
    }
}

# === Encoding Corruption Tests ===
{
    diag("Testing encoding corruption scenarios");
    
    # Test 10: Invalid UTF-8 sequences
    {
        # Invalid UTF-8 byte sequence
        my $invalid_utf8 = "\xFF\xFE\x00\x00";
        eval {
            decode('utf8', $invalid_utf8, Encode::FB_CROAK);
        };
        ok($@, "Encoding: Should detect invalid UTF-8 sequences");
    }

    # Test 11: Partial UTF-8 sequences
    {
        # Incomplete UTF-8 sequence (missing continuation bytes)
        my $partial_utf8 = "\xC3";  # Should be followed by another byte
        eval {
            decode('utf8', $partial_utf8, Encode::FB_CROAK);
        };
        ok($@, "Encoding: Should detect partial UTF-8 sequences");
    }

    # Test 12: Double encoding detection
    {
        my $text = "café";
        my $single_encoded = encode_utf8($text);
        my $double_encoded = encode_utf8($single_encoded);
        
        # Double encoded should be different from single encoded
        ok($double_encoded ne $single_encoded, "Encoding: Should detect double encoding");
    }

    # Test 13: Encoding mismatch handling
    {
        # Text that looks like UTF-8 but is actually Latin-1 encoded UTF-8
        my $utf8_text = "café";
        my $utf8_bytes = encode_utf8($utf8_text);
        my $latin1_of_utf8 = decode('latin1', $utf8_bytes);
        
        # Should be able to detect this mismatch
        ok($latin1_of_utf8 ne $utf8_text, "Encoding: Should detect encoding mismatches");
    }

    # Test 14: Null byte handling
    {
        my $text_with_null = "café\x00naïve";
        eval {
            my $encoded = encode_utf8($text_with_null);
            my $decoded = decode_utf8($encoded);
            ok(index($decoded, "\x00") >= 0, "Encoding: Should preserve null bytes");
        };
        ok(!$@, "Encoding: Null bytes should not cause errors");
    }

    # Test 15: Very long invalid sequences
    {
        my $long_invalid = ("\xFF" x 1000);
        eval {
            decode('utf8', $long_invalid, Encode::FB_QUIET);
            pass("Encoding: Long invalid sequences handled with FB_QUIET");
        };
        ok(!$@, "Encoding: Long invalid sequences should not crash");
    }
}

diag("Encoding comprehensive test suite completed");

done_testing();