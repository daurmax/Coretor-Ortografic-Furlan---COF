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

### Testing Requirements
- **Reference validation**: All phonetic algorithm changes must pass existing test suite
- **Cross-platform**: Ensure compatibility across development environments
- **Regression testing**: Prevent breaking existing functionality
- **Documentation**: Update test documentation with new test cases

### AI Agent Considerations
- **Context preservation**: Maintain understanding of repository's historical significance
- **Careful modifications**: Prefer additive changes over modifications
- **Documentation first**: Document before implementing
- **Test validation**: Always validate against original Perl implementation

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

---

*This document ensures consistent, high-quality contributions while preserving the historical and technical integrity of the original COF implementation.*