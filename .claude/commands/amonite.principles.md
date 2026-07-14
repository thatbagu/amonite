---
description: Establish or amend the project's persistent principles (constitution)
---

Establish the project constitution in `.amonite/principles.md`.

1. If the file has `[REPLACE]` placeholders, interview the user briefly
   (product values, engineering norms, hard limits) and fill them.
2. Never weaken E1–E3 or N1 (mechanical verification, explicit impurity,
   minimal env grants, green flake check) — they are amonite invariants.
3. If amending an existing constitution, show a diff of the change and the
   reason before writing.
4. Every later phase re-reads this file; keep entries short, testable,
   and free of aspiration-speak.

User input: $ARGUMENTS
