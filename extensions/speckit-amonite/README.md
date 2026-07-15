# amonite — Spec Kit Extension

Bridges [Spec Kit](https://github.com/github/spec-kit)'s spec/plan/tasks flow with
[amonite](https://github.com/thatbagu/amonite)'s hermetic Nix verification.

Spec Kit produces the spec, plan, and tasks as markdown. This extension adds a
compilation step: Spec Kit tasks become Nix derivations whose acceptance criteria run
inside the build. **A task that exists in the store has passed its checks** — the Nix
sandbox, not an LLM re-reading markdown, is the judge.

## How it works

```
speckit.specify → speckit.plan → speckit.tasks
                                       │
                                       ▼ (after_tasks hook — optional)
                              speckit.amonite.capsule
                              (creates tasks/TNNN/ capsules)
                                       │
                                       ▼
                              speckit.implement
                              (agents fill capsules)
                                       │
                                       ▼ (after_implement hook — optional)
                              speckit.amonite.verify
                              (amonite verify all → generation recorded)
```

## Commands

| Command | What it does |
|---|---|
| `/speckit.amonite.capsule` | Reads `tasks.md`, scaffolds `tasks/TNNN/task.nix` for each task with inferred env and verify entries |
| `/speckit.amonite.verify` | Runs `amonite verify all` — builds every derivation and reports pass/fail per task |

## Prerequisites

- [Nix](https://nixos.org/download) with flakes enabled
- [amonite](https://github.com/thatbagu/amonite): `nix shell github:thatbagu/amonite`
- [Spec Kit](https://github.com/github/spec-kit) >= 0.12.0

## Installation

### Option 1: Local install (current project)

```bash
mkdir -p .specify/extensions/amonite
cp -r /path/to/amonite/extensions/speckit-amonite/. .specify/extensions/amonite/
```

### Option 2: Via `specify extension add` (once published)

```bash
specify extension add amonite
```

### Wire the hooks (optional)

To have the hooks trigger automatically after `/speckit.tasks` and `/speckit.implement`,
add the following to `.specify/extensions.yml` in your project:

```yaml
hooks:
  after_tasks:
    extension: amonite
    command: speckit.amonite.capsule
    optional: true
    prompt: "Scaffold amonite Nix capsules for hermetic verification"

  after_implement:
    extension: amonite
    command: speckit.amonite.verify
    optional: true
    prompt: "Run amonite verify all to confirm all tasks pass their criteria"
```

## Initialize amonite in a Spec Kit project

If `flake.nix` does not yet exist in your project:

```bash
amonite init --flow-only
```

This adds the amonite meta-flake and agent commands without disturbing the Spec Kit layout.

## Example session

```
/speckit.specify Build a CLI tool that greets users
/speckit.plan    Use bash + coreutils, no dependencies
/speckit.tasks

# Extension hook fires (if wired), or run manually:
/speckit.amonite.capsule

# → creates tasks/T001/{flake.nix,task.nix}, tasks/T002/...
# → agent enters capsule: nix develop ./tasks/T001

/speckit.implement

/speckit.amonite.verify
# → amonite verify all → ✅ APP verified → generation 1
```

## Verification guarantee

The guarantee is conditional on criteria quality. `"$out/bin/tool" --help | grep -q usage`
is strong (the binary runs). `test -f "$out/bin/tool"` is weak (file exists, may be broken).

See [amonite's verification quality guide](https://thatbagu.github.io/amonite/) for patterns.
