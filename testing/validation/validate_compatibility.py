#!/usr/bin/env python3
"""
COF Validation Suite

This tool validates compatibility between different Friulian spell checker
implementations by comparing their results against COF ground truth data.

Usage:
    python validate_compatibility.py <spell_checker_type> [options]
    
Supported spell checkers:
    - furlanspellchecker: Python implementation
    - custom: Custom implementation (provide --executable)
"""

import json
import os
import subprocess
import sys
import time
import argparse
from pathlib import Path
from typing import Dict, List, Any, Optional, Tuple
import importlib.util


class SimpleColorManager:
    """Simple color output manager for cross-platform compatibility."""
    
    def info(self, text): return f"[INFO] {text}"
    def success(self, text): return f"[OK] {text}" 
    def error(self, text): return f"[ERROR] {text}"
    def warning(self, text): return f"[WARN] {text}"
    def header(self, text): return f"=== {text} ==="
    def accent(self, text): return text


class COFCompatibilityValidator:
    """Validates spell checker compatibility against COF ground truth."""
    
    def __init__(self, cof_root: Path):
        """Initialize the validator.
        
        Args:
            cof_root: Root directory of the COF project
        """
        self.cof_root = cof_root
        self.color_manager = SimpleColorManager()
        self.ground_truth_dir = cof_root / "testing" / "ground_truth" / "results"
        
    def find_latest_ground_truth(self) -> Optional[Path]:
        """Find the most recent ground truth file.
        
        Returns:
            Path to latest ground truth JSON file or None
        """
        if not self.ground_truth_dir.exists():
            print(self.color_manager.error(f"Ground truth directory not found: {self.ground_truth_dir}"))
            return None
        
        json_files = list(self.ground_truth_dir.glob("*_ground_truth_*.json"))
        if not json_files:
            print(self.color_manager.error("No ground truth files found"))
            return None
        
        # Sort by modification time (newest first)
        latest_file = max(json_files, key=lambda f: f.stat().st_mtime)
        print(self.color_manager.info(f"Using ground truth: {latest_file.name}"))
        return latest_file
    
    def load_ground_truth(self, ground_truth_file: Optional[Path] = None) -> Dict[str, Dict[str, Any]]:
        """Load ground truth data.
        
        Args:
            ground_truth_file: Specific ground truth file, or None for latest
            
        Returns:
            Dictionary mapping word -> {is_correct, suggestions}
        """
        if ground_truth_file is None:
            ground_truth_file = self.find_latest_ground_truth()
        
        if ground_truth_file is None or not ground_truth_file.exists():
            raise FileNotFoundError("No ground truth file available")
        
        with open(ground_truth_file, 'r', encoding='utf-8') as f:
            ground_truth = json.load(f)
        
        print(self.color_manager.success(f"Loaded ground truth for {len(ground_truth)} words"))
        return ground_truth
    
    def test_furlanspellchecker(self, words: List[str]) -> Dict[str, Dict[str, Any]]:
        """Test words using FurlanSpellChecker.
        
        Args:
            words: List of words to test
            
        Returns:
            Dictionary mapping word -> {is_correct, suggestions}
        """
        try:
            # Try to import FurlanSpellChecker from workspace
            furlan_path = self.cof_root.parent / "FurlanSpellChecker" / "src" / "furlanspellchecker"
            if not furlan_path.exists():
                raise ImportError("FurlanSpellChecker not found in workspace")
            
            # Add to Python path
            sys.path.insert(0, str(furlan_path.parent))
            
            # Import the spell checker
            from furlanspellchecker.spell_checker import FurlanSpellChecker
            
            # Initialize spell checker
            checker = FurlanSpellChecker()
            
            results = {}
            for word in words:
                is_correct = checker.check(word)
                suggestions = checker.suggest(word) if not is_correct else []
                
                results[word] = {
                    'is_correct': is_correct,
                    'suggestions': suggestions[:10]  # Limit suggestions
                }
            
            return results
            
        except Exception as e:
            print(self.color_manager.error(f"FurlanSpellChecker test failed: {e}"))
            return {}
    
    def test_custom_executable(self, words: List[str], executable: Path) -> Dict[str, Dict[str, Any]]:
        """Test words using a custom executable.
        
        Args:
            words: List of words to test
            executable: Path to spell checker executable
            
        Returns:
            Dictionary mapping word -> {is_correct, suggestions}
        """
        if not executable.exists():
            raise FileNotFoundError(f"Executable not found: {executable}")
        
        results = {}
        for word in words:
            try:
                # Assume executable takes word as argument and outputs JSON
                result = subprocess.run(
                    [str(executable), word],
                    capture_output=True,
                    text=True,
                    timeout=10
                )
                
                if result.returncode == 0:
                    data = json.loads(result.stdout)
                    results[word] = {
                        'is_correct': data.get('is_correct', False),
                        'suggestions': data.get('suggestions', [])
                    }
                else:
                    results[word] = {'is_correct': False, 'suggestions': []}
                    
            except Exception as e:
                print(self.color_manager.warning(f"Error testing word '{word}': {e}"))
                results[word] = {'is_correct': False, 'suggestions': []}
        
        return results
    
    def compare_results(self, ground_truth: Dict[str, Dict[str, Any]], 
                       test_results: Dict[str, Dict[str, Any]]) -> Dict[str, Any]:
        """Compare test results against ground truth.
        
        Args:
            ground_truth: COF reference results
            test_results: Implementation test results
            
        Returns:
            Comparison statistics and failed cases
        """
        comparison = {
            'total_words': 0,
            'correctness_matches': 0,
            'suggestion_matches': 0,
            'failed_words': [],
            'statistics': {}
        }
        
        common_words = set(ground_truth.keys()) & set(test_results.keys())
        comparison['total_words'] = len(common_words)
        
        if comparison['total_words'] == 0:
            print(self.color_manager.error("No common words found between ground truth and test results"))
            return comparison
        
        # Count different types of results in ground truth
        gt_correct = sum(1 for word in common_words if ground_truth[word]['is_correct'])
        gt_incorrect = comparison['total_words'] - gt_correct
        gt_with_suggestions = sum(1 for word in common_words if ground_truth[word]['suggestions'])
        
        comparison['statistics']['ground_truth'] = {
            'correct_words': gt_correct,
            'incorrect_words': gt_incorrect,
            'words_with_suggestions': gt_with_suggestions
        }
        
        # Compare each word
        for word in common_words:
            gt_result = ground_truth[word]
            test_result = test_results[word]
            
            # Check correctness match
            correctness_match = gt_result['is_correct'] == test_result['is_correct']
            if correctness_match:
                comparison['correctness_matches'] += 1
            
            # Check suggestion match (if both have suggestions)
            gt_suggestions = set(gt_result.get('suggestions', []))
            test_suggestions = set(test_result.get('suggestions', []))
            
            suggestion_match = False
            if gt_suggestions or test_suggestions:
                # Consider match if there's significant overlap or both empty
                if not gt_suggestions and not test_suggestions:
                    suggestion_match = True
                elif gt_suggestions and test_suggestions:
                    # Calculate Jaccard similarity
                    intersection = len(gt_suggestions & test_suggestions)
                    union = len(gt_suggestions | test_suggestions)
                    similarity = intersection / union if union > 0 else 0
                    suggestion_match = similarity >= 0.3  # 30% similarity threshold
            
            if suggestion_match:
                comparison['suggestion_matches'] += 1
            
            # Record failures
            if not correctness_match or not suggestion_match:
                comparison['failed_words'].append({
                    'word': word,
                    'correctness_match': correctness_match,
                    'suggestion_match': suggestion_match,
                    'ground_truth': gt_result,
                    'test_result': test_result
                })
        
        # Calculate percentages
        comparison['correctness_percentage'] = (comparison['correctness_matches'] / comparison['total_words']) * 100
        comparison['suggestion_percentage'] = (comparison['suggestion_matches'] / comparison['total_words']) * 100
        comparison['overall_compatibility'] = (
            (comparison['correctness_matches'] + comparison['suggestion_matches']) / 
            (2 * comparison['total_words'])
        ) * 100
        
        return comparison
    
    def generate_report(self, comparison: Dict[str, Any], 
                       spell_checker_name: str, output_dir: Path) -> Path:
        """Generate a detailed compatibility report.
        
        Args:
            comparison: Comparison results
            spell_checker_name: Name of tested spell checker
            output_dir: Output directory
            
        Returns:
            Path to generated report
        """
        output_dir.mkdir(parents=True, exist_ok=True)
        
        timestamp = time.strftime("%Y%m%d_%H%M%S")
        report_path = output_dir / f"{spell_checker_name}_compatibility_report_{timestamp}.md"
        
        with open(report_path, 'w', encoding='utf-8') as f:
            f.write(f"# COF Compatibility Report: {spell_checker_name}\\n\\n")
            f.write(f"Generated: {time.strftime('%Y-%m-%d %H:%M:%S')}\\n\\n")
            
            # Summary
            f.write("## Summary\\n\\n")
            f.write(f"- **Total Words Tested**: {comparison['total_words']}\\n")
            f.write(f"- **Correctness Matches**: {comparison['correctness_matches']} ({comparison['correctness_percentage']:.1f}%)\\n")
            f.write(f"- **Suggestion Matches**: {comparison['suggestion_matches']} ({comparison['suggestion_percentage']:.1f}%)\\n")
            f.write(f"- **Overall Compatibility**: {comparison['overall_compatibility']:.1f}%\\n")
            f.write(f"- **Failed Words**: {len(comparison['failed_words'])}\\n\\n")
            
            # Ground truth statistics
            if 'statistics' in comparison:
                gt_stats = comparison['statistics']['ground_truth']
                f.write("## Ground Truth Distribution\\n\\n")
                f.write(f"- Correct words: {gt_stats['correct_words']}\\n")
                f.write(f"- Incorrect words: {gt_stats['incorrect_words']}\\n")
                f.write(f"- Words with suggestions: {gt_stats['words_with_suggestions']}\\n\\n")
            
            # Failed words analysis
            if comparison['failed_words']:
                f.write("## Failed Words Analysis\\n\\n")
                f.write("| Word | Issue | COF Result | Test Result | COF Suggestions | Test Suggestions |\\n")
                f.write("|------|-------|------------|-------------|-----------------|------------------|\\n")
                
                for fail in comparison['failed_words'][:50]:  # Limit to first 50
                    word = fail['word']
                    issues = []
                    if not fail['correctness_match']:
                        issues.append("correctness")
                    if not fail['suggestion_match']:
                        issues.append("suggestions")
                    issue_text = ", ".join(issues)
                    
                    cof_correct = "✅" if fail['ground_truth']['is_correct'] else "❌"
                    test_correct = "✅" if fail['test_result']['is_correct'] else "❌"
                    
                    cof_sugg = ", ".join(fail['ground_truth'].get('suggestions', [])[:3])
                    test_sugg = ", ".join(fail['test_result'].get('suggestions', [])[:3])
                    
                    f.write(f"| {word} | {issue_text} | {cof_correct} | {test_correct} | {cof_sugg} | {test_sugg} |\\n")
                
                if len(comparison['failed_words']) > 50:
                    f.write(f"\\n*... and {len(comparison['failed_words']) - 50} more failures*\\n")
            
            f.write("\\n## Recommendations\\n\\n")
            if comparison['overall_compatibility'] >= 90:
                f.write("✅ **Excellent compatibility!** Minor adjustments may further improve alignment.\\n")
            elif comparison['overall_compatibility'] >= 70:
                f.write("⚠️ **Good compatibility** with room for improvement. Focus on failed cases.\\n")
            else:
                f.write("❌ **Significant compatibility issues** detected. Major improvements needed.\\n")
        
        print(self.color_manager.success(f"Report saved: {report_path}"))
        return report_path
    
    def run_validation(self, spell_checker_type: str, 
                      ground_truth_file: Optional[Path] = None,
                      executable: Optional[Path] = None) -> Dict[str, Any]:
        """Run complete validation process.
        
        Args:
            spell_checker_type: Type of spell checker to test
            ground_truth_file: Specific ground truth file
            executable: Custom executable path
            
        Returns:
            Validation results
        """
        print(self.color_manager.header("COF Compatibility Validation"))
        print("=" * 60)
        
        # Load ground truth
        ground_truth = self.load_ground_truth(ground_truth_file)
        words = list(ground_truth.keys())
        
        print(self.color_manager.info(f"Testing {len(words)} words against {spell_checker_type}..."))
        
        # Run tests based on spell checker type
        if spell_checker_type == "furlanspellchecker":
            test_results = self.test_furlanspellchecker(words)
        elif spell_checker_type == "custom" and executable:
            test_results = self.test_custom_executable(words, executable)
        else:
            raise ValueError(f"Unsupported spell checker type: {spell_checker_type}")
        
        if not test_results:
            raise RuntimeError("Failed to get test results")
        
        # Compare results
        comparison = self.compare_results(ground_truth, test_results)
        
        # Display results
        print()
        print(self.color_manager.header("Validation Results:"))
        print(f"Total words tested: {comparison['total_words']}")
        print(f"Correctness matches: {self.color_manager.success(str(comparison['correctness_matches']))} ({comparison['correctness_percentage']:.1f}%)")
        print(f"Suggestion matches: {self.color_manager.info(str(comparison['suggestion_matches']))} ({comparison['suggestion_percentage']:.1f}%)")
        compatibility_pct = f"{comparison['overall_compatibility']:.1f}%"
        print(f"Overall compatibility: {self.color_manager.accent(compatibility_pct)}")
        print(f"Failed words: {self.color_manager.error(str(len(comparison['failed_words'])))} cases")
        
        # Generate report
        output_dir = self.cof_root / "testing" / "validation" / "reports"
        report_path = self.generate_report(comparison, spell_checker_type, output_dir)
        
        return comparison


def main():
    """Main execution function."""
    parser = argparse.ArgumentParser(
        description="Validate spell checker compatibility against COF ground truth"
    )
    parser.add_argument(
        'spell_checker', 
        choices=['furlanspellchecker', 'custom'],
        help='Type of spell checker to validate'
    )
    parser.add_argument(
        '-g', '--ground-truth', 
        type=Path,
        help='Specific ground truth file (default: latest)'
    )
    parser.add_argument(
        '-e', '--executable', 
        type=Path,
        help='Path to custom spell checker executable'
    )
    parser.add_argument(
        '-o', '--output', 
        type=Path,
        help='Output directory for reports (default: ./testing/validation/reports/)'
    )
    
    args = parser.parse_args()
    
    # Determine COF root (this script should be in COF/testing/validation/)
    cof_root = Path(__file__).parent.parent.parent
    
    # Initialize validator
    validator = COFCompatibilityValidator(cof_root)
    
    try:
        # Validate arguments
        if args.spell_checker == 'custom' and not args.executable:
            print(validator.color_manager.error("Custom spell checker requires --executable argument"))
            return 1
        
        # Run validation
        results = validator.run_validation(
            args.spell_checker,
            args.ground_truth,
            args.executable
        )
        
        print()
        print(validator.color_manager.success("🎉 Validation completed successfully!"))
        
        return 0
        
    except Exception as e:
        print(validator.color_manager.error(f"Validation failed: {e}"))
        import traceback
        traceback.print_exc()
        return 1


if __name__ == "__main__":
    sys.exit(main())