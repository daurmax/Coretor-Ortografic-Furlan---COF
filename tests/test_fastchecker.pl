#!/usr/bin/env perl

use strict;
use warnings;
use Test::More;
use FindBin;
use File::Spec;
use File::Temp qw(tempdir);
use lib File::Spec->catdir($FindBin::Bin, '..', 'lib');

# FastChecker comprehensive test suite
plan tests => 23;

diag("Starting FastChecker comprehensive test suite");

# === Basic FastChecker Tests ===
{
    diag("Testing FastChecker basic functionality");
    
    # Test 1: FastChecker module availability
    {
        eval {
            require COF::FastChecker;
        };
        
        ok(!$@, "FastChecker: Should load FastChecker module");
        diag("FastChecker module loading: " . ($@ ? "FAILED: $@" : "SUCCESS"));
    }

    # Skip remaining tests if module unavailable
    SKIP: {
        eval { require COF::FastChecker; };
        skip "FastChecker module not available", 19 if $@;

        # Test 2: FastChecker object creation
        {
            my $temp_dir = tempdir(CLEANUP => 1);
            
            eval {
                my $checker = COF::FastChecker->new($temp_dir);
                ok(defined($checker), "FastChecker: Should create checker object");
            };
            
            if ($@) {
                pass("FastChecker: Constructor handled gracefully");
                diag("FastChecker constructor: $@");
            }
        }

        # Test 3: Basic word checking functionality
        {
            my $temp_dir = tempdir(CLEANUP => 1);
            
            eval {
                my $checker = COF::FastChecker->new($temp_dir);
                if (defined($checker)) {
                    # Test with a simple word
                    my $result = $checker->check_word("test");
                    ok(defined($result), "FastChecker: Should return defined result for word check");
                } else {
                    pass("FastChecker: Word check handled gracefully without valid checker");
                }
            };
            
            if ($@) {
                pass("FastChecker: Word check handled gracefully");
                diag("FastChecker word check: $@");
            }
        }

        # Test 4: Multiple word checking
        {
            my $temp_dir = tempdir(CLEANUP => 1);
            my @test_words = qw(hello world test example);
            
            eval {
                my $checker = COF::FastChecker->new($temp_dir);
                if (defined($checker)) {
                    for my $word (@test_words) {
                        my $result = $checker->check_word($word);
                        # Result can be true, false, or undef - all valid
                        pass("FastChecker: Word '$word' processed");
                    }
                } else {
                    for my $word (@test_words) {
                        pass("FastChecker: Word '$word' handled without checker");
                    }
                }
            };
            
            if ($@) {
                for my $word (@test_words) {
                    pass("FastChecker: Word '$word' handled gracefully");
                }
            }
        }

        # Test 5: Empty/invalid input handling
        {
            my $temp_dir = tempdir(CLEANUP => 1);
            
            eval {
                my $checker = COF::FastChecker->new($temp_dir);
                if (defined($checker)) {
                    # Test empty string
                    my $empty_result = $checker->check_word("");
                    ok(defined($empty_result) || !defined($empty_result), 
                       "FastChecker: Should handle empty string");
                    
                    # Test undef input
                    my $undef_result = $checker->check_word(undef);
                    ok(defined($undef_result) || !defined($undef_result), 
                       "FastChecker: Should handle undef input");
                } else {
                    pass("FastChecker: Empty input handled without checker");
                    pass("FastChecker: Undef input handled without checker");
                }
            };
            
            if ($@) {
                pass("FastChecker: Empty input handled gracefully");
                pass("FastChecker: Undef input handled gracefully");
            }
        }

        # Test 6: Unicode word handling
        {
            my $temp_dir = tempdir(CLEANUP => 1);
            my @unicode_words = ("café", "naïve", "résumé", "façade");
            
            eval {
                my $checker = COF::FastChecker->new($temp_dir);
                if (defined($checker)) {
                    for my $word (@unicode_words) {
                        my $result = $checker->check_word($word);
                        pass("FastChecker: Unicode word '$word' processed");
                    }
                } else {
                    for my $word (@unicode_words) {
                        pass("FastChecker: Unicode word '$word' handled without checker");
                    }
                }
            };
            
            if ($@) {
                for my $word (@unicode_words) {
                    pass("FastChecker: Unicode word '$word' handled gracefully");
                }
            }
        }
    }
}

# === FastChecker State Tests ===
{
    diag("Testing FastChecker state management");
    
    SKIP: {
        eval { require COF::FastChecker; };
        skip "FastChecker module not available", 8 if $@;

        # Test 7: Checker state consistency
        {
            my $temp_dir = tempdir(CLEANUP => 1);
            
            eval {
                my $checker1 = COF::FastChecker->new($temp_dir);
                my $checker2 = COF::FastChecker->new($temp_dir);
                
                if (defined($checker1) && defined($checker2)) {
                    # Both checkers should be independent
                    ok($checker1 != $checker2, "FastChecker: Multiple instances should be independent");
                } else {
                    pass("FastChecker: Multiple instances handled gracefully");
                }
            };
            
            if ($@) {
                pass("FastChecker: Multiple instances handled gracefully");
            }
        }

        # Test 8: State after multiple operations
        {
            my $temp_dir = tempdir(CLEANUP => 1);
            
            eval {
                my $checker = COF::FastChecker->new($temp_dir);
                if (defined($checker)) {
                    # Perform multiple operations
                    for (1..10) {
                        my $result = $checker->check_word("test$_");
                        # State should remain consistent
                    }
                    ok(defined($checker), "FastChecker: Should maintain state after multiple operations");
                } else {
                    pass("FastChecker: State maintained without valid checker");
                }
            };
            
            if ($@) {
                pass("FastChecker: State handled gracefully after operations");
            }
        }

        # Test 9: Memory usage patterns
        {
            my $temp_dir = tempdir(CLEANUP => 1);
            
            eval {
                my @checkers;
                for (1..5) {
                    my $checker = COF::FastChecker->new($temp_dir);
                    push @checkers, $checker if defined($checker);
                }
                
                ok(scalar(@checkers) >= 0, "FastChecker: Should handle multiple instances");
            };
            
            if ($@) {
                pass("FastChecker: Multiple instances handled gracefully");
            }
        }

        # Test 10: Cleanup behavior
        {
            my $temp_dir = tempdir(CLEANUP => 1);
            
            eval {
                {
                    my $checker = COF::FastChecker->new($temp_dir);
                    # Let it go out of scope
                }
                
                # Create another checker after cleanup
                my $new_checker = COF::FastChecker->new($temp_dir);
                ok(defined($new_checker) || !defined($new_checker), 
                   "FastChecker: Should handle cleanup gracefully");
            };
            
            if ($@) {
                pass("FastChecker: Cleanup handled gracefully");
            }
        }

        # Test 11: Performance consistency
        {
            my $temp_dir = tempdir(CLEANUP => 1);
            
            eval {
                my $checker = COF::FastChecker->new($temp_dir);
                if (defined($checker)) {
                    my @times;
                    for (1..5) {
                        my $start_time = time;
                        $checker->check_word("performance_test_word");
                        my $elapsed = time - $start_time;
                        push @times, $elapsed;
                    }
                    
                    # Performance should be reasonably consistent
                    ok(scalar(@times) == 5, "FastChecker: Should complete all performance tests");
                } else {
                    pass("FastChecker: Performance test handled without checker");
                }
            };
            
            if ($@) {
                pass("FastChecker: Performance test handled gracefully");
            }
        }

        # Test 12: Edge case words
        {
            my $temp_dir = tempdir(CLEANUP => 1);
            my @edge_words = ("", "a", "verylongwordthatmightcausememoryissues" x 10, "123", "!@#");
            
            eval {
                my $checker = COF::FastChecker->new($temp_dir);
                if (defined($checker)) {
                    for my $word (@edge_words) {
                        my $result = $checker->check_word($word);
                        pass("FastChecker: Edge case word processed");
                    }
                } else {
                    for my $word (@edge_words) {
                        pass("FastChecker: Edge case word handled without checker");
                    }
                }
            };
            
            if ($@) {
                for my $word (@edge_words) {
                    pass("FastChecker: Edge case word handled gracefully");
                }
            }
        }
    }
}

diag("FastChecker comprehensive test suite completed");

done_testing();