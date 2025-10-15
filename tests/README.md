# COF Test Suite

This directory contains the consolidated test suite for the COF (Coretor Ortografic Furlan) project. 

## Test Structure

The test suite is organized into specialized test files that comprehensively cover all COF functionality:

### Core Test Files

| File | Tests | Purpose |
|------|--------|---------|
| `test_core_functionality.pl` | 36 | Database connectivity, basic SpellChecker operations |
| `test_core_functionality_compat.pl` | 17 | COF::DataCompat compatibility validation and testing |
| `test_components.pl` | 23 | FastChecker and RTChecker component testing |
| `test_database_integration.pl` | 35 | Database integration and data access |
| `test_phonetic_algorithm.pl` | 231 | Comprehensive phonetic algorithm testing (98 words × 2 tests + 13 robustness + 28 parity tests) |
| `test_radix_tree.pl` | 72 | RadixTree ED1 suggestions, ground truth verification |
| `test_suggestions.pl` | 27 | Suggestion algorithm testing |
| `test_utilities.pl` | 22 | Encoding, CLI validation, utility functions |
| `test_worditerator.pl` | 33 | WordIterator functionality and text processing |

### Test Runner

- **`run_all_tests.pl`** - Unified test suite runner for all 9 test files

## Running Tests

### Individual Test Files
```bash
perl test_core_functionality.pl
perl test_core_functionality_compat.pl
perl test_components.pl
perl test_database_integration.pl
perl test_phonetic_algorithm.pl
perl test_radix_tree.pl
perl test_suggestions.pl
perl test_utilities.pl
perl test_worditerator.pl
```

### Complete Test Suite
```bash
perl run_all_tests.pl
```

## Test Philosophy

All tests follow these principles:
- **Real Database Testing**: Core tests use actual COF databases for integration testing
- **Graceful Component Handling**: Component tests handle optional modules gracefully  
- **Robust Error Handling**: All eval blocks use proper error checking patterns
- **Comprehensive Coverage**: Tests cover normal operations, edge cases, and error conditions
- **TAP Compliance**: All tests use Test::More with proper TAP output

## Test Results Summary

- **Total Tests**: 496 tests across 9 test files
- **Phonetic Algorithm**: 231 tests for exact Perl-Python parity (98 words × 2 hashes + 13 robustness + 28 parity tests)
- **RadixTree**: 72 tests for ED1 suggestions with ground truth verification
- **Core Functionality**: 88 tests across core, compatibility, and database integration
- **Other Components**: 105 tests for suggestions, utilities, word iteration, and component integration
- **Expected Results**: All tests should pass with proper COF installation
- **Database Dependencies**: Core tests require COF dictionaries in `../dict/` directory
- **Component Dependencies**: Component tests handle missing FastChecker/RTChecker gracefully

## Maintenance

This consolidated structure replaces the previous 17+ individual test files, providing:
- Better organization and maintainability
- Logical grouping of related functionality
- Reduced test suite complexity
- Improved test execution performance
- Cleaner directory structure following AGENTS.md guidelines

## Quality Guidelines

- **Clear Test Descriptions**: Every `ok` / `is` assertion must explain its purpose
- **No Debug Output**: Remove debug `print` statements (use `diag` only when strictly necessary)
- **Deterministic Order**: Avoid non-deterministic ordering (use explicit `sort` when needed)
- **Coverage**: Test positive path, negative path, minimal edge case, and extreme edge case

## What NOT to Do

- Do not move test runners to `util/` directory
- Do not add duplicate test execution scripts
- Do not mix data generation with assertions — use separate helper functions if complexity grows

## Future Improvements (Optional)

- Add separate performance tests (e.g., dedicated `perf/` directory)
- Integrate coverage analysis (Devel::Cover) for extended reporting
- Implement automated CI pipeline

## Compatibility Note

The `test_core_functionality_compat.pl` test validates basic COF::DataCompat functionality, 
while `test_phonetic_algorithm.pl` provides comprehensive validation that the COF::DataCompat 
phonetic algorithm produces identical results to the original implementation. This ensures 
100% compatibility for phonetic hashing when DB_File is unavailable.

## Support

For diagnosing internal behavior, use the utilities in `util/` directory:
- `spellchecker_utils.pl` - Spell checking and suggestion analysis
- `radixtree_utils.pl` - RadixTree suggestion debugging
- `encoding_utils.pl` - Text encoding inspection
- `database_utils.pl` - Database content investigation
