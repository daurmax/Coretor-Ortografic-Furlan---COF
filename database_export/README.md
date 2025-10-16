# COF Database Export & Conversion Scripts

This directory contains scripts to export COF's BerkeleyDB databases to JSON format and convert them to modern formats (msgpack or SQLite) for use in FurlanSpellChecker and other applications.

## Background

**Issue**: The original SQLite conversion had a bug that caused 29.2% of frequency values to become NULL, affecting 100% of Friulian accented words.

**Solution**: Export databases directly from COF using the same encoding filters as `COF::Data`, then convert to msgpack or SQLite format in Python.

## Files

### Export Scripts (Perl)

- **`export_words.pl`** - Export words.db (phonetic dictionary)
  - Input: `../dict/words.db` (~7.4M phonetic hashes, 10.1M words)
  - Output: `output/words.json` (~305 MB)
  - Encoding: ISO-8859-1 keys and values

- **`export_frequencies.pl`** - Export frec.db (word frequencies)
  - Input: `../dict/frec.db` (69,051 entries)
  - Output: `output/frequencies.json` (~1.4 MB)
  - Encoding: UTF-8 keys, integer values (0-255)
  
- **`export_errors.pl`** - Export errors.db (common misspellings → corrections)
  - Input: `../dict/errors.db` (301 entries)
  - Output: `output/errors.json` (~8 KB)
  - Encoding: UTF-8 keys and values
  
- **`export_elisions.pl`** - Export elisions.db (elision words)
  - Input: `../dict/elisions.db` (10,604 entries)
  - Output: `output/elisions.json` (~196 KB)
  - Encoding: UTF-8, array of words
  
- **`export_all.pl`** - Run all exports in sequence
  - Convenience script to export all databases
  - Reports success/failure for each

### Conversion Scripts (Python)

- **`convert_to_msgpack.py`** - Convert JSON to msgpack format
  - Recommended format for FurlanSpellChecker
  - Smaller size (30-50% reduction vs SQLite)
  - Faster loading (direct dict access)
  - No encoding issues
  
- **`convert_to_sqlite.py`** - Convert JSON to SQLite format
  - Alternative format for compatibility
  - Standard SQL database format
  - Can be queried with SQL tools

### Output

- **`output/`** - Generated files (gitignored)
  - JSON files: `words.json`, `frequencies.json`, `errors.json`, `elisions.json`
  - msgpack files: `words.msgpack`, `frequencies.msgpack`, `errors.msgpack`, `elisions.msgpack`
  - SQLite files: `words.sqlite`, `frequencies.sqlite`, `errors.sqlite`, `elisions.sqlite`

## Usage

### Step 1: Export from COF (Perl)

```bash
cd database_export
perl export_all.pl
```

This creates four JSON files in `output/`:
- `words.json` (~305 MB)
- `frequencies.json` (~1.4 MB)
- `errors.json` (~8 KB)
- `elisions.json` (~196 KB)

### Step 2: Convert to msgpack (Recommended)

```bash
python convert_to_msgpack.py
```

Or with custom directories:
```bash
python convert_to_msgpack.py --input-dir ./output --output-dir ./output
```

This creates four msgpack files:
- `words.msgpack` (~250 MB, 60% smaller than BerkeleyDB)
- `frequencies.msgpack` (~1.2 MB)
- `errors.msgpack` (~6 KB)
- `elisions.msgpack` (~150 KB)

### Step 3 (Alternative): Convert to SQLite

```bash
python convert_to_sqlite.py
```

This creates four SQLite databases:
- `words.sqlite`
- `frequencies.sqlite`
- `errors.sqlite`
- `elisions.sqlite`

## Encoding Details

All Perl export scripts use the **exact same encoding filters** as `COF::Data` to ensure correctness:

### Words (words.db)
```perl
$dbh->filter_fetch_key( sub { $_ = decode("iso-8859-1", $_) } );   # Keys: ISO-8859-1
$dbh->filter_fetch_value( sub { $_ = decode("iso-8859-1", $_) } ); # Values: ISO-8859-1
```

### Frequencies (frec.db)
```perl
$dbh->filter_fetch_key( sub { utf8::decode($_) } );      # Keys: UTF-8
$dbh->filter_fetch_value( sub { $_ = unpack("C", $_) } ); # Values: byte → int
```

### Errors & Elisions
```perl
$dbh->filter_fetch_key( sub { utf8::decode($_) } );   # Keys: UTF-8
$dbh->filter_fetch_value( sub { utf8::decode($_) } ); # Values: UTF-8 (errors only)
```

## Verification

Each script includes automatic verification:

### Perl Export Scripts
- **words.pl**: Shows sample phonetic hashes, counts single/multi-word hashes
- **frequencies.pl**: Checks critical accented words (fûr→177, à→207), reports accented vs non-accented counts
- **errors.pl**: Shows first 10 error→correction pairs
- **elisions.pl**: Shows first 20 elision words

### Python Conversion Scripts
- Verify data structure types (dict vs list)
- Check critical accented words in frequencies (fûr, à, furlane, etc.)
- Report statistics (entry counts, NULL values)
- Sample data verification

## Output Statistics

| File | JSON Size | msgpack Size | SQLite Size | Entries |
|------|-----------|--------------|-------------|---------|
| words | 305.56 MB | ~250 MB | ~400 MB | 7,430,427 hashes |
| frequencies | 1.44 MB | ~1.2 MB | ~2.4 MB | 69,051 |
| errors | 8.33 KB | ~6 KB | ~20 KB | 301 |
| elisions | 196.12 KB | ~150 KB | ~300 KB | 10,604 |

## Next Steps

### For FurlanSpellChecker Integration

1. **Convert to msgpack** (recommended):
   ```bash
   python convert_to_msgpack.py
   ```

2. **Copy msgpack files to FurlanSpellChecker**:
   ```bash
   cp output/*.msgpack ../../FurlanSpellChecker/data/databases/
   ```

3. **Update FurlanSpellChecker database classes** to load msgpack format

4. **Test** with accented words to verify frequencies are correct

### For Other Applications

If you need SQLite format instead:
```bash
python convert_to_sqlite.py
```

## Requirements

### Perl Scripts
- Perl 5.10+
- DB_File module (for BerkeleyDB access)
- JSON::PP module (core module since Perl 5.14)
- Encode module (core module)
- UTF-8 support

Install missing modules:
```bash
cpan DB_File
cpan JSON::PP  # Usually included in core Perl
```

### Python Scripts
- Python 3.7+
- msgpack module: `pip install msgpack`
- No other dependencies (uses stdlib sqlite3 and json)

Install Python dependencies:
```bash
pip install msgpack
```

## Troubleshooting

### Perl Export Issues

**"Cannot open database"**
- Check that `../dict/*.db` files exist
- Ensure you're running from `database_export/` directory
- Verify BerkeleyDB files are not corrupted

**"Wide character in print"**
- This is normal, UTF-8 output is working correctly
- Output files will have proper UTF-8 encoding

**"untie attempted while 1 inner references still exist"**
- This warning is harmless and expected
- BerkeleyDB cleanup issue, does not affect output

### Python Conversion Issues

**"No module named 'msgpack'"**
- Install msgpack: `pip install msgpack`

**"Frequency verification failed"**
- Check that JSON export has correct values
- Verify accented words: fûr→177, à→207
- Re-run Perl export if needed

**JSON file too large**
- This is expected, JSON is verbose
- `words.json` will be ~305 MB
- msgpack will reduce to ~250 MB (18% savings)
- SQLite will be ~400 MB

## Format Comparison

| Format | Size | Pros | Cons |
|--------|------|------|------|
| **msgpack** | Smallest | Fast, portable, no dependencies | Requires msgpack library |
| **SQLite** | Medium | Standard, queryable | Larger, slower, more complex |
| **JSON** | Largest | Human-readable, universal | Too large for distribution |
| **BerkeleyDB** | Medium | Original format | Obsolete, hard to install, platform-specific |

**Recommendation**: Use **msgpack** for FurlanSpellChecker (fast, small, portable).

## See Also

- `../../FurlanSpellChecker/docs/development/Database_Migration_Strategy.md` - Full migration strategy and analysis
- `../../FurlanSpellChecker/docs/development/COF_Parity_Roadmap.md` - Phase 5.1 implementation details
- `../lib/COF/Data.pm` - Original COF encoding implementation
- `../dict/` - Source BerkeleyDB databases
