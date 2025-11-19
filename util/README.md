# COF Utility Directory

This directory contains utility scripts for COF development and debugging. All utilities follow the `*_utils.pl` naming convention as per AGENTS.md guidelines.

## Purpose

Utilities in this folder are intended strictly for:
- Diagnostic inspection and debugging
- Data extraction and analysis  
- Encoding and tokenization testing
- Development assistance and manual testing

**Note**: No test runners are kept here. The canonical test suite lives in `tests/` directory.

## Available Utilities

### `spellchecker_utils.pl`
Spell checking and suggestion analysis utility.
- `--suggest WORD` - Run spellchecker and print suggestions
- `--word WORD` - Inspect a single word directly  
- `--file FILE` - Load words from file (one per line)
- `--format list|array|json` - Output format (default: list)
- `--list` - Print only suggestion words
- `--generate-hashes [--format=python|perl|text] word1 word2...` - Generate phonetic hashes for words
- `--compat` - Force COF::DataCompat mode (bypass COF::Data auto-detection)

### `radixtree_utils.pl`  
RadixTree suggestion debugging and test dataset generation utility.
- `--word WORD` - Show radix tree suggestions for a single word
- `--file FILE` - Batch process words from file
- `--format list|array|json` - Output format (default: list)
- `--list` - Show suggestions only
- `--generate-tests` - Generate test dataset from legacy vocabulary
- `--sample N` - Use sample of N words (default: 100, max: 1000)

### `encoding_utils.pl`
Text encoding inspection and debugging utility.
- `--suggest WORD` - Run spellchecker then inspect encodings of suggestions
- `--word WORD` - Inspect encoding of a single word
- `--file FILE` - Batch process words from file
- `--nohex` - Suppress raw UTF-8 byte output
- `--nounicode` - Suppress code point output

### `worditerator_utils.pl`
WordIterator debugging and token analysis utility.
- `--text TEXT` - Debug text tokenization directly
- `--file FILE` - Process file for token analysis
- `--limit N` - Limit output to N tokens
- `--raw` - Show raw token data
- `--help` - Display help information

### `database_utils.pl`
COF database inspection and diagnostic utility.
- `--errors` - Inspect errors database only
- `--elisions` - Inspect elisions database only
- `--frequency` - Inspect frequency database only
- `--test-word WORD` - Test suggestions for specific word
- `--show-top N` - Show top N most frequent words (default: 10)
- `--sample N` - Show N sample entries per database (default: 20)
- `--help` - Display full documentation

### `word_lookup_utils.pl`
Word lookup and metadata inspection utility for debugging ranking differences.
- `--word WORD` - Look up a single word with detailed metadata
- `--batch FILE` - Look up multiple words from file (one per line)
- `--suggest` - Include suggestions for the word
- `--phonetic` - Include phonetic code
- `--similar` - Include similar words (edit distance 1-2)
- `--json` - Output in JSON format for scripting
- `--verbose` - Show all available metadata
- `--help` - Display full documentation

### `nondeterminism_utils.pl`
Non-deterministic suggestion ordering detection utility.
- `--iterations N` - Number of iterations per word (default: 20)
- `--top N` - Number of top suggestions to check (default: 10)
- `--verbose` - Show all iterations (default: summary only)
- `--help` - Display help message

Detects non-deterministic ordering caused by hash iteration in COF::SpellChecker::suggest_raw.
Reports variant frequencies, position analysis, and identifies stable vs varying positions.

### `suggestion_ranking_utils.pl`
Suggestion ranking ground truth generation utility.
- `--verify-encoding` - Generate test cases with encoding verification
- `--latin1-escapes` - Output with \xNN escapes for Latin-1 characters
- `--help` - Display help message

Generates ground truth data for suggestion ranking tests with proper encoding handling.

## Usage Examples

### Basic Spell Checking
```bash
# Get suggestions for a word
perl util/spellchecker_utils.pl --suggest cjupe

# Analyze specific word  
perl util/spellchecker_utils.pl --word cjase --format json

# Process words from file
perl util/spellchecker_utils.pl --file wordlist.txt --list

# Generate phonetic hashes (for testing/development)
perl util/spellchecker_utils.pl --generate-hashes --format=python furlan cjase lenghe
```

### RadixTree Analysis and Test Dataset Generation
```bash
# Get RadixTree suggestions for a word
perl util/radixtree_utils.pl --word cjupe --format json

# Generate test dataset from legacy vocabulary
perl util/radixtree_utils.pl --generate-tests --sample 50

# Batch process with list output
perl util/radixtree_utils.pl --file words.txt --list
```

### Encoding Inspection
```bash
# Check encoding of suggestions
perl util/encoding_utils.pl --suggest cjupe --nohex

# Inspect single word encoding
perl util/encoding_utils.pl --word "cjàse" --nounicode
```

### WordIterator Debugging
```bash
# Debug text tokenization
perl util/worditerator_utils.pl --text "Cjale il libri"

# Process file with token analysis
perl util/worditerator_utils.pl --file sample.txt --limit 50
```

### Database Investigation
```bash
# Full database investigation
perl util/database_utils.pl

# Inspect specific database
perl util/database_utils.pl --errors
perl util/database_utils.pl --elisions
perl util/database_utils.pl --frequency

# Test suggestions for specific word
perl util/database_utils.pl --test-word furla

# Show top 20 most frequent words
perl util/database_utils.pl --frequency --show-top 20

# Show 50 sample entries per database
perl util/database_utils.pl --sample 50
```

### Word Lookup and Metadata Inspection
```bash
# Basic word lookup
perl util/word_lookup_utils.pl --word Cjas

# Detailed lookup with suggestions and phonetic
perl util/word_lookup_utils.pl --word cjasa --suggest --phonetic

# Check multiple words from file
perl util/word_lookup_utils.pl --batch words_to_check.txt

# Full metadata with similar words
perl util/word_lookup_utils.pl --word furla --verbose --similar

# JSON output for scripting/comparison
perl util/word_lookup_utils.pl --word cjase --json
```

### Non-Determinism Detection
```bash
# Check a single word for non-deterministic ordering
perl util/nondeterminism_utils.pl scuela

# Check multiple words with verbose output
perl util/nondeterminism_utils.pl --verbose scuela prossim grant

# Run 50 iterations and check top 15 suggestions
perl util/nondeterminism_utils.pl --iterations 50 --top 15 scuela

# Quick batch check of known problematic words
perl util/nondeterminism_utils.pl scuela prossim grant
```

### Suggestion Ranking Ground Truth
```bash
# Generate test cases with encoding verification
perl util/suggestion_ranking_utils.pl --verify-encoding

# Generate with Latin-1 hex escapes (for test files)
perl util/suggestion_ranking_utils.pl --latin1-escapes
```

## Development Guidelines

- All utilities follow the `*_utils.pl` naming convention
- Use consistent command-line argument patterns across utilities
- Provide `--help` option for usage information
- Support both single-word and batch file processing where applicable
- Use standard output formats (list, array, json) for consistency

### Conventions
- Naming: keep diagnostic tools suffixed with `_utils.pl`.
- Scope: limit each utility to a single concern (spell suggestions, radix tree, encoding, iterator).
- Tests: do NOT add test execution logic here; extend or add tests under `tests/` only.

### Adding a New Utility
1. Use a clear, single-purpose name (e.g. `morph_utils.pl`).
2. Provide POD (`=head1 NAME`, `DESCRIPTION`, `USAGE`).
3. Avoid hardcoding paths; derive relative paths with `FindBin` + `File::Spec` if needed.
4. Keep output deterministic and script exit codes meaningful (0 success, non‑zero on error).

### Cleaned Structure (2024)
This directory has been cleaned of temporary development files:

**Removed Files**:
- Development test files: `test_phonetic_standalone.pl`, `test_phonetic.pl`, `test_perl_phonetic_comparison.pl`, `test_perl_clean.pl`, `test_for_python.pl`, `phonetic_test_standalone.pl`, `phonetic_test_utils.pl`
- Temporary CSV files: `perl_results.csv`, `python_results.csv`
- Legacy test runners: `run_all_tests.pl`, `run_tests_simplified.pl`
- Duplicate utilities: `spellchecker_utils_compat.pl`

**Consolidated**:
- `spellchecker_utils.pl` now unified with automatic COF::Data/COF::DataCompat detection

**Current Structure**:
- `database_utils.pl` - COF database inspection and diagnostic utility (relocated from tests/)
- `dataset_utils.pl` - Dataset processing and validation utilities
- `encoding_utils.pl` - Text encoding analysis and conversion
- `nondeterminism_utils.pl` - Non-deterministic suggestion ordering detection and analysis
- `radixtree_utils.pl` - RadixTree operations, diagnostics and test dataset generation
- `spellchecker_utils.pl` - Unified spell checking (with compatibility auto-detection)
- `suggestion_ranking_utils.pl` - Suggestion ranking ground truth generation with encoding support
- `worditerator_utils.pl` - Text tokenization and word iteration
- `README.md` - This documentation

### Support
For expanding the test suite, see `tests/README.md` and `tests/run_all_tests.pl`.