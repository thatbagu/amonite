---
description: Decompose the plan into tasks and spawn encapsulated task capsules
---

Create or update `.amonite/tasks.md` from `.amonite/plan.md`, then spawn a
flake capsule per task, then write `clusters.nix`.

**If tasks.md already exists**, read it alongside `clusters.nix` before
starting. You are adding new tasks, not replacing existing ones. Preserve
existing task IDs and their verify criteria. Skip any TNNN that already
has a `tasks/TNNN/task.nix` file — it is already scaffolded.

**Step 1 — Decompose**

One task = one unit of work with a clear outcome, buildable as a derivation.
For each NEW task record in tasks.md:
- ID (TNNN), cluster, `[P]` if parallelizable, `depends` list
- Minimal env grants (exactly the tools the build and verify scripts need)
- Named verify criteria derived from the story's "Done when" bullets

**Step 2 — Scaffold capsules**

For each new task TNNN, in sequence (not parallel — parallel nix flake lock
calls cause git index conflicts):

```
if [ ! -d tasks/TNNN ]; then
  amonite task new TNNN "title"   # creates tasks/TNNN/{flake.nix,task.nix}
else
  # directory exists (e.g. from a plan stub) — create only what's missing
  if [ ! -f tasks/TNNN/flake.nix ]; then
    # copy flake.nix from tasks/T001/flake.nix, changing nothing except
    # the description comment — the inputs block is identical for all tasks
    cp tasks/T001/flake.nix tasks/TNNN/flake.nix
  fi
  # task.nix may already be a stub — it will be rewritten in Step 3
fi
nix flake lock tasks/TNNN          # one at a time, avoids .git/index.lock
```

**Step 3 — Fill task.nix**

For each new TNNN, write `tasks/TNNN/task.nix`:
- `env`: exactly the packages listed in tasks.md for this task, no more
- `verify`: every criterion from tasks.md, mechanical (exit-0 test/grep)
- `build`: the failing placeholder — **do not implement yet**:
  ```nix
  build = ''echo "TXXX not yet implemented" >&2 && exit 1'';
  ```
  Implementation is /amonite.implement's job. A task must fail to build
  until it is genuinely done — that is what makes verification honest.

**Step 4 — Write clusters.nix**

Write `clusters.nix` with the topology from plan.md. Now that all task.nix
files exist, `with tasks; [ T00X T00Y ]` will resolve correctly.

- One `mkCluster` per cluster with its integration `verify` entries
- `mkApplication` for APP at the top, listing all clusters
- Integration verify entries reference `$out/tasks/TNNN/...` paths — they
  run after all member tasks have built and linked into the cluster output

**Step 5 — Verify evaluation**

```
nix flake check --no-build
```

The flake must evaluate cleanly. Builds will fail (placeholders) — that is
expected and correct. Fix any evaluation errors (attribute not found, type
errors in Nix) before finishing. Do not weaken verify criteria to fix
evaluation errors.

User input: $ARGUMENTS
