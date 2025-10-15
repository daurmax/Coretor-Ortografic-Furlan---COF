# COF Test Suite

This directory contains the consolidated test suite for the COF (Coretor Ortografic Furlan) project. 

## Test Structure

The test suite is organized into 6 specialized test files that comprehensively cover all COF functionality:

### Core Test Files

| File | Tests | Purpose |
|------|--------|---------|
| `test_core.pl` | 129 | Core functionality, compatibility layer, database integration (88 core tests + 41 file checks) |
| `test_worditerator.pl` | 67 | WordIterator tokenization, Unicode handling, edge cases |
| `test_suggestions.pl` | 50 | Component integration (FastChecker/RTChecker) and suggestion algorithm testing |
| `test_radix_tree.pl` | 72 | RadixTree ED1 suggestions, ground truth verification, performance tests |
| `test_utilities.pl` | 37 | Encoding, CLI validation, legacy vocabulary handling |
| `test_phonetic_algorithm.pl` | 231 | Comprehensive phonetic algorithm testing (98 words × 2 tests + 13 robustness + 28 parity tests) |
| `test_known_bugs.pl` | 9 | Historical documentation of known bugs (non-deterministic suggestion ordering for tied suggestions) |

### Special Test Files

| File | Tests | Purpose |
|------|--------|---------|
| `test_known_bugs.pl` | 9 | Documents known bugs preserved for historical reference (non-deterministic hash iteration) |

### Test Runner

- **`run_all_tests.pl`** - Unified test suite runner for all 6 test files

## Running Tests

### Individual Test Files
```bash
perl test_core.pl
perl test_worditerator.pl
perl test_suggestions.pl
perl test_radix_tree.pl
perl test_utilities.pl
perl test_phonetic_algorithm.pl
perl test_known_bugs.pl
```

### Complete Test Suite (Recommended)
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

- **Total Tests**: 595 tests across 7 test files (6 main + 1 special)
- **Test Breakdown**:
  - Core & Database: 129 tests (initialization, compatibility, database integration)
  - WordIterator: 67 tests (tokenization, Unicode, edge cases)
  - Suggestions & Components: 50 tests (component integration + suggestion algorithm)
  - RadixTree: 72 tests (ED1 suggestions with ground truth verification)
  - Utilities: 37 tests (encoding, CLI validation, legacy data)
  - Phonetic Algorithm: 231 tests (98 words × 2 hashes + 13 robustness + 28 parity tests)
  - Known Bugs: 9 tests (documents non-deterministic behavior for historical preservation)
- **Expected Results**: 5/6 suites pass (1 pre-existing failure in test_utilities.pl line 24)
- **Database Dependencies**: Core tests require COF dictionaries in `../dict/` directory
- **Component Dependencies**: Component tests handle missing FastChecker/RTChecker gracefully
- **Execution Time**: Full suite completes in ~15 seconds on standard hardware

## Consolidation Benefits

This streamlined structure (6 test files, down from 9 previously) provides:
- **Better Organization**: Logical grouping of related functionality
- **Reduced Complexity**: Fewer files to maintain while preserving all test coverage
- **Improved Maintainability**: Clear scope definitions with POD documentation
- **Enhanced Clarity**: Consolidated test files eliminate redundant imports and setup code
- **Clean Directory**: Follows AGENTS.md guidelines for test organization

## Special Notes on test_known_bugs.pl

This test file serves as **historical documentation** of known bugs in the COF codebase:

- **Non-Deterministic Ordering**: Documents hash iteration order causing random suggestion ordering for tied results
- **Root Cause Analysis**: Includes detailed analysis of peso structure and hash iteration in `suggest_raw`
- **Valid Variants**: Documents all valid orderings that COF may produce (e.g., 'scuela' positions 4-5)
- **Purpose**: Preserves ground truth behavior at time of writing, alerts to future changes in codebase behavior
- **Not a Bug Report**: This is accepted behavior documentation, not a request for fixes

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

The `test_core.pl` file includes a comprehensive compatibility layer section that validates 
COF::DataCompat functionality, while `test_phonetic_algorithm.pl` provides extensive validation 
that the COF::DataCompat phonetic algorithm produces identical results to the original 
implementation. This ensures 100% compatibility for phonetic hashing when DB_File is unavailable.

## Support

For diagnosing internal behavior, use the utilities in `util/` directory:
- `spellchecker_utils.pl` - Spell checking and suggestion analysis
- `radixtree_utils.pl` - RadixTree suggestion debugging
- `encoding_utils.pl` - Text encoding inspection
- `database_utils.pl` - Database content investigation
