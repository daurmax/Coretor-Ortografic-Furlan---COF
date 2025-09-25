# COF Testing Tools

This directory contains tools for generating ground truth data and validating compatibility between different Friulian spell checker implementations.

## Overview

The testing suite consists of two main components:

1. **Ground Truth Generation** (`ground_truth/`) - Tools to generate reference results using the COF Perl script
2. **Compatibility Validation** (`validation/`) - Tools to validate other spell checkers against COF results

## Directory Structure

```
testing/
├── README.md                           # This file
├── ground_truth/                       # Ground truth generation tools
│   ├── generate_ground_truth.py        # Main ground truth generator
│   └── results/                        # Generated ground truth files
│       ├── *_ground_truth_*.json       # Ground truth data (JSON format)
│       ├── *_ground_truth_*.tsv        # Ground truth data (TSV format)
│       └── *_statistics_*.txt          # Generation statistics
├── validation/                         # Compatibility validation tools
│   ├── validate_compatibility.py       # Main validation script
│   └── reports/                        # Generated validation reports
│       └── *_compatibility_report_*.md # Detailed compatibility reports
└── fixtures/                          # Test data and fixtures
    ├── test_words.txt                 # Common test words
    └── legacy_words.json              # Words from COF legacy data
```

## Ground Truth Generation

### Purpose

The ground truth generator creates reference results using the original COF Perl script. These results serve as the authoritative standard for validating other Friulian spell checker implementations.

### Usage

```bash
# Generate ground truth from default test words
cd COF/testing/ground_truth
python generate_ground_truth.py

# Generate from specific word list
python generate_ground_truth.py path/to/words.txt

# Generate with custom output directory
python generate_ground_truth.py words.txt -o custom/output/dir

# Process in smaller batches
python generate_ground_truth.py words.txt --batch-size 25
```

### Input Formats

The generator supports multiple input formats:

- **JSON files**: Test cases or simple word lists
- **Text files**: One word per line
- **No input**: Uses default Friulian test words

### Output Files

Each generation produces:

- **JSON file**: Machine-readable ground truth data
- **TSV file**: Human-readable tabular format
- **Statistics file**: Generation summary and statistics

### Requirements

- Perl installed and accessible in PATH (preferably Strawberry Perl)
- COF Perl script (`script/cof_oo_cli.pl`)
- COF libraries (`lib/COF/`)

## Compatibility Validation

### Purpose

The validation suite compares other spell checker implementations against COF ground truth data to measure compatibility and identify differences.

### Usage

```bash
# Validate FurlanSpellChecker from workspace
cd COF/testing/validation
python validate_compatibility.py furlanspellchecker

# Validate with specific ground truth file
python validate_compatibility.py furlanspellchecker -g ../ground_truth/results/specific_gt.json

# Validate custom implementation
python validate_compatibility.py custom -e /path/to/custom/spellchecker
```

### Supported Spell Checkers

1. **FurlanSpellChecker** (`furlanspellchecker`)
   - Python implementation from workspace
   - Automatic discovery and import
   - Direct API integration

2. **Custom Implementations** (`custom`)
   - External executables
   - JSON-based communication protocol
   - Flexible integration

### Validation Metrics

The validation suite measures:

- **Correctness Matches**: Percentage of words with matching correct/incorrect status
- **Suggestion Matches**: Percentage of words with similar suggestion lists
- **Overall Compatibility**: Combined compatibility score

### Output Reports

Validation generates detailed Markdown reports including:

- Summary statistics
- Ground truth distribution analysis
- Failed word cases with specific differences
- Improvement recommendations

## Examples

### Complete Workflow

```bash
# 1. Generate ground truth from test words
cd COF/testing/ground_truth
python generate_ground_truth.py ../fixtures/test_words.txt

# 2. Validate FurlanSpellChecker compatibility
cd ../validation
python validate_compatibility.py furlanspellchecker

# 3. Review generated report
ls reports/furlanspellchecker_compatibility_report_*.md
```

### Custom Word Lists

```bash
# Create custom word list
echo -e "cjase\\ncjar\\ngjal\\nscjalde" > custom_words.txt

# Generate ground truth
python generate_ground_truth.py custom_words.txt

# Validate implementation
python validate_compatibility.py furlanspellchecker
```

## Integration with COF

### Prerequisites

1. **COF Installation**: Complete COF setup with Perl script functional
2. **Perl Environment**: Strawberry Perl recommended for Windows
3. **Python Environment**: Python 3.6+ with required packages

### Perl Setup

Ensure COF Perl script works:

```bash
cd COF
perl -I lib script/cof_oo_cli.pl
# Interactive mode - test with: s cjase
```

### Path Configuration

The scripts automatically detect COF root directory and configure paths. If needed, ensure:

- `COF/script/cof_oo_cli.pl` exists
- `COF/lib/COF/` directory contains Perl modules
- Strawberry Perl in system PATH

## Troubleshooting

### Common Issues

1. **"COF script not found"**
   - Verify COF directory structure
   - Check script permissions
   - Ensure relative paths are correct

2. **"Perl not available"**
   - Install Strawberry Perl
   - Add Perl to system PATH
   - Restart terminal/VS Code

3. **"COF script test failed"**
   - Test COF manually: `perl -I lib script/cof_oo_cli.pl`
   - Check COF dependencies
   - Verify COF dictionary files

4. **"FurlanSpellChecker not found"**
   - Ensure FurlanSpellChecker project is in workspace
   - Check Python import paths
   - Verify FurlanSpellChecker installation

### Debug Mode

Run with Python debug mode for detailed output:

```bash
python -u generate_ground_truth.py words.txt
python -u validate_compatibility.py furlanspellchecker
```

## Development

### Adding New Spell Checkers

To add support for a new spell checker:

1. Extend `COFCompatibilityValidator` class
2. Implement test method (e.g., `test_new_checker()`)
3. Add command-line option
4. Document integration protocol

### Custom Validation Metrics

The validation framework supports custom metrics by extending the comparison logic in `compare_results()` method.

### Batch Processing

Both tools support batch processing for large word lists. Adjust batch sizes based on system performance and memory constraints.

## Historical Context

This testing suite was developed to address compatibility validation between the original COF Perl implementation and newer Python-based implementations. The ground truth approach ensures objective comparison against the authoritative COF results.

Previous validation attempts used mock/fake reference data, which provided meaningless compatibility metrics. This suite generates real COF results for accurate validation.

## Contributing

When adding new testing capabilities:

1. Maintain backward compatibility with existing ground truth formats
2. Document new features in this README
3. Include example usage
4. Add error handling and user-friendly messages

## Files Generated

### Ground Truth Files

- `*_ground_truth_YYYYMMDD_HHMMSS.json`: Main ground truth data
- `*_ground_truth_YYYYMMDD_HHMMSS.tsv`: Tabular format for analysis
- `*_statistics_YYYYMMDD_HHMMSS.txt`: Generation statistics

### Validation Reports

- `*_compatibility_report_YYYYMMDD_HHMMSS.md`: Detailed compatibility analysis

All files include timestamps to prevent overwrites and enable historical comparison.