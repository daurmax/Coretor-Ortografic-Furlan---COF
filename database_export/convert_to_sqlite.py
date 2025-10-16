#!/usr/bin/env python3
"""
Convert COF JSON exports to SQLite format.

This script converts the JSON files exported from COF BerkeleyDB databases
to SQLite databases for use in FurlanSpellChecker or other applications.

Usage:
    python convert_to_sqlite.py [--input-dir INPUT] [--output-dir OUTPUT]

Output files:
    - words.sqlite (phonetic_hash -> words CSV)
    - frequencies.sqlite (word -> frequency)
    - errors.sqlite (error -> correction)
    - elisions.sqlite (word -> exists boolean)
"""

import json
import sqlite3
import argparse
from pathlib import Path
from typing import Dict, List, Any


def load_json(file_path: Path) -> Any:
    """Load JSON file with UTF-8 encoding."""
    print(f"Loading {file_path.name}...")
    with open(file_path, 'r', encoding='utf-8') as f:
        data = json.load(f)
    print(f"  ✓ Loaded {len(data) if isinstance(data, (dict, list)) else 'N/A'} entries")
    return data


def convert_words(input_dir: Path, output_dir: Path):
    """Convert words.json to words.sqlite."""
    print("\n" + "="*60)
    print("Converting words.json → words.sqlite")
    print("="*60)
    
    json_path = input_dir / "words.json"
    sqlite_path = output_dir / "words.sqlite"
    
    data = load_json(json_path)
    
    # Verify it's a dict
    if not isinstance(data, dict):
        raise ValueError("words.json should be a dictionary")
    
    # Create SQLite database
    if sqlite_path.exists():
        sqlite_path.unlink()
    
    conn = sqlite3.connect(sqlite_path)
    cursor = conn.cursor()
    
    # Create table
    cursor.execute("""
        CREATE TABLE words (
            phonetic_hash TEXT PRIMARY KEY,
            words TEXT NOT NULL
        )
    """)
    
    # Create index for faster lookups
    cursor.execute("CREATE INDEX idx_phonetic_hash ON words(phonetic_hash)")
    
    # Insert data
    print(f"Inserting {len(data):,} entries...")
    entries = [(hash_code, words) for hash_code, words in data.items()]
    cursor.executemany("INSERT INTO words (phonetic_hash, words) VALUES (?, ?)", entries)
    
    conn.commit()
    
    # Statistics
    cursor.execute("SELECT COUNT(*) FROM words")
    total_hashes = cursor.fetchone()[0]
    
    total_words = sum(len(words.split(',')) for words in data.values())
    
    print(f"\nStatistics:")
    print(f"  Total phonetic hashes: {total_hashes:,}")
    print(f"  Total words indexed: {total_words:,}")
    
    # Sample verification
    print(f"\nSample entries:")
    cursor.execute("SELECT phonetic_hash, words FROM words LIMIT 5")
    for hash_code, words in cursor.fetchall():
        word_list = words.split(',')[:3]
        print(f"  '{hash_code}' -> {len(words.split(','))} words ({', '.join(word_list)}...)")
    
    conn.close()
    
    size_mb = sqlite_path.stat().st_size / (1024 * 1024)
    print(f"\n✓ Saved {size_mb:.2f} MB")
    print(f"✅ words.sqlite created successfully!")


def convert_frequencies(input_dir: Path, output_dir: Path):
    """Convert frequencies.json to frequencies.sqlite."""
    print("\n" + "="*60)
    print("Converting frequencies.json → frequencies.sqlite")
    print("="*60)
    
    json_path = input_dir / "frequencies.json"
    sqlite_path = output_dir / "frequencies.sqlite"
    
    data = load_json(json_path)
    
    # Verify it's a dict
    if not isinstance(data, dict):
        raise ValueError("frequencies.json should be a dictionary")
    
    # Create SQLite database
    if sqlite_path.exists():
        sqlite_path.unlink()
    
    conn = sqlite3.connect(sqlite_path)
    cursor = conn.cursor()
    
    # Create table
    cursor.execute("""
        CREATE TABLE frequencies (
            word TEXT PRIMARY KEY,
            frequency INTEGER NOT NULL
        )
    """)
    
    # Create index
    cursor.execute("CREATE INDEX idx_word ON frequencies(word)")
    
    # Insert data
    print(f"Inserting {len(data):,} entries...")
    entries = [(word, freq) for word, freq in data.items()]
    cursor.executemany("INSERT INTO frequencies (word, frequency) VALUES (?, ?)", entries)
    
    conn.commit()
    
    # Statistics
    cursor.execute("SELECT COUNT(*) FROM frequencies")
    total_entries = cursor.fetchone()[0]
    
    cursor.execute("SELECT COUNT(*) FROM frequencies WHERE frequency IS NULL")
    null_count = cursor.fetchone()[0]
    
    print(f"\nStatistics:")
    print(f"  Total entries: {total_entries:,}")
    print(f"  NULL values: {null_count:,}")
    
    # Verify critical accented words
    critical_words = {
        'fûr': 177,
        'à': 207,
        'furlane': 182,
        'a': 243,
        'ur': 147
    }
    
    print(f"\nVerification (critical words):")
    all_ok = True
    for word, expected_freq in critical_words.items():
        cursor.execute("SELECT frequency FROM frequencies WHERE word = ?", (word,))
        result = cursor.fetchone()
        actual_freq = result[0] if result else None
        status = "✓" if actual_freq == expected_freq else "✗"
        print(f"  {status} '{word}' -> {actual_freq} (expected {expected_freq})")
        if actual_freq != expected_freq:
            all_ok = False
    
    conn.close()
    
    if not all_ok:
        raise ValueError("Frequency verification failed! Some critical words have wrong frequencies.")
    
    size_mb = sqlite_path.stat().st_size / (1024 * 1024)
    print(f"\n✓ Saved {size_mb:.2f} MB")
    print(f"✅ frequencies.sqlite created successfully!")


def convert_errors(input_dir: Path, output_dir: Path):
    """Convert errors.json to errors.sqlite."""
    print("\n" + "="*60)
    print("Converting errors.json → errors.sqlite")
    print("="*60)
    
    json_path = input_dir / "errors.json"
    sqlite_path = output_dir / "errors.sqlite"
    
    data = load_json(json_path)
    
    # Verify it's a dict
    if not isinstance(data, dict):
        raise ValueError("errors.json should be a dictionary")
    
    # Create SQLite database
    if sqlite_path.exists():
        sqlite_path.unlink()
    
    conn = sqlite3.connect(sqlite_path)
    cursor = conn.cursor()
    
    # Create table
    cursor.execute("""
        CREATE TABLE errors (
            error TEXT PRIMARY KEY,
            correction TEXT NOT NULL
        )
    """)
    
    # Create index
    cursor.execute("CREATE INDEX idx_error ON errors(error)")
    
    # Insert data
    print(f"Inserting {len(data):,} entries...")
    entries = [(error, correction) for error, correction in data.items()]
    cursor.executemany("INSERT INTO errors (error, correction) VALUES (?, ?)", entries)
    
    conn.commit()
    
    # Statistics
    cursor.execute("SELECT COUNT(*) FROM errors")
    total_entries = cursor.fetchone()[0]
    
    print(f"\nStatistics:")
    print(f"  Total error mappings: {total_entries:,}")
    
    # Sample entries
    print(f"\nSample entries:")
    cursor.execute("SELECT error, correction FROM errors LIMIT 10")
    for error, correction in cursor.fetchall():
        print(f"  '{error}' -> '{correction}'")
    
    conn.close()
    
    size_mb = sqlite_path.stat().st_size / (1024 * 1024)
    print(f"\n✓ Saved {size_mb:.2f} MB")
    print(f"✅ errors.sqlite created successfully!")


def convert_elisions(input_dir: Path, output_dir: Path):
    """Convert elisions.json to elisions.sqlite."""
    print("\n" + "="*60)
    print("Converting elisions.json → elisions.sqlite")
    print("="*60)
    
    json_path = input_dir / "elisions.json"
    sqlite_path = output_dir / "elisions.sqlite"
    
    data = load_json(json_path)
    
    # Verify it's a list
    if not isinstance(data, list):
        raise ValueError("elisions.json should be a list")
    
    # Create SQLite database
    if sqlite_path.exists():
        sqlite_path.unlink()
    
    conn = sqlite3.connect(sqlite_path)
    cursor = conn.cursor()
    
    # Create table
    cursor.execute("""
        CREATE TABLE elisions (
            word TEXT PRIMARY KEY
        )
    """)
    
    # Create index
    cursor.execute("CREATE INDEX idx_elision_word ON elisions(word)")
    
    # Insert data
    print(f"Inserting {len(data):,} entries...")
    entries = [(word,) for word in data]
    cursor.executemany("INSERT INTO elisions (word) VALUES (?)", entries)
    
    conn.commit()
    
    # Statistics
    cursor.execute("SELECT COUNT(*) FROM elisions")
    total_entries = cursor.fetchone()[0]
    
    print(f"\nStatistics:")
    print(f"  Total elision words: {total_entries:,}")
    
    # Sample entries
    print(f"\nSample entries (first 20):")
    cursor.execute("SELECT word FROM elisions LIMIT 20")
    for (word,) in cursor.fetchall():
        print(f"  {word}")
    
    conn.close()
    
    size_mb = sqlite_path.stat().st_size / (1024 * 1024)
    print(f"\n✓ Saved {size_mb:.2f} MB")
    print(f"✅ elisions.sqlite created successfully!")


def main():
    parser = argparse.ArgumentParser(
        description='Convert COF JSON exports to SQLite format',
        formatter_class=argparse.RawDescriptionHelpFormatter,
        epilog=__doc__
    )
    parser.add_argument(
        '--input-dir',
        type=Path,
        default=Path(__file__).parent / 'output',
        help='Input directory containing JSON files (default: ./output)'
    )
    parser.add_argument(
        '--output-dir',
        type=Path,
        default=Path(__file__).parent / 'output',
        help='Output directory for SQLite files (default: ./output)'
    )
    
    args = parser.parse_args()
    
    # Verify input directory exists
    if not args.input_dir.exists():
        print(f"❌ Error: Input directory does not exist: {args.input_dir}")
        return 1
    
    # Create output directory if needed
    args.output_dir.mkdir(parents=True, exist_ok=True)
    
    print("="*60)
    print("COF Database JSON → SQLite Converter")
    print("="*60)
    print(f"Input directory: {args.input_dir}")
    print(f"Output directory: {args.output_dir}")
    
    try:
        # Convert all databases
        convert_words(args.input_dir, args.output_dir)
        convert_frequencies(args.input_dir, args.output_dir)
        convert_errors(args.input_dir, args.output_dir)
        convert_elisions(args.input_dir, args.output_dir)
        
        print("\n" + "="*60)
        print("✅ ALL CONVERSIONS COMPLETED SUCCESSFULLY!")
        print("="*60)
        print(f"\nOutput files in: {args.output_dir}")
        print("  - words.sqlite")
        print("  - frequencies.sqlite")
        print("  - errors.sqlite")
        print("  - elisions.sqlite")
        print("\nThese files can now be used in FurlanSpellChecker.")
        
        return 0
        
    except Exception as e:
        print(f"\n❌ Error during conversion: {e}")
        import traceback
        traceback.print_exc()
        return 1


if __name__ == '__main__':
    exit(main())
