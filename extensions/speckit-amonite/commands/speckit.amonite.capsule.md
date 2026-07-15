---
description: "Scaffold amonite task capsules for each task in tasks.md, enabling hermetic Nix-based verification."
handoffs:
  - label: Verify All Tasks
    agent: speckit.amonite.verify
    prompt: Run amonite verify all
    send: true
---

# Scaffold amonite Task Capsules

Read `tasks.md` in the current Spec Kit feature directory and create an amonite task
capsule for each uncompleted task. Each capsule is `tasks/TNNN/{flake.nix,task.nix}` — a
self-contained Nix flake whose `task.nix` holds env grants, a build script placeholder,
and acceptance-criteria `verify` entries derived from the task's Spec Kit description.

## What is an amonite capsule?

In amonite a **capsule** is a `tasks/TNNN/` directory containing:

- `flake.nix` — isolated dev environment (agent enters with `nix develop ./tasks/TNNN`)
- `task.nix` — single source of truth: `env` grants, `build` script, and `verify` entries

`verify` entries are shell snippets that must exit 0 inside the Nix derivation build.
A task that exists in the Nix store has *passed* its criteria — the sandbox enforces
the guarantee, not an LLM re-reading markdown.

## Steps

1. **Setup**: Run `scripts/bash/setup-tasks.sh --json` from project root. Parse
   `FEATURE_DIR` and `TASKS_FILE`. If `tasks.md` does not exist, stop and ask the
   user to run `/speckit.tasks` first.

2. **Parse tasks.md**: Extract all uncompleted tasks matching `- [ ] T\d+`:
   - `TASK_ID`: e.g. `T012`
   - `TASK_TITLE`: everything after the ID and labels (`[P]`, `[US1]`, etc.)
   - `FILE_PATHS`: paths mentioned in the task description
   - `LABELS`: extract `[US1]`, `[US2]`, … to map tasks back to user stories

3. **Skip existing capsules**: If `tasks/TASK_ID/` already exists, skip silently.

4. **Scaffold each new capsule**:
   ```bash
   amonite task new TASK_ID "TASK_TITLE"
   ```
   This creates `tasks/TASK_ID/flake.nix` and `tasks/TASK_ID/task.nix` from the
   amonite capsule template.

5. **Infer and fill task.nix context** for each scaffolded capsule:

   **`env` inference from FILE_PATHS and TASK_TITLE**:
   | Clue | Inferred tool |
   |------|--------------|
   | `.py` files or "python" | `pkgs.python3` |
   | `.ts` / `.js` or "node" | `pkgs.nodejs` |
   | `.go` or "go" | `pkgs.go` |
   | `.rs` or "rust" | `pkgs.rustc` |
   | `.sh` or "bash" | `pkgs.bash` |
   | Any file operations | `pkgs.coreutils` |
   | Any build step | `pkgs.bash pkgs.coreutils` (minimum) |

   **`verify` entries from acceptance scenarios**:
   Convert each Spec Kit `Given/When/Then` from the feature spec and Done When bullets
   into a shell check. Prefer behavioral over file-presence:

   | Spec Kit criterion | amonite verify entry |
   |--------------------|----------------------|
   | "binary runs and shows help" | `"$out/bin/tool" --help \| grep -q usage` |
   | "output file produced" | `test -s "$out/report.md"` |
   | "script is valid" | `bash -n "$out/scripts/run.sh"` |
   | "JSON is parseable" | `jq empty "$out/output.json"` |
   | "test suite passes" | `cd "$out" && python3 -m pytest` |

   Always use `test -x` or run the binary rather than `test -f` when possible.
   Document why if a plain `test -f` is unavoidable (e.g., static asset).

6. **Cluster topology**: Update `clusters.nix` if the new tasks belong to a cluster not
   yet declared. If `clusters.nix` does not exist, note that the user will need to
   create it or run `amonite init --flow-only` first.

7. **Report**:
   - N capsules created, list of TASK_IDs
   - How to enter a capsule: `nix develop ./tasks/TNNN`
   - How to verify a single task: `amonite verify TNNN`
   - How to verify all: `amonite verify APP`

## Note on `build` scripts

The scaffolded `task.nix` contains a `build` placeholder:
```nix
build = ''
  # TODO: implement — fill this with the task's actual build steps
  mkdir -p "$out"
'';
```
Leave this for the implementing agent. `verify` entries tell the agent what passing
looks like; `build` is where the work happens.

## Done When

- [ ] A `tasks/TNNN/` capsule exists for every uncompleted task in `tasks.md`
- [ ] Each `task.nix` has an inferred `env` list and at least one `verify` entry
- [ ] `clusters.nix` is updated to reference any new task IDs
- [ ] User informed of next steps (`nix develop ./tasks/TNNN`, `amonite verify`)
