# COF - Coretôr Ortografic Furlan

<div align="center">
  <img src="res/icons/cof128.png" alt="COF Logo" width="128" height="128">
  <br>
  <em>Original Friulian Spell Checker</em>
</div>

## Overview

**COF** (Coretôr Ortografic Furlan) is the original Friulian spell checker developed by Franz Feregot. This is the reference implementation written in Perl, serving as the authoritative source for the Friulian language spell checking algorithm and dictionary management.

> **⚠️ Important Notice**: This repository contains the original, unmodified COF source code that should be preserved as-is for historical and reference purposes. Any modifications should be made in derivative projects, not in this original codebase.

## Project History

This repository represents version **2.16** of COF, built on **20110620** with lemmas version **20150417**. The software includes both a graphical user interface and command-line tools for Friulian spell checking.

### Branch Structure

- **`master`**: Main branch with original COF source code + accepted changes from develop (🔒 **protected** - requires pull requests for merges)
- **`original`**: Pure original source with preservation notice (🔒 **locked** - completely read-only, historical reference)
- **`develop`**: Active development branch for new features and improvements (🔓 **open for development**)

> **Note**: The `original` branch contains only the unmodified original COF code and is completely locked for historical preservation. The `master` branch evolves by accepting vetted changes from `develop` through pull requests. All active development work should be done in the `develop` branch.

### Repository Structure

This repository preserves Franz Feregot's original COF implementation with modern enhancements. See `CHANGELOG.md` for detailed version history.

**Original Structure** (preserved in `original` branch):
- Complete Perl implementation in `COF-2.16/`
- Core spell checking modules in `lib/COF/`
- GUI and CLI executables in `script/`
- OpenOffice.org plugin integration
- Resource files and original icons
- Empty dictionary placeholder (`dict/empty`)
- Build configuration and metadata

**Enhancements Added**:
- Complete Friulian dictionary database with Git LFS
- Comprehensive test suite with 402 validation cases covering all components
- Documentation and contribution guidelines
- Repository modernization and GitHub integration
- Continuous Integration with automated testing on every commit

## Architecture

### Compatibility Solutions

**⚠️ DB_File Dependency Issue**: The original COF implementation depends on BerkeleyDB through Perl's `DB_File` module. On some systems (especially Windows with Strawberry Perl), this dependency may fail with errors like "Can't load 'DB_File.xs.dll'".

**✅ Recommended Solution: Fix PATH for BerkeleyDB**
The proper solution is to ensure BerkeleyDB libraries are in your system PATH:

**For Strawberry Perl users:**
```powershell
# Add BerkeleyDB libraries to PATH
$env:PATH += ";C:\Strawberry\c\bin"
# Or permanently via System Properties → Environment Variables
```

**Verify the fix:**
```perl
perl -MDB_File -e "print 'DB_File loaded successfully\n'"
```

This enables full `COF::Data` functionality with complete database access and all original features.

**🔧 Alternative Solution: COF::DataCompat**
If PATH configuration is not possible, we provide `COF::DataCompat` as a fallback:
- ✅ **Complete phonetic algorithm**: Identical `phalg_furlan` implementation (100% compatibility)
- ✅ **No BerkeleyDB dependency**: Uses SDBM_File (included in standard Perl)
- ✅ **Drop-in replacement**: Same API as `COF::Data` for phonetic functions
- ⚠️ **Limited dictionary features**: Database operations are restricted but phonetic algorithm works fully

**Usage**:
```perl
# Fallback when DB_File cannot be fixed
use COF::DataCompat;

# Phonetic algorithm works identically
my ($primo, $secondo) = COF::DataCompat::phalg_furlan('furlan');
# Returns: ('fYl65', 'fYl65')
```

**When to use each approach**:
- **COF::Data** (preferred): When PATH is properly configured for BerkeleyDB
- **COF::DataCompat** (fallback): When BerkeleyDB libraries cannot be resolved
- **Cross-platform development**: Use DataCompat for maximum compatibility

**Test files available**:
- `tests/test_core_functionality_compat.pl` - Core functionality with compat version
- `tests/test_radix_tree.pl` - RadixTree functionality and performance validation
- `tests/run_all_tests.pl` - Complete test suite runner (402 test cases)
- `util/spellchecker_utils.pl` - Spell checking utilities (auto-detects compatibility mode)

### Core Components

1. **COF::App** - Main application entry point with Wx GUI framework
2. **COF::Data** - Dictionary and language data management
3. **COF::SpellChecker** - Core spell checking logic
4. **COF::FastChecker** - Text processing and error detection engine  
5. **COF::RadixTree** - Efficient dictionary storage and lookup
6. **COF::Letters** - Friulian character set definitions
7. **COF::Frame** - Main GUI window and user interface

### Key Features

#### 1. Phonetic Algorithm (`phalg_furlan`)
The heart of COF's spell checking is a sophisticated phonetic algorithm located in `COF::Data::phalg_furlan` that:

- Generates dual phonetic hashes (primo/secondo) for Friulian words
- Normalizes accented characters (à/á/â → a, è/é/ê → e, etc.)
- Handles Friulian-specific sequences (çi/çe, sci/sce, cj patterns)
- Implements complex vowel and consonant transformations
- Supports phonetic similarity matching for suggestions

**Algorithm Flow:**
```perl
Input: "sciençe" 
  → Preparation: normalize accents, handle ç sequences, compress doubles
  → Hash Generation: apply different rules to primo/secondo hashes  
  → Vowel Mapping: diphthongs first (ai→6, ei→7), then singles (a→6, e→7)
  → Consonant Mapping: context-sensitive transformations (^t→H, ^d→I)
Output: ("A75ç7", "E775ç7")
```

#### 2. Dictionary System
- **System Dictionary**: Core Friulian vocabulary stored in RadixTree format
- **User Dictionary**: Personal additions with phonetic indexing
- **Exception Dictionary**: Words that override default rules
- **Frequency Dictionary**: Usage statistics for word ranking

#### 3. Text Processing
- **Word Iterator**: Tokenizes text respecting Friulian word boundaries
- **Context Analysis**: Considers surrounding words for better suggestions
- **Automatic Correction**: Learns from user corrections

#### 4. Suggestion Engine
- **Phonetic Matching**: Uses dual hash system for sound-alike words
- **Edit Distance**: Levenshtein distance with Friulian-specific costs
- **Frequency Ranking**: Prioritizes common words in suggestions

## Installation & Setup on Windows

### Prerequisites

**1. Install Git LFS** (required for dictionary files):
```powershell
# Git LFS is included with modern Git installations
# Verify installation
git lfs version

# If not installed, download from: https://git-lfs.github.io/
```

**2. Install Strawberry Perl** using Chocolatey:

```powershell
# Install Chocolatey if not already installed
Set-ExecutionPolicy Bypass -Scope Process -Force; 
[System.Net.ServicePointManager]::SecurityProtocol = [System.Net.ServicePointManager]::SecurityProtocol -bor 3072; 
iex ((New-Object System.Net.WebClient).DownloadString('https://community.chocolatey.org/install.ps1'))

# Install Strawberry Perl
choco install strawberryperl

# Refresh environment variables
refreshenv
# OR restart PowerShell session
```

### Install Dependencies

```powershell
# Navigate to COF directory
cd "path\to\COF"

# Install required Perl modules
cpan install Params::Validate
cpan install File::HomeDir  
cpan install Wx
cpan install Wx::Perl::ListCtrl
cpan install Try::Tiny
cpan install Carp::Always
```

**3. Configure Windows PATH** (essential for global perl access and COF::Data):

#### Permanent PATH Configuration (Recommended)

For system-wide and permanent access to perl commands and DB_File support:

```powershell
# Open System Properties (Run → sysdm.cpl) OR search "Environment Variables" in Start menu
# Go to: Advanced tab → Environment Variables button
# In "System Variables" section:
#   - Find and select "Path" → Click "Edit..."
#   - Click "New" and add: C:\Strawberry\perl\bin
#   - Click "New" and add: C:\Strawberry\c\bin
#   - Click "OK" to save all dialogs
# Restart terminal to apply changes
```

#### Temporary Session Configuration

```powershell
# Add to PATH for current PowerShell session only
$env:PATH += ";C:\Strawberry\perl\bin;C:\Strawberry\c\bin"
```

#### Verification

```powershell
# Test Perl global access
perl --version

# Test DB_File module availability
perl -MDB_File -e "print 'DB_File loaded successfully\n'"

# Test COF functionality
cd COF
perl script\cof_oo_cli.pl
```

> **Important**: Without proper PATH configuration, `perl` command won't work globally and COF will encounter DB_File errors, falling back to `COF::DataCompat` with limited functionality. The permanent PATH fix enables full database access and all original COF features.

### Clone Repository with LFS

```powershell
# Clone repository and download LFS files
git clone https://github.com/daurmax/COF.git
cd COF
git lfs install
git lfs pull
```

### Build and Run

```powershell
# Build the project
perl Build.PL
perl Build

# Run phonetic algorithm tests
perl tests/test_phonetic_perl.pl

# Launch GUI application
perl script/cof.pl

# Use CLI version
perl script/cof_oo_cli.pl
```

## Repository Structure

### Original COF Implementation
Franz Feregot's complete COF v2.16 source code (preserved in `original` branch and flattened to repository root):

```
├── lib/COF/                    # Core Perl modules (16 files)
│   ├── Data.pm                 # Dictionary management & phonetic algorithm
│   ├── SpellChecker.pm         # Main spell checking logic
│   ├── FastChecker.pm          # Text processing engine
│   ├── RadixTree.pm            # Dictionary storage structure
│   ├── App.pm                  # GUI application framework
│   ├── Frame.pm, FrameBase.pm  # GUI window management
│   ├── TextDisplay.pm          # Text editing components
│   ├── Personal.pm             # User dictionary management
│   └── [7 additional modules]  # Complete implementation
├── script/                     # Executable scripts
│   ├── cof.pl                  # GUI application launcher
│   └── cof_oo_cli.pl           # Command-line interface
├── COFOOPlugin/                # OpenOffice.org integration
│   ├── cof/oo/                 # Java plugin classes
│   └── [plugin configuration]
├── res/                        # Resources and assets
│   ├── icons/                  # Application icons (.ico format)
│   │   ├── cof128.ico, cof32.ico, cof16.ico
│   │   └── [additional icon variants]
│   ├── Istruzions.chm         # Help documentation
│   └── dr.bmp, dv.bmp         # UI graphics
├── dict/
│   └── empty                   # Placeholder file (dictionaries not included)
├── Build.PL                    # Perl build configuration
├── MANIFEST                    # File manifest
├── META.json, META.yml         # Package metadata
└── cof.bat                     # Windows launcher script
```

### Enhanced Repository (current branch)
Modern additions while preserving original structure in flat hierarchy:

```
├── README.md                   # This documentation
├── CHANGELOG.md                # Version history based on Git tags
├── AGENTS.md                   # Contribution guidelines  
├── .gitattributes              # Git LFS configuration
├── .github/                    # GitHub integration
├── validation/                 # Validation and compatibility testing
│   ├── README.md               # Validation suite documentation
│   ├── ground_truth/           # COF ground truth generation
│   │   ├── generate_ground_truth.py # Reference result generator
│   │   └── results/            # Generated ground truth files
│   ├── compatibility/          # Compatibility validation
│   │   ├── validate_compatibility.py # Validation suite
│   │   └── reports/            # Validation reports
│   └── fixtures/               # Test data and word lists
├── lib/COF/DataCompat.pm       # 🆕 DB_File-free compatible version

├── [original files]            # All COF-2.16 files at root level
├── dict/                       # Enhanced dictionary folder
│   ├── empty                   # Original placeholder (preserved)
│   ├── words.db                # Main dictionary (627MB) [Git LFS]
│   ├── words.rt                # RadixTree index (30MB) [Git LFS]
│   ├── frec.db                 # Frequency data (2.6MB) [Git LFS]
│   ├── elisions.db             # Elision rules (332KB) [Git LFS]
│   └── errors.db               # Error patterns (12KB) [Git LFS]
├── res/icons/
│   ├── [original .ico files]   # Preserved unchanged
│   └── cof128.png              # Converted logo for README
├── tests/                      # Test suite (646 total tests)
│   ├── test_core.pl            # Core functionality, compatibility, database (129 tests)
│   ├── test_worditerator.pl    # WordIterator comprehensive tests (67 tests)
│   ├── test_suggestions.pl     # Component integration & suggestions (50 tests)
│   ├── test_radix_tree.pl      # RadixTree functionality (72 tests)
│   ├── test_suggestion_ranking.pl # Suggestion ranking validation (51 tests)
│   ├── test_utilities.pl       # Encoding, CLI, legacy data (37 tests)
│   ├── test_phonetic_algorithm.pl # Phonetic algorithm validation (231 tests)
│   ├── test_known_bugs.pl      # Known behavior documentation (9 tests)
│   └── run_all_tests.pl        # Unified test suite runner
├── util/                       # Support utilities (parameterized)
│   ├── spellchecker_utils.pl   # SpellChecker suggestions with CLI options
│   ├── radixtree_utils.pl      # RadixTree suggestions with CLI options
│   ├── encoding_utils.pl       # UTF-8 encoding diagnostics with CLI
│   ├── database_utils.pl       # Database management utilities
│   └── README.md               # Utility documentation and usage examples
├── legacy/                     # Historical reference files
│   ├── 00-contenuto.txt        # Original content description
│   ├── lemis_cof_2015.txt      # Historical word lemmas (24,266 entries)
│   └── peraulis_cof_2015.txt   # Historical vocabulary list (1M+ words)
└── temp/                       # Temporary output files (ignored by git)
```

### 🔧 Compatibility Files

**Primary Solution**: Fix BerkeleyDB PATH configuration (`$env:PATH += ";C:\Strawberry\c\bin"`) to enable full `COF::Data` functionality.

**Fallback Solution**: When PATH configuration is not feasible, we provide `COF::DataCompat`:

```
lib/COF/DataCompat.pm           # Drop-in replacement for COF::Data
                                # - Complete phalg_furlan algorithm  
                                # - Uses SDBM_File (standard Perl)
                                # - No BerkeleyDB dependency
                                # - Limited dictionary features
```

**Recommendation Hierarchy**:
1. ✅ **COF::Data with PATH fix** (preferred): Full functionality with proper BerkeleyDB
2. 🔧 **COF::DataCompat** (fallback): Algorithm compatibility with limited features
3. ⚠️ **Manual workarounds** (deprecated): Use DataCompat instead

**Key Features of Compatibility Version**:
- ✅ **100% Algorithm Parity**: Identical phonetic results to original
- ✅ **Cross-Platform**: Works on any Perl installation 
- ✅ **Zero Additional Dependencies**: Uses only standard Perl modules
- ⚠️ **Reduced Functionality**: Dictionary operations limited
- 🎯 **Primary Use Case**: Phonetic algorithm integration when full setup is not possible
```

### Dictionary Database
The original COF distribution included only an `empty` placeholder in `dict/`. This enhanced repository provides the complete Friulian dictionary set (630MB total) managed via Git LFS:

- **words.db** (627MB): Main vocabulary database (~600K words)
- **words.rt** (30MB): RadixTree index for fast prefix matching  
- **frec.db** (2.6MB): Word frequency statistics for suggestion ranking
- **elisions.db** (332KB): Elision and contraction rules
- **errors.db** (12KB): Common spelling error patterns

> 📦 **Git LFS Required**: Dictionary files use Git Large File Storage. Install with: `git lfs install && git lfs pull`

## Testing Framework

The repository includes comprehensive test suites for COF validation (646 tests) and external compatibility testing tools for modern spell checker implementations.

### Internal Test Suites (`tests/`)

| Test Suite | Tests | Coverage |
|------------|-------|----------|
| **test_core.pl** | 129 | Core functionality, compatibility layer, database integration |
| **test_worditerator.pl** | 67 | WordIterator logic, Unicode handling, edge cases |
| **test_suggestions.pl** | 50 | Component integration and suggestion algorithm |
| **test_radix_tree.pl** | 72 | RadixTree structure, lookups, suggestions, performance |
| **test_suggestion_ranking.pl** | 51 | Exact suggestion order validation with multi-factor ranking |
| **test_utilities.pl** | 37 | Encoding, CLI validation, legacy data handling |
| **test_phonetic_algorithm.pl** | 231 | Comprehensive phonetic algorithm validation |
| **test_known_bugs.pl** | 9 | Known behavior documentation |
| **Total** | **646** | **Complete COF functionality validation** |

#### Test Coverage Areas
- **Core Functionality**: Database availability, initialization, basic operations
- **Backwards Compatibility**: COF::DataCompat without DB_File dependency
- **Phonetic Algorithm**: phalg_furlan hash generation and consistency
- **Text Processing**: WordIterator tokenization, Unicode normalization
- **Dictionary System**: RadixTree, user dict, exceptions, frequencies
- **Suggestion Engine**: Ranking algorithms, edit distance, phonetic matching
- **Edge Cases**: Empty inputs, special characters, boundary conditions
- **Character Handling**: UTF-8 support for Friulian characters (àèìòù, ç, etc.)

### Compatibility Testing Suite (`validation/`)

The validation framework provides tools for testing other Friulian spell checker implementations against COF as the authoritative reference:

#### Ground Truth Generation (`validation/ground_truth/`)
- **`generate_ground_truth.py`**: Creates reference results using COF Perl implementation
- **Input Support**: JSON test cases, plain text word lists, or default Friulian words
- **Output Formats**: JSON (machine-readable), TSV (analysis), and statistics files
- **Batch Processing**: Handles large word lists efficiently

#### Compatibility Validation (`validation/compatibility/`)
- **`validate_compatibility.py`**: Compares other implementations against COF results
- **Supported Checkers**: FurlanSpellChecker (Python), custom executables
- **Metrics**: Correctness matches, suggestion similarity, overall compatibility
- **Detailed Reports**: Markdown reports with failed cases and improvement recommendations

#### Usage Examples
```bash
# Generate ground truth from test words
cd validation/ground_truth
python generate_ground_truth.py ../fixtures/test_words.txt

# Validate FurlanSpellChecker compatibility
cd ../compatibility
python validate_compatibility.py furlanspellchecker

# View compatibility report
cat reports/furlanspellchecker_compatibility_report_*.md
```

**Key Benefits**:
- **Objective Validation**: Real COF results, not mock/fake data
- **Regression Testing**: Detect algorithm changes in implementations
- **Performance Benchmarking**: Compare speed and accuracy across implementations
- **Development Guidance**: Identify specific areas needing improvement

See [`validation/README.md`](validation/README.md) for comprehensive documentation.

## Troubleshooting

### DB_File Issues on Windows

**Error**: `Can't load 'auto/DB_File/DB_File.xs.dll'` or similar BerkeleyDB errors.

**Root Cause**: Strawberry Perl includes BerkeleyDB libraries but they may not be in the system PATH.

**Solution Steps**:

1. **Verify the problem:**
   ```powershell
   perl -MDB_File -e "print 'OK\n'"
   # Should show: Can't load 'auto/DB_File/DB_File.xs.dll'
   ```

2. **Locate BerkeleyDB libraries:**
   ```powershell
   dir C:\Strawberry\c\bin\*db*.dll
   # Should find: libdb-6.2__.dll or similar
   ```

3. **Fix PATH for current session:**
   ```powershell
   $env:PATH += ";C:\Strawberry\c\bin"
   perl -MDB_File -e "print 'DB_File loaded successfully\n'"
   ```

4. **Make permanent (recommended):**
   - Open System Properties → Advanced → Environment Variables
   - Edit user or system PATH variable
   - Add: `C:\Strawberry\c\bin`
   - Restart PowerShell/terminal

5. **Verify fix:**
   ```powershell
   perl -I COF\lib COF\tests\test_suggestions.pl
   # Should run without DataCompat fallbacks
   ```

**Alternative**: If PATH fix is not feasible, use `COF::DataCompat` as documented in compatibility sections above.

## Running Tests

The repository includes a comprehensive test suite with 646 tests covering all COF functionality:

```bash
# Run all tests with integrated runner (recommended):
cd tests
perl run_all_tests.pl         # Complete test suite (646 tests)

# Run individual test suites:
perl test_core.pl                      # Core & database (129 tests)
perl test_worditerator.pl              # WordIterator (67 tests)
perl test_suggestions.pl               # Suggestions & components (50 tests)
perl test_radix_tree.pl                # RadixTree (72 tests)
perl test_suggestion_ranking.pl        # Ranking validation (51 tests)
perl test_utilities.pl                 # Utilities (37 tests)
perl test_phonetic_algorithm.pl        # Phonetic algorithm (231 tests)
perl test_known_bugs.pl                # Known behavior (9 tests)
```

The test suite validates the correctness, reliability, and behavior of the COF implementation across all components.

## Historical Context

COF was developed as part of efforts to preserve and promote the Friulian language through digital tools. The phonetic algorithm represents years of linguistic research into Friulian phonology and orthography patterns.

This codebase serves as the reference implementation for:
- Cross-platform Friulian spell checkers
- Phonetic similarity algorithms for minority languages
- Dictionary management systems for agglutinative languages
- Academic research into computational linguistics for Friulian

## Contributing

**The original source code (`master` and `original` branches) should not be modified.**

### Branch Protection Status:
- 🔒 **`master`**: Protected - requires pull requests for merges, evolves with accepted changes from develop
- 🔒 **`original`**: Completely locked - read-only, preserves pure original COF source code
- 🔓 **`develop`**: Open for active development work

### Development Workflow:
1. **Active development**: Work directly in `develop` branch or create feature branches from `develop`
2. **Contributing to master**: Create pull requests from `develop` to `master` (protection rules apply)
3. **Derivative projects**: Fork this repository for new implementations (e.g., Python, JavaScript ports)
4. **Algorithm validation**: Maintain compatibility with original `phalg_furlan` and use the test suite

## License

Original COF software by Franz Feregot. Please respect the original licensing terms and acknowledge this reference implementation in derivative works.

## Related Projects

- **[FurlanSpellChecker](https://github.com/daurmax/FurlanSpellChecker)**: Modern Python implementation based on this reference

---

*This README documents the original COF implementation for preservation and reference purposes. The software represents an important milestone in Friulian computational linguistics.*