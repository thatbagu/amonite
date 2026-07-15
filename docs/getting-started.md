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

## Research tasks

When an AI agent produces a research report, `mkResearchTask` enforces that
the report is grounded in collected sources — offline, hermeticallay, inside
the Nix sandbox. Two verification tiers run automatically in the build phase:

1. **TF-IDF cosine similarity** — fast lexical gate; fails if the report has
   no lexical overlap with the sources.
2. **AlignScore NLI entailment** — claim-level faithfulness; fails if the
   mean entailment score drops below the threshold.

```nix
# task.nix
{ pkgs, amonite }:
amonite.mkResearchTask {
  id = "R001";
  title = "framework comparison research";
  src = ../..; tfidfThreshold = 0.08; nliThreshold = 0.35;
  build = ''
    mkdir -p "$out/sources"
    # agent copies collected source files here:
    cp "$src/research/R001/sources/." "$out/sources/"
    cp "$src/research/R001/report.md"  "$out/report.md"
    python3 "$src/nix/research/verify_tfidf.py" --report "$out/report.md" \
      --sources "$out/sources" --threshold 0.08
    python3 "$src/nix/research/verify_nli.py"   --report "$out/report.md" \
      --sources "$out/sources" --threshold 0.35 \
      --weights-dir "${alignscoreWeights}"
  '';
}
```

If the report drifts from its sources the derivation build exits non-zero —
same as a failing unit test. No LLM judge; no network at verify time.
AlignScore model weights are packaged as a fixed-output Nix derivation
(`nix build .#alignscore-weights`).
