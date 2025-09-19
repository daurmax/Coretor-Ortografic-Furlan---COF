# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [v2.19] - 2025-09-19

### Added
- **CHANGELOG.md**: Comprehensive version history based on Git tags and commit history
- **Complete Documentation**: Professional changelog following Keep a Changelog format

### Fixed
- **README Accuracy**: Documentation now reflects actual repository state
- **File Structure**: Corrected references to removed `empty` placeholder file
- **Historical Attribution**: Clear distinction between original and enhanced content

### Changed
- **Version Management**: Moved version-specific information from README to dedicated CHANGELOG
- **Professional Standards**: Adopted industry-standard documentation practices

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