# Getting Started

amonite is spec-driven development that compiles to Nix derivations. The spec's
verifiable core becomes acceptance criteria inside `mkTask` derivations — a task
that exists in the Nix store has passed its checks, hermetically and bit-identically,
with no LLM re-reading markdown to decide compliance.

## Prerequisites

- Nix with flakes enabled (`experimental-features = nix-command flakes` in `nix.conf`)
- A git repository

## Install

```bash
nix shell github:thatbagu/amonite
```

This drops you into a shell with `amonite` on `PATH`. To use it across sessions, add it to your project's `devShell` or a persistent `nix shell` alias.

## Start a new project

```bash
amonite init myproject
cd myproject
```

`init` scaffolds a meta flake, cluster topology, flow markdown files, and
Claude Code commands. Everything is committed automatically.

## Adopt an existing flake

If you already have a `flake.nix`:

```bash
amonite init --flow-only
```

This adds the `.amonite/` flow files and `.claude/commands/` without touching
your flake.

## The flow

```
/amonite.principles  →  /amonite.specify  →  /amonite.plan  →  /amonite.tasks  →  /amonite.implement
```

| Step | Command | Output |
|---|---|---|
| Principles | `/amonite.principles` | `.amonite/principles.md` — the project constitution |
| Specify | `/amonite.specify` | `.amonite/spec.md` — observable "done when" criteria |
| Plan | `/amonite.plan` | `.amonite/plan.md` + meta flake toolchain block |
| Tasks | `/amonite.tasks` | `.amonite/tasks.md` + one capsule per task in `tasks/` |
| Implement | `/amonite.implement` | agents fill capsules; `nix build .#task-TNNN` verifies |

After tasks are implemented:

```bash
amonite verify T001   # build + verify a single task
amonite verify C001   # cluster: member tasks + integration checks
amonite verify APP    # full application → records a generation
amonite verify all    # nix flake check
```
