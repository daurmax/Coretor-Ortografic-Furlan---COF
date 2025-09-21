# COF Test Suite

This directory contains the consolidated test suite for the COF (Coretor Ortografic Furlan) project. 

## Test Structure

The test suite has been organized into 4 logical test files that comprehensively cover all COF functionality:

### Core Test Files

| File | Tests | Purpose |
|------|--------|---------|
| `test_core_functionality.pl` | 46 | Database connectivity, SpellChecker, phonetic algorithms |
| `test_components.pl` | 22 | FastChecker and RTChecker component testing |
| `test_utilities.pl` | 37 | Encoding, CLI validation, legacy data handling |
| `test_worditerator.pl` | 67 | WordIterator functionality and text processing |

### Test Runner

- **`run_all_tests.pl`** - Unified test suite runner for all 4 test files

## Running Tests

### Individual Test Files
```bash
perl test_core_functionality.pl
perl test_components.pl  
perl test_utilities.pl
perl test_worditerator.pl
```

### Complete Test Suite
```bash
perl run_all_tests.pl
```

## Test Philosophy

All tests follow these principles:
- **Real Database Testing**: Core tests use actual COF databases for integration testing
- **Graceful Component Handling**: Component tests handle optional modules gracefully  
- **Robust Error Handling**: All eval blocks use proper error checking patterns
- **Comprehensive Coverage**: Tests cover normal operations, edge cases, and error conditions
- **TAP Compliance**: All tests use Test::More with proper TAP output

## Test Results Summary

- **Total Tests**: 172 tests across all suites
- **Expected Results**: All tests should pass with proper COF installation
- **Database Dependencies**: Core tests require COF dictionaries in `../dict/` directory
- **Component Dependencies**: Component tests handle missing FastChecker/RTChecker gracefully

## Maintenance

This consolidated structure replaces the previous 17+ individual test files, providing:
- Better organization and maintainability
- Logical grouping of related functionality
- Reduced test suite complexity
- Improved test execution performance
- Cleaner directory structure following AGENTS.md guidelines

## Linee guida qualità
- Test chiari: ogni `ok` / `is` deve spiegare il perché
- Nessun debug `print` residuo (usa `diag` se strettamente necessario)
- Evitare ordini non deterministici (sort esplicito se serve)
- Coprire: percorso positivo, negativo, edge-case minimo, edge-case estremo

## Cosa NON fare
- Spostare di nuovo runner in `util/`
- Aggiungere script di esecuzione duplicati
- Mischiare generazione dati con asserzioni — predisponi helper separati se cresce

## Futuri miglioramenti (opzionale)
- Aggiungere test performance separati (es: `perf/` directory dedicata)
- Integrare coverage (Devel::Cover) per analisi estesa
- Pipeline CI automatica

## Supporto
Per diagnosticare comportamento interno: usa gli strumenti in `util/` (`spellchecker_utils.pl`, `radixtree_utils.pl`, `encoding_utils.pl`).

---
Mantieni questa directory pulita e focalizzata: un singolo runner, test granulari, nessun rumore.
