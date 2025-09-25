#!/usr/bin/env python3
"""
COF Ground Truth Generator

This tool generates reference results using the COF Perl spell checker
to create ground truth data for compatibility validation with other
Friulian spell checker implementations.

Usage:
    python generate_ground_truth.py [input_words_file] [output_directory]
    
The script can process:
- JSON files with test cases
- Plain text files with one word per line
- Word lists from COF legacy data
"""

import json
import os
import subprocess
import sys
import tempfile
from pathlib import Path
from typing import Dict, List, Any, Optional, Tuple
import time
import argparse


class SimpleColorManager:
    """Simple color output manager for cross-platform compatibility."""
    
    def info(self, text): return f"[INFO] {text}"
    def success(self, text): return f"[OK] {text}" 
    def error(self, text): return f"[ERROR] {text}"
    def warning(self, text): return f"[WARN] {text}"
    def header(self, text): return f"=== {text} ==="
    def accent(self, text): return text


class COFGroundTruthGenerator:
    """Generator for COF reference results using cof_oo_cli.pl."""
    
    def __init__(self, cof_root: Path):
        """Initialize the generator.
        
        Args:
            cof_root: Root directory of the COF project
        """
        self.cof_root = cof_root
        self.color_manager = SimpleColorManager()
        
        # Paths
        self.cof_script_path = cof_root / "script" / "cof_oo_cli.pl"
        self.cof_lib_path = cof_root / "lib"
        
        # Results storage
        self.results_cache = {}
        
    def check_cof_availability(self) -> bool:
        """Check if COF Perl script is available and functional.
        
        Returns:
            True if COF script exists and is accessible
        """
        if not self.cof_script_path.exists():
            print(self.color_manager.error(f"COF script not found at: {self.cof_script_path}"))
            return False
        
        if not self.cof_lib_path.exists():
            print(self.color_manager.error(f"COF lib directory not found at: {self.cof_lib_path}"))
            return False
        
        # Test if perl is available
        try:
            result = subprocess.run(['perl', '--version'], 
                                  capture_output=True, text=True, timeout=10)
            if result.returncode != 0:
                print(self.color_manager.error("Perl not found or not working"))
                return False
        except (subprocess.TimeoutExpired, FileNotFoundError):
            print(self.color_manager.error("Perl not available in system PATH"))
            print(self.color_manager.info("Hint: Add Strawberry Perl to PATH"))
            return False
        
        # Test COF with a simple word
        try:
            is_correct, suggestions = self.run_cof_on_word("test")
            print(self.color_manager.success("COF script is functional"))
            return True
        except Exception as e:
            print(self.color_manager.error(f"COF script test failed: {e}"))
            return False
    
    def run_cof_on_word(self, word: str) -> Tuple[bool, List[str]]:
        """Run COF spell checker on a single word using STDIN protocol.
        
        Args:
            word: Word to check
            
        Returns:
            Tuple of (is_correct, suggestions_list)
        """
        if word in self.results_cache:
            return self.results_cache[word]
        
        try:
            # COF CLI protocol via STDIN:
            # Input: "s <word>\\nq\\n" (suggest command + quit)
            # Output: "ok" or "no\\t<suggestions>"
            
            cmd = [
                'perl', '-I', str(self.cof_lib_path),
                str(self.cof_script_path)
            ]
            
            # Prepare input for COF
            cof_input = f"s {word}\nq\n"
            
            # Set up environment with proper PATH for Strawberry Perl
            env = os.environ.copy()
            strawberry_paths = [
                "C:\\\\Strawberry\\\\perl\\\\bin",
                "C:\\\\Strawberry\\\\c\\\\bin"
            ]
            for path in strawberry_paths:
                if path not in env.get('PATH', ''):
                    env['PATH'] = env.get('PATH', '') + f";{path}"
            
            result = subprocess.run(
                cmd, 
                input=cof_input,
                capture_output=True, 
                text=True, 
                timeout=10,
                encoding='utf-8',
                cwd=str(self.cof_root),
                env=env
            )
            
            if result.returncode != 0:
                print(self.color_manager.warning(f"COF error for word '{word}': {result.stderr}"))
                return (False, [])
            
            # Parse COF output
            cof_output = result.stdout.strip()
            is_correct = False
            suggestions = []
            
            if cof_output:
                lines = cof_output.split('\n')
                for line in lines:
                    line = line.strip()
                    if line == 'ok':
                        is_correct = True
                        suggestions = []
                        break
                    elif line.startswith('no') and '\t' in line:
                        is_correct = False
                        # Split by tab and get suggestions part
                        parts = line.split('\t', 1)
                        if len(parts) > 1:
                            suggestions_part = parts[1]
                            if suggestions_part:
                                suggestions = [s.strip() for s in suggestions_part.split(',') if s.strip()]
                        break
                    elif line == 'no':
                        is_correct = False
                        suggestions = []
                        break
            
            # Cache result
            self.results_cache[word] = (is_correct, suggestions)
            return (is_correct, suggestions)
            
        except subprocess.TimeoutExpired:
            print(self.color_manager.warning(f"Timeout processing word: {word}"))
            return (False, [])
        except Exception as e:
            print(self.color_manager.warning(f"Error processing word '{word}': {e}"))
            return (False, [])
    
    def load_words_from_file(self, input_file: Path) -> List[str]:
        """Load words from various file formats.
        
        Args:
            input_file: Path to input file (JSON, TXT, or legacy format)
            
        Returns:
            List of words to test
        """
        words = []
        
        if input_file.suffix.lower() == '.json':
            # Handle JSON format (test cases or simple word lists)
            with open(input_file, 'r', encoding='utf-8') as f:
                data = json.load(f)
            
            if 'test_cases' in data:
                # Test cases format
                words = [case['word'] for case in data['test_cases'] if case.get('word')]
            elif isinstance(data, list):
                # Simple list format
                words = [str(item) for item in data if item]
            else:
                print(self.color_manager.warning(f"Unknown JSON format in {input_file}"))
        
        else:
            # Handle plain text format
            with open(input_file, 'r', encoding='utf-8') as f:
                words = [line.strip() for line in f if line.strip()]
        
        print(self.color_manager.success(f"Loaded {len(words)} words from {input_file.name}"))
        return words
    
    def generate_ground_truth_batch(self, words: List[str], 
                                   batch_size: int = 50) -> Dict[str, Dict[str, Any]]:
        """Generate ground truth results for words in batches.
        
        Args:
            words: List of words to test
            batch_size: Number of words to process per batch
            
        Returns:
            Dictionary mapping word -> {is_correct, suggestions}
        """
        print(self.color_manager.info("Generating ground truth results using COF..."))
        
        ground_truth = {}
        total_words = len(words)
        processed = 0
        
        start_time = time.time()
        
        for i in range(0, total_words, batch_size):
            batch = words[i:i + batch_size]
            batch_num = (i // batch_size) + 1
            total_batches = (total_words + batch_size - 1) // batch_size
            
            print(self.color_manager.info(f"Processing batch {batch_num}/{total_batches}..."))
            
            for word in batch:
                # Skip empty or problematic words
                if not word or len(word.strip()) == 0:
                    processed += 1
                    continue
                
                # Get COF results
                is_correct, suggestions = self.run_cof_on_word(word)
                
                ground_truth[word] = {
                    'is_correct': is_correct,
                    'suggestions': suggestions
                }
                
                processed += 1
                
                # Progress update
                if processed % 10 == 0:
                    elapsed = time.time() - start_time
                    progress = (processed / total_words) * 100
                    print(f"Progress: {progress:.1f}% ({processed}/{total_words}) - {elapsed:.1f}s elapsed")
        
        elapsed_total = time.time() - start_time
        print(self.color_manager.success(f"Generated ground truth for {len(ground_truth)} words in {elapsed_total:.1f}s"))
        
        return ground_truth
    
    def save_results(self, ground_truth: Dict[str, Dict[str, Any]], 
                    output_dir: Path, input_file: Optional[Path] = None) -> Dict[str, Path]:
        """Save ground truth results in multiple formats.
        
        Args:
            ground_truth: Ground truth results
            output_dir: Output directory
            input_file: Original input file (for naming)
            
        Returns:
            Dictionary of saved file paths
        """
        output_dir.mkdir(parents=True, exist_ok=True)
        
        # Generate timestamp
        timestamp = time.strftime("%Y%m%d_%H%M%S")
        
        # Base name from input file or default
        if input_file:
            base_name = input_file.stem
        else:
            base_name = "cof_ground_truth"
        
        saved_files = {}
        
        # Save as JSON
        json_path = output_dir / f"{base_name}_ground_truth_{timestamp}.json"
        with open(json_path, 'w', encoding='utf-8') as f:
            json.dump(ground_truth, f, indent=2, ensure_ascii=False)
        saved_files['json'] = json_path
        
        # Save as TSV for easy analysis
        tsv_path = output_dir / f"{base_name}_ground_truth_{timestamp}.tsv"
        with open(tsv_path, 'w', encoding='utf-8') as f:
            f.write("word\\tcorrect\\tsuggestions\\n")
            for word, result in ground_truth.items():
                correct = "true" if result['is_correct'] else "false"
                suggestions = ",".join(result['suggestions'])
                f.write(f"{word}\\t{correct}\\t{suggestions}\\n")
        saved_files['tsv'] = tsv_path
        
        # Save statistics
        stats_path = output_dir / f"{base_name}_statistics_{timestamp}.txt"
        correct_count = sum(1 for r in ground_truth.values() if r['is_correct'])
        incorrect_count = len(ground_truth) - correct_count
        with_suggestions = sum(1 for r in ground_truth.values() if r['suggestions'])
        
        with open(stats_path, 'w', encoding='utf-8') as f:
            f.write(f"COF Ground Truth Statistics\\n")
            f.write(f"Generated: {time.strftime('%Y-%m-%d %H:%M:%S')}\\n")
            f.write(f"Total words: {len(ground_truth)}\\n")
            f.write(f"Correct words: {correct_count} ({correct_count/len(ground_truth)*100:.1f}%)\\n")
            f.write(f"Incorrect words: {incorrect_count} ({incorrect_count/len(ground_truth)*100:.1f}%)\\n")
            f.write(f"Words with suggestions: {with_suggestions}\\n")
        saved_files['stats'] = stats_path
        
        print(self.color_manager.success(f"Ground truth results saved:"))
        for format_type, path in saved_files.items():
            print(f"  {format_type.upper()}: {self.color_manager.accent(str(path))}")
        
        return saved_files


def main():
    """Main execution function."""
    parser = argparse.ArgumentParser(
        description="Generate COF ground truth data for spell checker validation"
    )
    parser.add_argument(
        'input_file', 
        nargs='?', 
        type=Path,
        help='Input file with words to test (JSON or TXT format)'
    )
    parser.add_argument(
        '-o', '--output', 
        type=Path, 
        default=None,
        help='Output directory (default: ./testing/ground_truth/)'
    )
    parser.add_argument(
        '--batch-size', 
        type=int, 
        default=50,
        help='Batch size for processing (default: 50)'
    )
    
    args = parser.parse_args()
    
    # Determine COF root (this script should be in COF/testing/ground_truth/)
    cof_root = Path(__file__).parent.parent.parent
    
    # Set default output directory
    if args.output is None:
        args.output = cof_root / "testing" / "ground_truth" / "results"
    
    # Initialize generator
    generator = COFGroundTruthGenerator(cof_root)
    
    # Display banner
    print(generator.color_manager.header("COF Ground Truth Generator"))
    print("=" * 50)
    print()
    print(generator.color_manager.info("Generating reference results using COF Perl script"))
    print(f"COF Root: {cof_root}")
    print()
    
    try:
        # Check COF availability
        if not generator.check_cof_availability():
            print(generator.color_manager.error("Cannot proceed without functional COF"))
            return 1
        
        # Handle input
        if args.input_file:
            if not args.input_file.exists():
                print(generator.color_manager.error(f"Input file not found: {args.input_file}"))
                return 1
            words = generator.load_words_from_file(args.input_file)
        else:
            # Interactive mode or default test words
            print(generator.color_manager.info("No input file provided. Using default Friulian test words..."))
            words = [
                "cjase", "cjar", "gjal", "scjalde", "spieli", "storie", 
                "tradizion", "gjaldins", "cjant", "gjerât", "scjasie"
            ]
            print(generator.color_manager.success(f"Using {len(words)} default test words"))
        
        if not words:
            print(generator.color_manager.error("No words to process"))
            return 1
        
        # Generate ground truth
        ground_truth = generator.generate_ground_truth_batch(words, args.batch_size)
        
        # Save results
        saved_files = generator.save_results(ground_truth, args.output, args.input_file)
        
        # Statistics
        correct_count = sum(1 for gt in ground_truth.values() if gt['is_correct'])
        incorrect_count = len(ground_truth) - correct_count
        with_suggestions = sum(1 for gt in ground_truth.values() if gt['suggestions'])
        
        print()
        print(generator.color_manager.header("Ground Truth Statistics:"))
        print(f"✅ Correct words: {generator.color_manager.success(str(correct_count))}")
        print(f"❌ Incorrect words: {generator.color_manager.error(str(incorrect_count))}")
        print(f"💭 Words with suggestions: {generator.color_manager.info(str(with_suggestions))}")
        print()
        print(generator.color_manager.success("🎉 Ground truth generation completed successfully!"))
        print()
        print(generator.color_manager.info("Generated files can be used for:"))
        print("- Compatibility validation with other spell checkers")
        print("- Regression testing of COF modifications")
        print("- Performance benchmarking")
        print("- Algorithm comparison studies")
        
        return 0
        
    except Exception as e:
        print(generator.color_manager.error(f"Ground truth generation failed: {e}"))
        import traceback
        traceback.print_exc()
        return 1


if __name__ == "__main__":
    sys.exit(main())