#!/usr/bin/env python3
"""
Convert COF JSON exports to msgpack format.

This script converts the JSON files exported from COF BerkeleyDB databases
to msgpack format for use in FurlanSpellChecker.

Usage:
    python convert_to_msgpack.py [--input-dir INPUT] [--output-dir OUTPUT]

Output files:
    - words.msgpack (phonetic_hash -> "word1,word2,word3")
    - frequencies.msgpack (word -> frequency)
    - errors.msgpack (error -> correction)
    - elisions.msgpack (list of words that allow elision)
"""

import json
import msgpack
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


def save_msgpack(data: Any, file_path: Path, compress: bool = True):
    """Save data to msgpack format."""
    print(f"Saving {file_path.name}...")
    with open(file_path, 'wb') as f:
        packed = msgpack.packb(data, use_bin_type=True)
        f.write(packed)
    
    size_mb = file_path.stat().st_size / (1024 * 1024)
    print(f"  ✓ Saved {size_mb:.2f} MB")


def convert_words(input_dir: Path, output_dir: Path):
    """Convert words.json to words.msgpack."""
    print("\n" + "="*60)
    print("Converting words.json → words.msgpack")
    print("="*60)
    
    json_path = input_dir / "words.json"
    msgpack_path = output_dir / "words.msgpack"
    
    data = load_json(json_path)
    
    # Verify it's a dict with phonetic hashes as keys
    if not isinstance(data, dict):
        raise ValueError("words.json should be a dictionary")
    
    # Statistics
    total_hashes = len(data)
    total_words = sum(len(words.split(',')) for words in data.values())
    
    print(f"\nStatistics:")
    print(f"  Total phonetic hashes: {total_hashes:,}")
    print(f"  Total words indexed: {total_words:,}")
    
    # Sample verification
    print(f"\nSample entries:")
    for i, (hash_code, words) in enumerate(list(data.items())[:5]):
        word_list = words.split(',')[:3]
        print(f"  '{hash_code}' -> {len(words.split(','))} words ({', '.join(word_list)}...)")
    
    save_msgpack(data, msgpack_path)
    print(f"\n✅ words.msgpack created successfully!")


def convert_frequencies(input_dir: Path, output_dir: Path):
    """Convert frequencies.json to frequencies.msgpack."""
    print("\n" + "="*60)
    print("Converting frequencies.json → frequencies.msgpack")
    print("="*60)
    
    json_path = input_dir / "frequencies.json"
    msgpack_path = output_dir / "frequencies.msgpack"
    
    data = load_json(json_path)
    
    # Verify it's a dict
    if not isinstance(data, dict):
        raise ValueError("frequencies.json should be a dictionary")
    
    # Statistics
    total_entries = len(data)
    accented_count = sum(1 for word in data.keys() if any(c in word for c in 'àáâèéêìíîòóôùúûÀÁÂÈÉÊÌÍÎÒÓÔÙÚÛ'))
    
    print(f"\nStatistics:")
    print(f"  Total entries: {total_entries:,}")
    print(f"  Words with accents: {accented_count:,}")
    print(f"  Words without accents: {total_entries - accented_count:,}")
    
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
        actual_freq = data.get(word)
        status = "✓" if actual_freq == expected_freq else "✗"
        print(f"  {status} '{word}' -> {actual_freq} (expected {expected_freq})")
        if actual_freq != expected_freq:
            all_ok = False
    
    if not all_ok:
        raise ValueError("Frequency verification failed! Some critical words have wrong frequencies.")
    
    save_msgpack(data, msgpack_path)
    print(f"\n✅ frequencies.msgpack created successfully!")


def convert_errors(input_dir: Path, output_dir: Path):
    """Convert errors.json to errors.msgpack."""
    print("\n" + "="*60)
    print("Converting errors.json → errors.msgpack")
    print("="*60)
    
    json_path = input_dir / "errors.json"
    msgpack_path = output_dir / "errors.msgpack"
    
    data = load_json(json_path)
    
    # Verify it's a dict
    if not isinstance(data, dict):
        raise ValueError("errors.json should be a dictionary")
    
    print(f"\nStatistics:")
    print(f"  Total error mappings: {len(data):,}")
    
    # Sample entries
    print(f"\nSample entries:")
    for i, (error, correction) in enumerate(list(data.items())[:10]):
        print(f"  '{error}' -> '{correction}'")
    
    save_msgpack(data, msgpack_path)
    print(f"\n✅ errors.msgpack created successfully!")


def convert_elisions(input_dir: Path, output_dir: Path):
    """Convert elisions.json to elisions.msgpack."""
    print("\n" + "="*60)
    print("Converting elisions.json → elisions.msgpack")
    print("="*60)
    
    json_path = input_dir / "elisions.json"
    msgpack_path = output_dir / "elisions.msgpack"
    
    data = load_json(json_path)
    
    # Verify it's a list
    if not isinstance(data, list):
        raise ValueError("elisions.json should be a list")
    
    print(f"\nStatistics:")
    print(f"  Total elision words: {len(data):,}")
    
    # Sample entries
    print(f"\nSample entries (first 20):")
    for word in data[:20]:
        print(f"  {word}")
    
    save_msgpack(data, msgpack_path)
    print(f"\n✅ elisions.msgpack created successfully!")


def main():
    parser = argparse.ArgumentParser(
        description='Convert COF JSON exports to msgpack format',
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
        help='Output directory for msgpack files (default: ./output)'
    )
    
    args = parser.parse_args()
    
    # Verify input directory exists
    if not args.input_dir.exists():
        print(f"❌ Error: Input directory does not exist: {args.input_dir}")
        return 1
    
    # Create output directory if needed
    args.output_dir.mkdir(parents=True, exist_ok=True)
    
    print("="*60)
    print("COF Database JSON → msgpack Converter")
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
        print("  - words.msgpack")
        print("  - frequencies.msgpack")
        print("  - errors.msgpack")
        print("  - elisions.msgpack")
        print("\nThese files can now be used in FurlanSpellChecker.")
        
        return 0
        
    except Exception as e:
        print(f"\n❌ Error during conversion: {e}")
        import traceback
        traceback.print_exc()
        return 1


if __name__ == '__main__':
    exit(main())
