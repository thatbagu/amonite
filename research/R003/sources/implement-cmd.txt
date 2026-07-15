---
description: Implement tasks inside their capsules until clusters and APP verify
---

You are the orchestrator. Work through all waves until APP verifies.

## 1. Read the current state

```bash
amonite waves
```

This shows every wave with ● (store path exists = verified) or ○ (pending).
The current wave is the first wave that contains any ○ task.

## Known agent roadblocks (read before writing prompts)

**Git staging is mandatory.** Nix evaluates the git index, not the raw
filesystem. Any source file an agent creates or modifies is invisible to
`nix build` until `git add`-ed. Every agent prompt must include:
> "After creating or editing any source file, run `git add <file>` before
> running `nix build`. Nix reads the git index, not the filesystem."

**Session / tool-use limits.** An agent that loops trying many approaches
will hit the tool-use cap (≈60 calls). If an agent returns with a session
limit error and the store path is absent: re-dispatch with a more focused
prompt that states the exact file to create and the exact verify criterion
that's failing.

**Grep exit-code confusion.** `nix build ... 2>&1 | grep error:; echo $?`
prints grep's exit code (1 = no match), not nix's. Always check nix build
exit separately: `nix build ... && echo PASS || echo FAIL`.

**Derivations already in the store are free.** Nix skips building if the
store path exists. Agents never need to "skip" already-verified tasks — Nix
handles it. A `nix build .#task-T001` call on an already-verified task
returns in milliseconds.

## 2. Audit verify quality before dispatching

Before spawning agents, read each pending task's `verify` block in
`task.nix`. Flag any criterion that is only `test -f` or bare `grep -q` on
a source file — these are weak and may pass even when the feature is broken.

For each weak criterion, try to upgrade it in place:
- If the task produces an executable: replace `test -f "$out/bin/tool"` with
  `"$out/bin/tool" --help | grep -q "expected"` (or similar invocation).
- If it's a shell script: run it in a tmp sandbox and check exit code / output.
- If it's config/YAML: parse with `jq`/`yq` and assert structure.
- If it's a compiled binary (Go): ensure the build step actually compiles;
  add a run-it verify step.

Only leave a `test -f` or `grep -q` if there is genuinely no runnable form
(e.g. a static asset, a license file). Note why in a comment.

A verify block that exercises no code is a false safety net — it will pass
for a file full of placeholder content.

## 3. Dispatch wave-1 tasks in parallel

Identify all ○ tasks in the current wave. Spawn one Agent per task in a
**single message** (multiple Agent tool calls = parallel execution):

```
Agent(
  description="Implement T006 — mdBook docs content",
  isolation="worktree",
  prompt="""
    Project: /path/to/project
    Task: T006

    CRITICAL: After creating or editing any source file, run `git add <file>`
    before running `nix build`. Nix reads the git index, not the filesystem.
    Without this, your edits are invisible to the build.

    Read tasks/T006/task.nix — the verify block is your spec; do not change it.
    Fill the build block and create any source files it needs so that:

      nix build .#task-T006

    exits 0 from the project root. The derivation existing in the store IS
    the passing test — there is no separate test step.

    Scope: you may create/edit any files that T006's build and verify scripts
    reference. Do not touch other tasks' directories or clusters.nix.

    When nix build .#task-T006 exits 0, report the store path and stop.
  """
)
```

Repeat this Agent call for every other ○ task in the same wave, all in the
same message so they run concurrently. Each agent works in its own worktree
(no conflicts as long as tasks touch non-overlapping files — which they
must, by decomposition).

If a task has a known blocker or uncertainty, give the agent a hint in its
prompt. Keep prompts self-contained — agents start cold.

## 4. Check for task-level problems

When an agent returns, read its result. If it failed:
- Missing tool in env → add it to `task.nix env` and re-dispatch
- Verify criterion is wrong (spec error) → surface to user; do not weaken
  criteria silently
- Build logic error → re-dispatch with additional context

## 5. Verify the cluster

Once all tasks in a cluster's wave are ●:

```bash
nix build .#cluster-CNNN
```

If the cluster fails, the integration `verify` block in `clusters.nix`
identified a cross-task problem. Fix in the tasks (not in the cluster
verify entry) and rebuild.

## 6. Advance to the next wave

```bash
amonite waves
```

Tasks that `depends` on now-verified tasks are unblocked. Repeat steps 3–5
for the next wave. Wave 2 tasks can be dispatched immediately when all their
dependencies are ●; do not wait for unrelated clusters to finish.

## 7. Final verification

When all waves are ●:

```bash
amonite verify APP
```

The store path is the verified application. Surface any `gate.live` items
from `tasks.md` to the user — those are manual checks that require the real
world (live CI run, deployed site, published release).

---

**If called with a specific task ID** (`/amonite.implement T006`):
Skip the wave orchestration. Implement only that task, then run
`nix build .#task-T006` to verify. Report the store path.

User input: $ARGUMENTS
