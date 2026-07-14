---
description: Decompose the plan into tasks and spawn encapsulated task capsules
---

Create or update `.amonite/tasks.md` from `.amonite/plan.md`, then spawn a
flake capsule per task.

1. Decompose: one task = one unit of work with a clear outcome, buildable
   as a derivation. For each task record: id (TNNN), cluster, dependencies,
   [P] if parallelizable, minimal env grants, and named verify criteria
   derived from the story's "Done when" bullets.
2. For each task run `amonite task new TNNN "title"` — this scaffolds
   `tasks/TNNN/{flake.nix,task.nix}` from the capsule template.
3. Fill each `task.nix`: env grants (exactly what tasks.md granted, no
   more), and the `verify` attrset (every criterion mechanical, exit-0).
   Leave `build` as the failing placeholder — implementation is
   /amonite.implement's job; a task must fail until genuinely done.
4. Fill `clusters.nix` with the planned topology: one mkCluster per
   cluster with its integration verifications, APP via mkApplication
   at the top.
5. `nix flake check` must EVALUATE (builds will fail — placeholders — but
   evaluation errors mean broken decomposition; fix those now).

User input: $ARGUMENTS
