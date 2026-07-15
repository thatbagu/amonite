<div align="center">
  <h1>amonite 🐚</h1>
  <p><em>Spec-driven development that compiles to Nix derivations.</em></p>
</div>

<p align="center">
  <a href="https://github.com/thatbagu/amonite/releases/latest"><img src="https://img.shields.io/github/v/release/thatbagu/amonite" alt="Latest Release"/></a>
  <a href="https://github.com/thatbagu/amonite/actions/workflows/ci.yml"><img src="https://img.shields.io/github/actions/workflow/status/thatbagu/amonite/ci.yml?label=nix%20flake%20check" alt="CI"/></a>
  <a href="https://github.com/thatbagu/amonite/blob/main/LICENSE"><img src="https://img.shields.io/github/license/thatbagu/amonite" alt="License"/></a>
  <a href="https://thatbagu.github.io/amonite/"><img src="https://img.shields.io/badge/docs-thatbagu.github.io%2Famonite-blue" alt="Documentation"/></a>
</p>

---

## Table of Contents

- [What is amonite?](#what-is-amonite)
- [Get Started](#get-started)
- [The Flow](#the-flow)
- [Four Properties](#four-properties)
- [Library Surface](#library-surface)
- [Research Tasks](#research-tasks)
- [TUI](#tui)
- [Generations and Rollback](#generations-and-rollback)
- [Layout of a Generated Project](#layout-of-a-generated-project)
- [Spec Kit Integration](#spec-kit-integration)
- [What amonite Does Not Pretend](#what-amonite-does-not-pretend)
- [Learn More](#learn-more)
- [Status](#status)
- [License](#license)

---

## What is amonite?

Spec Kit and its siblings verify agent work by having an LLM re-read the spec
and vibe about compliance. amonite makes the verifiable core of the spec
**mechanical**: every task is a Nix derivation whose acceptance criteria run
inside its build — **a task that exists in the store has passed its checks**.
Verified tasks cluster into higher abstractions, clusters into the final
derivation: the working application.

```
principles ─▶ specify ─▶ plan ─▶ tasks ─▶ implement
(persistent flow, markdown in .amonite/)
                          │        │
                          ▼        ▼
                   meta flake   task capsules        clusters      APP
                   (project    (one flake env per   (mkCluster,   (final
                    toolchain)  task: minimal env,   integration   derivation =
                                verify in-build)     checks)       application)
```

## Get Started

### 1. Install

```bash
nix shell github:thatbagu/amonite
```

Or add it to your project's `devShell` in `flake.nix` for persistent access.

### 2. Initialize a project

```bash
amonite init myproject
cd myproject
```

`init` scaffolds a meta flake, cluster topology, flow markdown files, and
agent commands. Everything is committed automatically.

For an existing flake, add only the flow layer:

```bash
amonite init --flow-only
```

### 3. Run the flow with your agent

Commands are installed into `.claude/commands/` (and equivalents for other agents):

```bash
/amonite.principles   # establish the project constitution
/amonite.specify      # what & why — observable "done when" criteria
/amonite.plan         # architecture + verification strategy; adjusts the meta flake
/amonite.tasks        # decompose into capsules; spawns tasks/TNNN/ for each task
/amonite.implement    # agents fill capsules until APP builds
```

### 4. Verify

```bash
amonite verify T001   # build + verify one task
amonite verify C001   # cluster: members + integration checks
amonite verify APP    # full application → records a generation
amonite verify all    # nix flake check (total hermetic gate)
```

## The Flow

| Step | Command | Output |
|---|---|---|
| Principles | `/amonite.principles` | `.amonite/principles.md` — project constitution |
| Specify | `/amonite.specify` | `.amonite/spec.md` — observable "done when" criteria |
| Plan | `/amonite.plan` | `.amonite/plan.md` + meta flake toolchain block |
| Tasks | `/amonite.tasks` | `.amonite/tasks.md` + one capsule per task in `tasks/` |
| Implement | `/amonite.implement` | agents fill capsules; `amonite verify TNNN` builds each |

## Four Properties

| Property | How |
|---|---|
| **Guardrails** | A task's `env` grants exactly its toolchain; the Nix sandbox denies network and undeclared paths. Missing tool = plan change, not a workaround. |
| **Encapsulation** | Each task is a flake capsule: `nix develop ./tasks/T001` gives an agent that task's world and nothing else. Parallel agents can't collide. |
| **Reproducibility** | `flake.lock` everywhere. Any reviewer re-runs any verification bit-identically. |
| **Run/build verification** | Acceptance criteria are `verify` entries executed inside the derivation. Clusters depend on member tasks — Nix's own dependency semantics enforce "verified before composed". No orchestrator. |

## Library Surface

Five functions in `nix/lib.nix` — no more without a spec amendment:

```nix
mkTask            # one unit of work + acceptance criteria baked into the build
mkCluster         # aggregates verified tasks; optional assembly build + integration verify
mkApplication     # alias for mkCluster at the root (the deliverable)
mkResearchTask    # enforces sources/ + report.md; TF-IDF + AlignScore NLI verification
mkVmVerify        # wraps pkgs.testers.runNixOSTest; VM test = a cluster member (Linux only)
```

### mkCluster `build` — assembling from members

The optional `build` script in `mkCluster` runs after members are symlinked. Use it to
assemble a combined artifact from member outputs:

```nix
cliCluster = amonite.mkCluster {
  id = "C001";
  tasks = [ taskA taskB taskC ];
  build = ''
    mkdir -p "$out/bin" "$out/share/tool"
    cp "$out/tasks/T003/bin/tool"         "$out/bin/tool"
    cp -r "$out/tasks/T003/share/tool/."  "$out/share/tool/"
  '';
  verify.tool-works = ''
    TOOL_SHARE="$out/share/tool" bash "$out/bin/tool" --help | grep -q usage
  '';
};
```

Clusters compose at any depth — `mkApplication` simply wraps `mkCluster` to signal
"this is the deliverable":

```nix
APP = amonite.mkApplication {
  id = "APP";
  tasks = [ cliCluster docsCluster completionsCluster ];
  build = ''
    cp "$out/tasks/C001/bin/tool"          "$out/bin/tool"
    cp -r "$out/tasks/C001/share/tool/."   "$out/share/tool/"
  '';
};
```

## Research Tasks

AI agent outputs are just text — and text can hallucinate. `mkResearchTask`
makes faithfulness a build constraint:

```nix
amonite.mkResearchTask {
  id = "R001"; title = "framework comparison";
  src = ../..; tfidfThreshold = 0.08; nliThreshold = 0.35;
  build = ''
    cp "$src/research/R001/sources/." "$out/sources/"   # evidence
    cp "$src/research/R001/report.md"  "$out/report.md" # synthesis
    python3 verify_tfidf.py --report ... --threshold 0.08   # tier 1
    python3 verify_nli.py   --report ... --threshold 0.35   # tier 2
  '';
}
```

The derivation fails if the report drifts from its sources — no LLM judge,
no network at verify time. Model weights (AlignScore, RoBERTa-base) are
bundled as a fixed-output Nix derivation: `nix build .#alignscore-weights`.

Two verification tiers run automatically:

1. **TF-IDF cosine similarity** — fast lexical gate; fails if the report has no lexical overlap with sources
2. **AlignScore NLI entailment** — gross fabrication detector; fails below the configured threshold

## TUI

`amonite tui` (bubbletea/lipgloss) renders the derivation hierarchy live
from the project's `graph.<system>` flake output:

```
▸ ● [cluster] APP · Demo application
  └─ ● [cluster] C001 · Greeting foundation
     └─ ● [task] T001 · emit greeting artifact
  ○ [task] T002 · parse config file
```

`●` = verified (store path exists), `○` = pending. Navigate with ↑/↓,
`enter` verifies the selected node (`nix build`), `r` refreshes,
`w` switches to wave view, `--dump` renders once headlessly (CI-friendly).

## Generations and Rollback

Every verified `APP` build is recorded as a **generation**: a GC-rooted
symlink in `.amonite/generations/` pointing at the immutable store path,
with the git rev and timestamp that produced it.

```bash
amonite generations     # list all generations
amonite rollback 2      # flip current to generation 2 (instant — already verified)
```

`current` is just a pointer, so rollback is an instant symlink flip to an
artifact that already passed the whole verification tree — the NixOS model,
applied to your application.

## Layout of a Generated Project

```
myproject/
├── flake.nix            # meta env; toolchain at # amonite:toolchain marker
├── clusters.nix         # cluster topology → mkCluster / mkApplication
├── .amonite/            # persistent flow: principles, spec, plan, tasks
│   └── generations/     # GC-rooted symlinks to verified APP store paths
├── .claude/commands/    # /amonite.* commands for your agent
└── tasks/
    └── T001/
        ├── flake.nix    # capsule: isolated dev env for this task
        └── task.nix     # env grants + build + verify (imported by both capsule and root flake)
```

`task.nix` is imported by both the capsule (isolated dev) and the project
flake (aggregate verification) — the capsule is a workspace, not a fork.

## Spec Kit Integration

amonite can act as a [Spec Kit](https://github.com/github/spec-kit) extension, bridging
Spec Kit's spec/plan/tasks flow with amonite's hermetic Nix verification:

```bash
# In a Spec Kit project:
specify extension add amonite   # (once published to the catalog)

# Or install locally:
cp -r /path/to/amonite/extensions/speckit-amonite .specify/extensions/

# Then in your agent:
/speckit.amonite.capsule   # scaffold tasks/TNNN/ capsules from tasks.md
/speckit.amonite.verify    # run amonite verify all after implementation
```

See [`extensions/speckit-amonite/`](./extensions/speckit-amonite/) for the extension
manifest and full installation instructions.

## What amonite Does Not Pretend

Hermetic verification covers what is buildable/runnable in isolation. Checks
that need the real world (live cloud state, external APIs) belong in the
plan's explicit `gate.live` section and stay human-gated. Hiding impurity is
the one sin the flow refuses.

No orchestrator daemon, no state DB: the Nix store is the state. No LLM-judged
compliance. The library surface is four distinct functions plus one alias plus one
Linux-only helper. If it needs plugins, it has failed.

## Learn More

- **[Full Documentation](https://thatbagu.github.io/amonite/)** — architecture, CLI reference, guides
- **[Architecture](./docs/architecture.md)** — derivation semantics, verification ladder, design decisions
- **[Getting Started](./docs/getting-started.md)** — step-by-step walkthrough

For support, open a [GitHub issue](https://github.com/thatbagu/amonite/issues).

## Status

v0.2 — all nine sprint stories shipped:

- flow-only init, nixpkgs package.nix, shell completions, CLI UX hardening
- parallel-agent wave planner (`amonite waves`)
- mdBook docs site + GitHub Pages CI
- CI gate (matrix, Cachix) + release-please pipeline
- TUI wave view (`w` key)
- `mkResearchTask` + offline two-tier faithfulness verification (TF-IDF + AlignScore NLI)
- hierarchical cluster composition (`mkCluster` accepts clusters as members at any depth)
- `mkCluster build` — FHS-style assembly across task → cluster → application levels

`nix flake check` is the total hermetic gate. Locks are generated and committed automatically.

## License

MIT — see [LICENSE](./LICENSE).
