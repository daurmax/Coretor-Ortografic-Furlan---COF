# COF - Agent Contribution Guidelines

## Overview

This document provides guidelines for AI agents and contributors working on the COF (Coretôr Ortografic Furlan) project. The repository preserves the original Friulian spell checker while enabling careful development and documentation improvements.

## Repository Structure & Branch Protection

### Branch Hierarchy
- **`original`**: 🔒 **Completely locked** - Historical reference, pure original COF source code
- **`master`**: 🔒 **Protected** - Stable branch with original code + accepted changes, requires pull requests
- **`develop`**: 🔓 **Open** - Active development branch for features, documentation, and testing

### Development Workflow
1. **Active Development**: Work in `develop` branch or feature branches from `develop`
2. **Integration**: Submit pull requests from `develop` to `master` for stable integration
3. **Historical Preservation**: Never modify `original` branch (completely locked)

## Git Commit Guidelines

We follow strict commit message formatting for maintainability and automated changelog generation.

### Commit Message Format
```
<type>(<scope>): <subject>
<BLANK LINE>
<body>
<BLANK LINE>
<footer>
```

**Rules:**
- Header is mandatory, scope is optional
- No line longer than 100 characters
- Use imperative, present tense ("add" not "added")
- No capitalization of first letter in subject
- No period at end of subject

### Commit Types
- **feat**: New feature implementation
- **fix**: Bug fixes
- **docs**: Documentation changes only
- **test**: Adding or modifying tests
- **refactor**: Code restructuring without functionality changes
- **perf**: Performance improvements
- **style**: Code formatting, whitespace, etc.
- **chore**: Build process, auxiliary tools, maintenance

### Scope Examples
- **README**: Documentation updates
- **phonetic-algorithm**: Phonetic algorithm related changes
- **tests**: Test suite modifications
- **architecture**: Core system architecture
- **build**: Build system and dependencies

### Example Commits
```bash
feat(phonetic-algorithm): add comprehensive test suite validation

docs(README): document branch protection and development workflow

test(phonetic): add 47 test cases covering Friulian transformations

chore(build): update Perl dependencies for Windows compatibility
```

### Breaking Changes
Use footer to document breaking changes:
```
BREAKING CHANGE: phonetic algorithm API changed from get_hash() to get_phonetic_hashes_by_word()
```

## Development Guidelines

### Code Preservation
- **Original COF code**: Must remain unmodified in `original` branch
- **Algorithm compatibility**: Maintain compatibility with original `phalg_furlan` function
- **Cross-validation**: Use test suite to validate any algorithm implementations

### Documentation Standards
- **Comprehensive**: Document architecture, setup, and usage thoroughly
- **Historical context**: Explain COF's significance in Friulian computational linguistics
- **Technical accuracy**: Provide precise algorithm documentation with examples
- **Setup instructions**: Include complete Windows/Perl setup procedures
- **Historical Preservation**: **NEVER modify historical changelog entries or original structure descriptions**
  - When documenting structural changes, add NEW entries without altering existing ones
  - Preserve original path references in historical documentation (e.g., `COF-2.16/` paths in old changelog entries)
  - Update only current operational instructions and documentation, not historical descriptions

### Testing Requirements
- **Reference validation**: All phonetic algorithm changes must pass existing test suite
- **Cross-platform**: Ensure compatibility across development environments
- **Regression testing**: Prevent breaking existing functionality
- **Documentation**: Update test documentation with new test cases

### Support Utilities and Test Infrastructure
- **Utility Scripts**: When test support functions are needed, search in `util/` directory first
- **Existing Tools**: Use existing utilities like `spellchecker_utils.pl`, `encoding_utils.pl` for common tasks
- **New Utilities**: If required functionality doesn't exist, add to appropriate file in `util/` or create new utility file
- **Logical Organization**: Group utilities by scope using the `_utils` convention:
  * `spellchecker_utils.pl` - SpellChecker suggestion extraction and utilities
  * `radixtree_utils.pl` - RadixTree suggestion extraction and utilities  
  * `encoding_utils.pl` - Character encoding and UTF-8 diagnostics
  * `validation_utils.pl` - General validation and testing utilities (future)
- **Temporary Output**: All temporary files and test outputs must go in `temp/` directory (git-ignored)
- **Clean Structure**: Keep `tests/` directory clean with only actual test files

**Utility Usage Examples**

To inspect encoding and suggestions quickly from the command line:

```
perl util/encoding_utils.pl --suggest cjupe
perl util/encoding_utils.pl --word 'þope'
perl util/encoding_utils.pl --file sample_words.txt --nohex

perl util/spellchecker_utils.pl cjupe        # default list output
perl util/spellchecker_utils.pl cjupe array  # print as qw(...) for tests
```

These examples show how to call utilities in `util/` to extract static expected values for tests or diagnose encoding issues.

**Current Support Functions**

The `util/` directory contains comprehensive support functions documented in `util/README.md`. Key utilities include:

- **Phonetic Hash Generation**: `spellchecker_utils.pl --generate-hashes --format=python word1 word2...`
- **Spell Checking**: `spellchecker_utils.pl --suggest WORD` or `--word WORD`  
- **Encoding Analysis**: `encoding_utils.pl --word WORD` for UTF-8 diagnostics
- **RadixTree Testing**: `radixtree_utils.pl --word WORD` for suggestion analysis
- **Text Tokenization**: `worditerator_utils.pl --text TEXT` for word iteration testing

**When Adding Support Functions**:
1. Check if functionality already exists in `util/` directory
2. Review `util/README.md` for current capabilities and usage patterns
3. If new functionality is needed, extend existing utilities or create new ones following the `*_utils.pl` convention
4. Update `util/README.md` with new functionality
5. Use consistent command-line interfaces matching existing utilities

### AI Agent Considerations
- **Context preservation**: Maintain understanding of repository's historical significance
- **Careful modifications**: Prefer additive changes over modifications
- **Documentation first**: Document before implementing
- **Test validation**: Always validate against original Perl implementation
- **Historical Integrity**: When repository structure changes, ONLY update current operational paths
  - Never alter historical changelog entries describing original structure
  - Never modify original structure descriptions in README/documentation
  - Add new sections for current state without changing historical descriptions

## Quality Standards

### Code Quality
- Follow existing Perl coding conventions in original codebase
- Maintain algorithm precision and accuracy
- Preserve original comments and documentation style
- Add comprehensive error handling for new features

### Documentation Quality
- Use clear, technical language appropriate for developers
- Provide working code examples
- Include setup and troubleshooting information
- Maintain consistency with existing documentation style

### Commit Quality
- One logical change per commit
- Clear, descriptive commit messages
- Proper use of conventional commit format
- Include reasoning in commit body when necessary

## Special Considerations

### Friulian Language Preservation
- Respect the cultural and linguistic significance of the project
- Maintain accuracy of Friulian phonetic transformations
- Document linguistic decisions and algorithm rationale
- Preserve original author attribution and historical context

### Cross-Platform Compatibility
- Ensure Windows setup instructions work correctly
- Test Perl dependencies and installation procedures
- Validate file paths and line endings across platforms
- Maintain compatibility with original COF architecture

### Windows Environment Setup

**Permanent Strawberry Perl PATH Configuration**

For global and permanent access to Perl commands, add Strawberry Perl to Windows system PATH:

1. **Open System Environment Variables**:
   - Press `Win + R`, type `sysdm.cpl`, press Enter
   - Click "Environment Variables..." button
   - Or search "Environment Variables" in Start menu

2. **Edit System PATH**:
   - In "System Variables" section, find and select "Path"
   - Click "Edit..." button
   - Click "New" and add: `C:\Strawberry\perl\bin`
   - Click "New" again and add: `C:\Strawberry\c\bin` (for DB_File support)
   - Click "OK" to save all dialogs

3. **Restart Terminal**:
   - Close all PowerShell/CMD windows
   - Open new terminal and verify: `perl --version`

**DB_File Dependency Fix**

The COF project requires DB_File module for Berkeley DB access. If you encounter `DB_File` errors:

**Problem**: `Can't locate loadable object for module DB_File`
**Solution**: Ensure `C:\Strawberry\c\bin` is in PATH (step 2 above includes this)

**Verification Commands**:
```powershell
# Test Perl installation
perl --version

# Test DB_File availability
perl -e "use DB_File; print 'DB_File OK\n';"

# Test COF CLI functionality
cd COF
perl script\cof_oo_cli.pl
```

**Alternative PATH Setting (temporary session)**:
```powershell
# For current session only (not permanent)
$env:PATH += ";C:\Strawberry\perl\bin;C:\Strawberry\c\bin"
```

**Troubleshooting**:
- If `perl` command not found: Strawberry Perl not installed or PATH incorrect
- If `DB_File` errors persist: `C:\Strawberry\c\bin` missing from PATH
- If COF modules not found: Run from COF directory or check `@INC` paths

---

*This document ensures consistent, high-quality contributions while preserving the historical and technical integrity of the original COF implementation.*