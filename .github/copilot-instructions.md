# Copilot instructions for this repository

This repository uses an internal developer guide called `AGENTS.md`. Use that file as the single source of truth for project conventions, test workflow and developer responsibilities before making changes.

Key pointers for Copilot assistants and automated edits:

- Reference: `AGENTS.md` at the repository root describes coding standards, test philosophy, file layout, and the `util/` conventions. Always read it before proposing or applying changes.
- Utilities: Helper scripts live under `util/` and follow the `_utils` naming convention (for example `spellchecker_utils.pl`, `radixtree_utils.pl`, `encoding_utils.pl`). Prefer those utilities for extracting test fixtures and diagnosing encoding issues.
- Tests: Unit tests live under `tests/`. Tests are the canonical verification of behavior — do not modify tests without a corresponding change to code or a documented rationale.
- Temp files: Put temporary outputs in the `temp/` directory (git-ignored). Never commit test output or temporary artifacts.
- Encoding: Respect UTF-8 for input/output. AGENTS.md explains how to diagnose and handle special Friulian characters like `ç` (U+00E7).
- Committing & PRs: Create small, focused commits with clear messages. Update `CHANGELOG.md` with an `Unreleased` entry describing user-visible changes before opening a pull request. Mention `AGENTS.md` where relevant in PR descriptions.
- **Historical Preservation**: NEVER modify historical changelog entries or original structure descriptions. When repository structure changes, only update current operational instructions and add new changelog entries without altering existing ones. Historical path references (like `COF-2.16/`) must be preserved in old documentation.

Examples (run from repository root):

```bash
# Inspect spellchecker suggestions in array format for embedding into tests
perl util/spellchecker_utils.pl --suggest cjupe --format array

# Inspect radix-tree suggestions as JSON
perl util/radixtree_utils.pl --word cjupe --format json

# Diagnose encoding for spellchecker suggestions
perl util/encoding_utils.pl --suggest cjupe
```

If you are unsure, stop and reference `AGENTS.md` or ask a human reviewer.
