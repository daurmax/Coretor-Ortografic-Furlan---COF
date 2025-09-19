# COF - Coretôr Ortografic Furlan

<div align="center">
  <img src="COF-2.16/res/icons/cof128.png" alt="COF Logo" width="128" height="128">
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

**Original files** (from initial commit 01ad001, April 20, 2021):
- Core Perl modules in `lib/COF/`
- GUI and CLI scripts: `script/cof.pl`, `script/cof_oo_cli.pl`
- OpenOffice plugin in `COFOOPlugin/`
- Resources and icons in `res/`
- Dictionary files in `COF-2.16/dict/`
- Build configuration files

**Files added for testing and documentation**:
- `README.md` - This documentation
- `tests/test_phonetic_perl.pl` - Phonetic algorithm test suite (47 test cases)
- `AGENTS.md` - Contribution guidelines for developers and AI agents
- `.gitattributes` - Git LFS configuration for dictionary files

## Architecture

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
cd "path\to\COF\COF-2.16"

# Install required Perl modules
cpan install Params::Validate
cpan install File::HomeDir  
cpan install Wx
cpan install Wx::Perl::ListCtrl
cpan install Try::Tiny
cpan install Carp::Always
```

### Clone Repository with LFS

```powershell
# Clone repository and download LFS files
git clone https://github.com/daurmax/COF.git
cd COF/COF-2.16
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

## File Structure

### Original Structure (from initial commit)
```
COF-2.16/
├── lib/COF/           # Core Perl modules (original)
│   ├── Data.pm        # Dictionary management & phonetic algorithm
│   ├── SpellChecker.pm # Main spell checking logic
│   ├── FastChecker.pm  # Text processing engine
│   ├── RadixTree.pm    # Dictionary storage structure
│   ├── App.pm          # GUI application
│   └── [12 other modules]
├── script/            # Original executable scripts
│   ├── cof.pl         # GUI launcher
│   └── cof_oo_cli.pl  # Command-line interface
├── COFOOPlugin/       # OpenOffice.org integration plugin
├── dict/              # Dictionary files (📦 Git LFS)
│   ├── words.db       # Main Friulian dictionary (627MB)
│   ├── words.rt       # RadixTree index (30MB)
│   ├── frec.db        # Frequency dictionary (2.6MB)
│   ├── elisions.db    # Elision rules (332KB)
│   └── errors.db      # Common errors (12KB)
├── res/               # Resources (icons, help files)
│   └── icons/         # Application icons
│       ├── cof128.ico # Original Windows icon (128x128)
│       ├── cof128.png # README logo (converted from ICO)
│       └── [other sizes] # 16x16, 32x32, 48x48 variants
└── Build.PL           # Build configuration
```

### Development Additions (this branch)
```
├── tests/             # Test suites (added)
│   └── test_phonetic_perl.pl  # Phonetic algorithm tests (47 cases)
├── AGENTS.md          # Contribution guidelines (added)
├── .gitattributes     # Git LFS configuration (added)
├── README.md          # This documentation (added)
└── res/icons/cof128.png # Project logo for README (converted from ICO)
```

### Dictionary Files (Git LFS)
The `COF-2.16/dict/` folder contains the essential Friulian dictionaries required for COF operation:
- **words.db** (627MB): Main vocabulary database with ~600K words
- **words.rt** (30MB): RadixTree index for fast prefix matching
- **frec.db** (2.6MB): Word frequency statistics for ranking suggestions
- **elisions.db** (332KB): Elision and contraction rules
- **errors.db** (12KB): Common spelling error patterns

> 📦 **Note**: Dictionary files are stored using **Git LFS** (Large File Storage) due to their size. Ensure Git LFS is installed when cloning: `git lfs install && git lfs pull`

## Testing the Phonetic Algorithm

The repository includes a comprehensive test suite for the phonetic algorithm with 47 test cases covering:

- **Basic Words**: Common Friulian vocabulary
- **Diphthongs**: ai, ei, ou, oi, vu sequences  
- **Consonant Clusters**: cj, gj, sci/sce patterns
- **Accented Characters**: à/â/á, è/ê/é variations
- **Edge Cases**: Start-of-word consonants, special endings

```powershell
# Run phonetic tests
perl tests/test_phonetic_perl.pl

# Expected output format:
# word -> ("hash1", "hash2")
# cjatâ -> ("A696", "c7696")
```

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