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

### `radixtree_utils.pl`  
RadixTree suggestion debugging utility.
- `--word WORD` - Show radix tree suggestions
- `--file FILE` - Batch process words from file
- `--format list|array|json` - Output format
- `--list` - Show suggestions only

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
```

### RadixTree Analysis
```bash
# Get RadixTree suggestions
perl util/radixtree_utils.pl --word cjupe --format json

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

### Removed Legacy Items
- Test runners (`run_all_tests.pl`, `run_tests_simplified.pl`) eliminati da `util/`. Usa `perl tests/run_all_tests.pl`.

### Support
For expanding the test suite, see the new `tests/README.md` once added.