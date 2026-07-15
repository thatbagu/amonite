---
description: Produce the implementation plan and adjust the project meta flake
---

Create or update `.amonite/plan.md` from `.amonite/spec.md`, then apply the
meta-environment section to the project `flake.nix`, and write the task
dependency graph to `.amonite/task-graph.json`.

**Gate:** if spec.md has any unresolved Open questions, STOP and surface them.
Do not proceed until the spec is clean.

**If plan.md already exists**, read it alongside `tasks.md` and `clusters.nix`
before starting. You are extending the plan, not replacing it. Preserve
existing cluster IDs (C001…) and task IDs (T001…); new clusters and tasks
continue the sequence. Do not re-plan work that is already scaffolded
(has a `tasks/TNNN/task.nix` file) or already verified (checked box in
`tasks.md`).

1. Fix the technical context: language, dependencies, storage, target.
2. Design the architecture; name components — tasks will map onto them.
3. Write the verification strategy table. For every layer decide: hermetic
   (unit in task derivations, integration in cluster verify / nixosTest)
   or gate.live (impure, manual). Anything you cannot verify hermetically
   MUST appear in gate.live — hiding impurity violates principle E2.
4. Sketch the cluster topology in plan.md: which clusters exist, which
   tasks feed them, APP at the top. **Write this to plan.md only — do NOT
   touch clusters.nix here.** clusters.nix is written by /amonite.tasks
   once the task capsules exist. Updating it here, before task.nix files
   exist, will break `nix flake check`.
5. Apply the "Meta environment" package list to the project `flake.nix`
   devShell. Keep it minimal (principle E3): project-wide tools only;
   task-specific tools go into task envs later.
   - Find the `devShells.*.default` mkShell block.
   - If a `# amonite:toolchain` comment is already present, add new
     packages after it.
   - If the comment is absent, add it above the packages list:
     ```nix
     # amonite:toolchain — keep minimal; task tools go in task.nix env
     packages = [ ... ];
     ```
6. Write `.amonite/task-graph.json` — the machine-readable parallel
   execution plan. Include ALL tasks (existing + new). Format:
   ```json
   {
     "waves": [
       {
         "wave": 1,
         "tasks": [
           { "id": "T001", "title": "...", "cluster": "C001", "depends": [] }
         ]
       },
       {
         "wave": 2,
         "tasks": [
           { "id": "T003", "title": "...", "cluster": "C001", "depends": ["T001"] }
         ]
       }
     ]
   }
   ```
   Rules: wave 1 = tasks with no dependencies; wave N = tasks whose
   `depends` are all in waves < N. Do not invent dependencies — if two
   tasks are truly independent, put them in the same wave.
7. Run `nix flake check --no-build` on the project root; the flake must
   evaluate cleanly. If it fails, fix the evaluation error before
   continuing — but do NOT create task.nix stubs to satisfy it. If the
   check fails because clusters.nix references tasks that don't exist yet,
   that means clusters.nix was edited incorrectly in this step; revert
   those changes and leave clusters.nix for /amonite.tasks.
8. Re-check the whole plan against `.amonite/principles.md`.

User input: $ARGUMENTS
