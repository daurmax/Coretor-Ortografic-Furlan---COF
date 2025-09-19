# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

## [v2.21] - 2025-09-19

### Changed
- **Repository Structure Flattening**: Eliminated nested `COF-2.16/` directory structure
  - All original files moved to repository root for cleaner organization
  - Legacy files (2015 lemma and vocabulary data) organized in `legacy/` directory  
  - Updated all current path references in documentation while preserving historical descriptions
  - Preserved full functionality with simplified directory hierarchy

### Added
- **Continuous Integration**: GitHub Actions pipeline for automated testing
  - Test suite execution on every commit and pull request
  - Cross-platform testing (Ubuntu and Windows)
  - Automatic Perl environment setup and dependency installation
  - Utility script validation as part of CI process

### Fixed
- **Historical Documentation Preservation**: Enhanced guidelines to prevent modification of historical entries
  - Added explicit rules in `AGENTS.md` about preserving historical changelog entries and original structure descriptions
  - Updated `.github/copilot-instructions.md` with warnings about historical integrity
  - Corrected approach to only update current operational paths, not historical documentation

## [v2.20] - 2025-09-19

### Added
- **Comprehensive Test Suite**: Complete validation framework for COF functionality (76 total tests)
  - `test_radix_tree.pl`: RadixTree/RT_Checker functionality tests (9 tests)
  - `test_spell_checker.pl`: SpellChecker word validation and suggestions (5 tests with static expected results)
  - `test_key_value_database.pl`: Database lookup validation (15 tests including edge cases)
  - `test_phonetic_perl.pl`: Phonetic algorithm validation (47 tests, uniformed with Test::More)
  - `run_all_tests.pl`: Integrated test runner for comprehensive validation
- **Parameterized Utility Scripts**: CLI-enabled utilities for test data extraction and diagnostics
  - `spellchecker_utils.pl`: SpellChecker suggestions with --suggest/--word/--file/--format options (list|array|json)
  - `radixtree_utils.pl`: RadixTree suggestions with --word/--file/--format options  
  - `encoding_utils.pl`: UTF-8/Unicode encoding diagnostics with --suggest/--word/--file options
  - `util/README.md`: Usage documentation and examples for all utilities
- **GitHub Copilot Integration**: `.github/copilot-instructions.md` referencing AGENTS.md conventions
- **Documentation Updates**: Enhanced AGENTS.md and README.md with util conventions and examples

### Fixed
- **Professional Output**: Removed emoji from test output, replaced with text-based indicators `[PASS]`/`[FAIL]`
- **Test Philosophy**: Modified tests to accept actual COF results as source of truth
- **Result Alignment**: Updated all test suites to use extracted COF results as expected static values
- **UTF-8 Encoding**: Resolved character display issues with ç (c-cedilla) and other Friulian special characters
- **Documentation Cleanup**: Removed references to C# importing from all test documentation

### Changed
- **COF as Truth Source**: Established COF Perl implementation as authoritative reference for future Python 1:1 compatibility
- **Testing Standards**: Uniformed all test files with professional Test::More framework and proper POD documentation
- **Static Test Values**: All expected results extracted from actual COF behavior and embedded as static test data
- **Project Structure**: Reorganized support files in logical hierarchy:
  - `tests/` - Clean test suite (only test files)
  - `util/` - Support utilities and extraction scripts
  - `temp/` - Temporary output files (git-ignored)
- **Utility Organization**: Consolidated utility scripts with descriptive names (`spellchecker_utils.pl`, `radixtree_utils.pl`, `encoding_utils.pl`) for clear scope identification

## [v2.19] - 2025-09-19

### Added
- **CHANGELOG.md**: Comprehensive version history based on Git tags and commit history
- **Complete Documentation**: Professional changelog following Keep a Changelog format
- **Comprehensive Test Suite**: Imported and validated C# test suites into Perl Test::More framework
  - `test_radix_tree.pl`: RadixTree/RT_Checker functionality tests (8 tests from RT_CheckerFixture.cs)
  - `test_spell_checker.pl`: SpellChecker word validation and suggestions (5 tests from FurlanSpellCheckerFixture.cs)
  - `test_key_value_database.pl`: Database lookup validation (8 tests from KeyValueDatabaseFixture.cs)
  - `run_all_tests.pl`: Integrated test runner for comprehensive validation (21 total tests)

### Fixed
- **README Accuracy**: Documentation now reflects actual repository state
- **File Structure**: Corrected references to removed `empty` placeholder file
- **Historical Attribution**: Clear distinction between original and enhanced content
- **Test Coverage**: Validated Perl implementation correctness against C# reference behavior
- **Database Integration**: Confirmed proper connectivity and functionality of all dictionary databases

### Changed
- **Version Management**: Moved version-specific information from README to dedicated CHANGELOG
- **Professional Standards**: Adopted industry-standard documentation practices
- **Quality Assurance**: Added comprehensive testing to ensure implementation reliability

## [v2.18] - 2025-09-19

### Fixed
- **Repository Structure**: Moved README.md, AGENTS.md, and .gitattributes to repository root for proper GitHub functionality
- **File Paths**: Updated all internal path references to reflect corrected structure
- **Documentation Accuracy**: Corrected README to distinguish between original and enhanced content
- **Historical Accuracy**: Clarified what files were original vs additions

### Changed
- Repository now properly follows GitHub standards with root-level documentation
- Git LFS configuration moved to repository root for proper functionality

## [v2.17] - 2025-09-19

### Added
- **Documentation**: Comprehensive README.md with project overview, setup instructions, and architecture analysis
- **Contribution Guidelines**: AGENTS.md with conventional commit standards and development workflow
- **Testing Framework**: 47 comprehensive test cases in `COF-2.16/tests/test_phonetic_perl.pl` validating phonetic algorithm accuracy (98% match with original)
- **Dictionary Database**: Complete Friulian language dictionaries with Git LFS support:
  - `words.db` (627MB) - Main vocabulary database
  - `words.rt` (30MB) - RadixTree index for fast lookup
  - `frec.db` (2.6MB) - Word frequency statistics  
  - `elisions.db` (332KB) - Elision and contraction rules
  - `errors.db` (12KB) - Common spelling error patterns
- **Project Branding**: Converted COF logo (`COF-2.16/res/icons/cof128.png`) for README presentation
- **Git LFS Configuration**: `.gitattributes` for efficient handling of large dictionary files

### Changed
- Dictionary folder: replaced single `empty` placeholder with complete database set
- Branch workflow established: `original` (preserved) → `master` (stable) → `develop` (active)

### Technical Details
- **Cross-validation**: Phonetic algorithm tested against original Perl implementation
- **Historical Preservation**: Original Franz Feregot code completely unchanged in `original` branch
- **Git LFS**: Large files managed efficiently for repository cloning
- **Windows Setup**: Complete installation instructions using Strawberry Perl and Chocolatey

## [v2.16-original] - 2025-09-19

### Preserved
- **Original Source Code**: Franz Feregot's complete COF v2.16 implementation
  - Version: 2.16 (built 20110620)
  - Lemmas version: 20150417
  - All original Perl modules in `COF-2.16/lib/COF/`
  - GUI and CLI scripts: `cof.pl`, `cof_oo_cli.pl`
  - OpenOffice.org integration plugin
  - Original icons and resources
  - Build configuration (`Build.PL`)

### Structure (Original)
```
COF-2.16/
├── lib/COF/              # 16 Perl modules for spell checking
├── script/               # GUI and CLI executables
├── COFOOPlugin/          # OpenOffice.org integration
├── res/                  # Icons, help files, resources
├── dict/                 # Contains only 'empty' placeholder
├── Build.PL              # Build configuration
├── MANIFEST              # File manifest
├── META.json/META.yml    # Metadata
└── cof.bat              # Windows batch launcher
```

## [v0.0.0-baseline] - 2021-04-20

### Added
- **Initial Commit**: Empty repository baseline
- **Historical Reference**: Starting point for all enhancements

---

## Development Workflow

- **`original` branch**: Locked preservation of Franz Feregot's work
- **`master` branch**: Stable releases with protection rules requiring PR approval
- **`develop` branch**: Active development with new features and improvements

## Attribution

Original COF (Coretôr Ortografic Furlan) developed by **Franz Feregot**.
Enhancements and modernization by Massimo Romanin while preserving original algorithm integrity.