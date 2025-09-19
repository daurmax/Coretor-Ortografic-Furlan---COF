# Continuous Integration

This project uses GitHub Actions for automated testing on every commit and pull request.

## Pipeline Overview

The CI pipeline runs on two platforms:
- **Ubuntu Latest**: For Linux compatibility testing
- **Windows Latest**: For Windows compatibility testing (using Strawberry Perl)

## Test Process

### 1. Environment Setup
- Checkout code with Git LFS support (for dictionary files)
- Install Perl with fallback strategies:
  - Primary: `shogo82148/actions-setup-perl@v1.31.3` (Ubuntu/Windows)
  - Fallback Ubuntu: System Perl + cpanminus via apt-get
  - Fallback Windows: Strawberry Perl via Chocolatey
- Install required system dependencies
- Install Perl module dependencies

### 2. Build Process
- Run `perl Build.PL` to configure the build
- Run `perl Build` to build the project
- Graceful fallback if GUI dependencies (Wx) are unavailable in headless environment

### 3. Test Execution
- **Core Test Suite**: Run all tests via `tests/run_all_tests.pl`
  - Phonetic algorithm validation (47 tests)
  - RadixTree functionality (9 tests)  
  - SpellChecker validation (5 tests)
  - Key-Value database tests (15 tests)
- **Utility Validation**: Test all CLI utilities
  - `spellchecker_utils.pl` with JSON output
  - `radixtree_utils.pl` with JSON output
  - `encoding_utils.pl` for character diagnostics

## Dependencies

### Required Perl Modules
- `Module::Build` - Build system
- `Test::More` - Testing framework
- `Params::Validate` - Parameter validation
- `File::HomeDir` - Home directory detection
- `Try::Tiny` - Exception handling
- `Carp::Always` - Enhanced error reporting
- `Getopt::Long` - Command line parsing
- `JSON::PP` - JSON processing
- `Pod::Usage` - Documentation extraction
- `File::Spec` - Cross-platform file operations
- `DB_File` - Berkeley DB interface (critical for dictionary access)
- `GDBM_File` - GDBM database interface

### Optional Dependencies
- `Wx` and `Wx::Perl::ListCtrl` - GUI components (skipped in CI)

## Configuration Files

- `.github/workflows/test.yml` - Main CI configuration
- `Build.PL` - Perl build configuration
- `MANIFEST` - File manifest for distribution

## Triggering Tests

Tests run automatically on:
- Push to `main`, `master`, or `develop` branches
- Pull requests targeting `main`, `master`, or `develop` branches

## Viewing Results

1. Go to the repository's **Actions** tab
2. Click on the latest workflow run
3. Expand job logs to see detailed test results
4. Failed tests will show specific error messages and locations

## Local Testing

To run the same tests locally:

```bash
# Install dependencies
cpanm --installdeps .

# Build project
perl Build.PL
perl Build

# Run full test suite
cd tests
perl run_all_tests.pl

# Test utilities individually
perl util/spellchecker_utils.pl --suggest cjupe --format json
perl util/radixtree_utils.pl --word cjupe --format json
perl util/encoding_utils.pl --suggest cjupe
```

## Troubleshooting

### Common Issues

1. **Build fails due to Wx dependencies**
   - CI gracefully continues without GUI components
   - Core functionality and tests still validate

2. **Git LFS files not available**
   - Ensure Git LFS is properly configured
   - Dictionary files are required for full test suite

3. **Perl version incompatibility**
   - Pipeline uses Perl 5.34 for consistency
   - Ensure local environment matches for reliable results

4. **DB_File module missing**
   - Install system dependencies: `sudo apt-get install libdb-dev libgdbm-dev`
   - Install Perl module: `cpanm DB_File`
   - Critical for accessing dictionary database files

5. **Missing dict/empty file**
   - Pipeline creates this placeholder file automatically
   - Required by original MANIFEST for build compatibility

6. **Perl setup action failure**
   - Pipeline has automatic fallbacks for Perl installation
   - Ubuntu: Falls back to system Perl via apt-get
   - Windows: Falls back to Chocolatey Strawberry Perl installation
   - Usually resolves automatically without intervention

### Modifying the Pipeline

When updating `.github/workflows/test.yml`:
1. Test changes in a feature branch first
2. Check both Ubuntu and Windows job success
3. Verify all test categories still execute
4. Update this documentation if adding new test steps