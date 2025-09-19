Utilities in this folder follow the `_utils` convention and are intended for test data extraction and diagnostics.

Available utilities:

- `spellchecker_utils.pl` - Run COF spellchecker and output suggestions. Supports options:
  - `--suggest WORD` run the spellchecker and inspect suggestions
  - `--word WORD` inspect the given word directly
  - `--file FILE` read words (one per line) from FILE
  - `--format list|array|json` choose output format (default `list`)
  - `--list` print only the words, one per line

- `radixtree_utils.pl` - Extract suggestions from the radix tree for one or more words. Supports options:
  - `--word WORD` inspect suggestions for WORD
  - `--file FILE` read words from FILE
  - `--format list|array|json` choose output
  - `--list` prints only suggestions, one per line

- `encoding_utils.pl` - Inspect UTF-8/Unicode encodings for given words or spellchecker suggestions. Supports options:
  - `--suggest WORD` run spellchecker and inspect suggestions
  - `--word WORD` inspect the given word
  - `--file FILE` read words from FILE
  - `--nohex` do not show UTF-8 hex bytes
  - `--nounicode` do not show Unicode code points

Examples:

```bash
perl util/spellchecker_utils.pl --suggest cjupe
perl util/spellchecker_utils.pl --suggest cjupe --format array
perl util/radixtree_utils.pl --word cjupe --format json
perl util/encoding_utils.pl --suggest cjupe
```
