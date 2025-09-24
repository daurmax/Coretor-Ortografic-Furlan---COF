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
- `encoding_utils.pl` - Text encoding analysis and conversion
- `radixtree_utils.pl` - RadixTree operations, diagnostics and test dataset generation
- `spellchecker_utils.pl` - Unified spell checking (with compatibility auto-detection)
- `worditerator_utils.pl` - Text tokenization and word iteration
- `README.md` - This documentation

### Support
For expanding the test suite, see `tests/README.md` and `tests/run_all_tests.pl`.