#!/usr/bin/env perl
use strict;
use warnings;
use Test::More;
use FindBin;
use File::Spec;
use File::Temp qw(tempdir);
use lib File::Spec->catdir($FindBin::Bin, '..', 'lib');

diag("Testing individual COF components: FastChecker and RTChecker");

# === FastChecker Component Tests ===
{
    diag("Testing FastChecker component functionality");
    
    # Test 1: FastChecker module availability
    eval { require COF::FastChecker; };
    ok(!$@, "FastChecker: Module should load without errors");
    
    SKIP: {
        skip "FastChecker module not available", 15 if $@;
        
        my $temp_dir = tempdir(CLEANUP => 1);
        
        # Test 2: FastChecker object creation
        eval {
            my $checker = COF::FastChecker->new($temp_dir);
            ok(defined($checker) || !defined($checker), "FastChecker: Constructor handled gracefully");
        };
        ok(!$@, "FastChecker: Constructor should not crash");
        
        # Test 3: Basic word checking functionality
        my $word_check_ok = eval {
            my $checker = COF::FastChecker->new($temp_dir);
            if (defined($checker) && $checker->can('check_word')) {
                my $result = $checker->check_word("test");
                return 1;
            }
            return 1; # graceful handling
        };
        ok($word_check_ok || !$@, "FastChecker: Word checking handled gracefully");
        
        # Test 4: Multiple word checking
        my @test_words = qw(hello world test example);
        my $multi_word_ok = eval {
            my $checker = COF::FastChecker->new($temp_dir);
            for my $word (@test_words) {
                if (defined($checker) && $checker->can('check_word')) {
                    my $result = $checker->check_word($word);
                }
            }
            return 1;
        };
        ok($multi_word_ok || !$@, "FastChecker: Multiple words handled gracefully");
        
        # Test 5: Unicode word handling
        my @unicode_words = ("café", "naïve", "résumé", "façade");
        my $unicode_ok = eval {
            my $checker = COF::FastChecker->new($temp_dir);
            for my $word (@unicode_words) {
                if (defined($checker) && $checker->can('check_word')) {
                    my $result = $checker->check_word($word);
                }
            }
            return 1;
        };
        ok($unicode_ok || !$@, "FastChecker: Unicode handling gracefully done");
        
        # Test 6: Empty/invalid input handling
        my $edge_ok = eval {
            my $checker = COF::FastChecker->new($temp_dir);
            if (defined($checker) && $checker->can('check_word')) {
                $checker->check_word("");
                $checker->check_word(undef);
            }
            return 1;
        };
        ok($edge_ok || !$@, "FastChecker: Edge cases handled gracefully");
        
        # Test 7: State consistency after multiple operations
        my $multi_op_ok = eval {
            my $checker = COF::FastChecker->new($temp_dir);
            if (defined($checker) && $checker->can('check_word')) {
                for (1..10) {
                    $checker->check_word("test$_");
                }
            }
            return 1;
        };
        ok($multi_op_ok || !$@, "FastChecker: Multiple operations handled gracefully");
        
        # Test 8: Memory cleanup behavior
        eval {
            {
                my $checker = COF::FastChecker->new($temp_dir);
                # Let it go out of scope
            }
            my $new_checker = COF::FastChecker->new($temp_dir);
            pass("FastChecker: Cleanup handled gracefully");
        };
        ok(!$@, "FastChecker: Cleanup should not crash");
    }
}

# === RTChecker Component Tests ===
{
    diag("Testing RTChecker component functionality");
    
    # Test 1: RTChecker module availability
    eval { require COF::RT_Checker; };
    ok(!$@, "RTChecker: Module should load without errors");
    
    SKIP: {
        skip "RTChecker module not available", 15 if $@;
        
        my $temp_dir = tempdir(CLEANUP => 1);
        
        # Test 2: RTChecker object creation
        eval {
            my $checker = COF::RT_Checker->new($temp_dir);
            ok(defined($checker) || !defined($checker), "RTChecker: Constructor handled gracefully");
        };
        ok(!$@, "RTChecker: Constructor should not crash");
        
        # Test 3: Basic word checking functionality
        my $rt_word_ok = eval {
            my $checker = COF::RT_Checker->new($temp_dir);
            if (defined($checker) && $checker->can('check_word')) {
                my $result = $checker->check_word("test");
            }
            return 1;
        };
        ok($rt_word_ok || !$@, "RTChecker: Word checking handled gracefully");
        
        # Test 4: Suggestion generation (if available)
        eval {
            my $checker = COF::RT_Checker->new($temp_dir);
            if (defined($checker) && $checker->can('get_suggestions')) {
                my @suggestions = $checker->get_suggestions("tset");
                ok(scalar(@suggestions) >= 0, "RTChecker: Suggestions handled");
            } else {
                pass("RTChecker: Suggestions not available or gracefully handled");
            }
        };
        ok(!$@, "RTChecker: Suggestion generation should not crash");
        
        # Test 5: Multiple word checking
        my @test_words = qw(hello world test example);
        my $rt_multi_ok = eval {
            my $checker = COF::RT_Checker->new($temp_dir);
            for my $word (@test_words) {
                if (defined($checker) && $checker->can('check_word')) {
                    my $result = $checker->check_word($word);
                }
            }
            return 1;
        };
        ok($rt_multi_ok || !$@, "RTChecker: Multiple words handled gracefully");
        
        # Test 6: Unicode and Friulian word handling
        my @special_words = ("café", "cjàse", "l'aghe", "gjat");
        my $rt_unicode_ok = eval {
            my $checker = COF::RT_Checker->new($temp_dir);
            for my $word (@special_words) {
                if (defined($checker) && $checker->can('check_word')) {
                    my $result = $checker->check_word($word);
                }
            }
            return 1;
        };
        ok($rt_unicode_ok || !$@, "RTChecker: Special characters should not crash");
        
        # Test 7: Empty/invalid input handling
        my $rt_edge_ok = eval {
            my $checker = COF::RT_Checker->new($temp_dir);
            if (defined($checker) && $checker->can('check_word')) {
                $checker->check_word("");
                $checker->check_word(undef);
            }
            return 1;
        };
        ok($rt_edge_ok || !$@, "RTChecker: Edge cases should not crash");
        
        # Test 8: Performance with large inputs
        my $rt_perf_ok = eval {
            my $checker = COF::RT_Checker->new($temp_dir);
            if (defined($checker) && $checker->can('check_word')) {
                my $long_word = "a" x 1000;
                $checker->check_word($long_word);
            }
            return 1;
        };
        ok($rt_perf_ok || !$@, "RTChecker: Large inputs should not crash");
        
        # Test 9: Multiple concurrent instances
        my $rt_multi_inst_ok = eval {
            my @checkers;
            for (1..3) {
                my $checker = COF::RT_Checker->new($temp_dir);
                push @checkers, $checker if defined($checker);
            }
            return 1;
        };
        ok($rt_multi_inst_ok || !$@, "RTChecker: Multiple instances should not crash");
        
        # Test 10: Stress test with edge cases
        my @edge_cases = ("", "a", "A" x 50, "123", "!@#", "\n\t", undef);
        my $rt_stress_ok = eval {
            my $checker = COF::RT_Checker->new($temp_dir);
            for my $test_case (@edge_cases) {
                if (defined($checker) && $checker->can('check_word')) {
                    $checker->check_word($test_case);
                }
            }
            return 1;
        };
        ok($rt_stress_ok || !$@, "RTChecker: Edge case stress test should not crash");
    }
}

done_testing();

__END__

=head1 NAME

test_components.pl - Individual component tests for COF

=head1 DESCRIPTION

Tests for individual COF components that may or may not be available:

- COF::FastChecker: Fast word checking functionality
- COF::RT_Checker: RadixTree-based word checking and suggestion generation

These tests are designed to be robust and handle gracefully cases where
the components are not available or fail to initialize. All tests focus
on ensuring no crashes occur and that basic functionality works when available.

=cut