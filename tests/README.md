# COF Test Suite

Questa directory contiene l'intera test suite consolidata del progetto COF. È l'unica fonte autorevole per l'esecuzione dei test. Nessun test runner vive più in `util/`.

## Obiettivi della suite
- Validare il comportamento del correttore ortografico Friulano end-to-end
- Coprire struttura RadixTree, hashing fonetico, iteratori, encoding e DB
- Assicurare robustezza su input non validi, edge cases e caratteri Unicode
- Verificare che l'interfaccia CLI gestisca errori e parametri incorretti

## File di test
| File | Scopo sintetico |
|------|-----------------|
| `test_spell_checker.pl` | Verifica parole, suggerimenti, risposta per termini inesistenti |
| `test_radix_tree.pl` | Struttura RT, ricerca, suggerimenti basati su distanza |
| `test_phonetic_perl.pl` | Coerenza algoritmo fonetico `phalg_furlan` |
| `test_worditerator.pl` | Tokenizzazione, Unicode, delimitatori, casi limite |
| `test_database.pl` | Lookup, integrità key/value, gestione errori DB_File |
| `test_encoding.pl` | Gestione UTF-8, sequenze invalide, rilevazione corruzione |
| `test_fastchecker.pl` | Stato interno, riutilizzo, coerenza risposta |
| `test_rtchecker.pl` | Suggestion logic, gestione memoria, continuità |
| `test_cli_parameter_validation.pl` | Validazione parametri CLI, messaggi errore, I/O |

## Runner principale
Eseguire tutti i test:
```bash
perl tests/run_all_tests.pl
```
Può essere lanciato anche da dentro la directory:
```bash
cd tests && perl run_all_tests.pl
```
Exit code 0 = tutti i test passano, 1 = almeno una suite fallita.

## Convenzioni
- Ogni file definisce una singola unità logica di copertura
- Niente logica di business dentro i test (solo orchestrazione + asserzioni)
- Nomi: `test_<component>.pl` (minuscolo, underscore se necessario)
- Output: formato TAP standard (Test::More)

## Aggiungere un nuovo test
1. Scegli un nome coerente: `test_<nuovocomponente>.pl`
2. Inizia con:
   ```perl
   use strict; use warnings; use utf8; use Test::More;
   ```
3. Copri un solo asse concettuale (evita multi-component mashup)
4. Mantieni le `plan tests => N` accurate (o usa `done_testing`) 
5. Evita dipendenze esterne non necessarie

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
