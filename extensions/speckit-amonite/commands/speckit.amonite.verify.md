---
description: "Run amonite verify — build every Nix task derivation and report which tasks have passed their acceptance criteria."
---

# Run amonite Verification

Run `amonite verify` to build every task derivation. Because acceptance criteria are shell
snippets that execute inside the Nix sandbox during the build, a task that exists in the
store has *definitively* passed its checks — the Nix build graph, not an LLM, is the judge.

## User Input

```text
$ARGUMENTS
```

If a specific task ID (e.g. `T012`) or cluster ID (e.g. `C001`) is provided,
verify only that scope. Otherwise default to `all`.

## Steps

1. **Check prerequisites**:
   - Verify `nix` is on `PATH` with flakes enabled (`nix flake --version` must exit 0).
   - Verify `amonite` is on `PATH`. If not:
     ```bash
     # Add to this session:
     nix shell github:thatbagu/amonite
     # Or add to flake.nix devShell for persistence
     ```
   - Verify `flake.nix` exists in the project root. If not, prompt the user to run
     `amonite init --flow-only` to initialize amonite in the Spec Kit project.
   - Verify at least one `tasks/TNNN/` directory exists. If not, ask the user to run
     `/speckit.amonite.capsule` first.

2. **Determine scope** from arguments or context:
   - Explicit task ID (`T001`, `T012`) → `amonite verify TASK_ID`
   - Explicit cluster ID (`C001`, `APP`) → `amonite verify CLUSTER_ID`
   - No argument → `amonite verify all` (runs `nix flake check`)

3. **Run verification**:
   ```bash
   amonite verify all
   ```
   Or for a specific scope:
   ```bash
   amonite verify T001   # single task
   amonite verify C001   # cluster: members + integration checks
   amonite verify APP    # full application → records a generation
   ```

4. **Report results** per task/cluster:
   - ✅ Verified — store path recorded
   - ❌ Failed — print the failing `verify` entry name and its exit output
   - For failures: identify which `task.nix` verify block failed and suggest the fix

5. **If `amonite verify APP` succeeded**, note:
   ```bash
   amonite generations   # view the recorded generation (git rev + timestamp)
   amonite tui           # browse the verified derivation tree interactively
   ```

## Verification ladder

| Command | Scope | What must pass |
|---|---|---|
| `amonite verify TNNN` | One task | Unit `verify` entries in `task.nix` |
| `amonite verify CNNN` | Cluster | All member tasks + cluster `verify` block |
| `amonite verify APP` | Full app | All clusters + APP `verify` → records generation |
| `amonite verify all` | Everything | `nix flake check` — total hermetic gate |

## What the guarantee means

amonite's guarantee is conditional on criteria quality:

| Criterion style | Guarantee |
|---|---|
| `"$out/bin/tool" --help \| grep -q usage` | Strong — the binary runs and produces expected output |
| `test -x "$out/bin/tool"` | Weak — proves file exists and is executable, not that it works |
| `grep -q keyword "$out/src/file.nix"` | Weak — passes even if logic is dead code |

When a verify entry is weak (file presence, keyword grep), the failing task is the
`verify` block itself — fix the criterion before re-running, or the guarantee is hollow.

## Done When

- [ ] `amonite verify all` (or specified scope) exits 0
- [ ] Generation recorded if APP verification passed
- [ ] Any failing tasks reported with specific verify entry output and suggested fix
