# amonite 🐚

**Spec-driven development that compiles to Nix derivations.**

**[Documentation →](https://thatbagu.github.io/amonite/)**

Spec Kit and its siblings verify agent work by having an LLM re-read the spec
and vibe about compliance. amonite makes the verifiable core of the spec
*mechanical*: every task is a Nix derivation whose acceptance criteria run
inside its build — **a task that exists in the store has passed its checks**.
Verified tasks cluster into higher abstractions, clusters into the final
derivation: the working application.

```
principles ─▶ specify ─▶ plan ─▶ tasks ─▶ implement
(persistent flow, Spec Kit style — markdown in .amonite/)
                          │        │
                          ▼        ▼
                   meta flake   task capsules        clusters      APP
                   (project    (one flake env per   (mkCluster,   (final
                    toolchain)  task: minimal env,   integration   derivation =
                                verify in-build)     checks)       application)
```

## The four properties

| Property | How |
|---|---|
| **Guardrails** | A task's `env` grants exactly its toolchain; the Nix sandbox denies network and undeclared paths. Missing tool = plan change, not a workaround. |
| **Encapsulation** | Each task is a flake capsule: `nix develop ./tasks/T001` gives an agent that task's world and nothing else. Parallel agents can't collide. |
| **Reproducibility** | `flake.lock` everywhere. Any reviewer re-runs any verification bit-identically. |
| **Run/build verification** | Acceptance criteria are `verify` entries executed inside the derivation. Clusters depend on member tasks, so Nix's own dependency semantics enforce "verified before composed" — no orchestrator. |

## Quickstart

```bash
nix run path:/path/to/amonite -- init myproject
cd myproject
# then, with your agent (commands are installed into .claude/commands/):
#   /amonite.principles  — constitution
#   /amonite.specify     — what & why, observable "done when"
#   /amonite.plan        — architecture + verification strategy; adjusts the meta flake
#   /amonite.tasks       — decomposition; spawns a capsule per task
#   /amonite.implement   — agents fill capsules until APP builds

amonite verify T001   # build+verify one task
amonite verify C001   # cluster: members + integration checks
amonite verify APP    # the working application → records a generation
amonite verify all    # nix flake check
amonite generations   # list APP generations (NixOS-style)
amonite rollback 2    # flip current back to a verified generation
amonite tui           # interactive derivation-hierarchy viewer
amonite status        # flow + checklist state + current generation
```

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
`--dump` renders once headlessly (CI-friendly).

## Generations & rollback

Every verified `APP` build is recorded as a **generation**: a GC-rooted
symlink in `.amonite/generations/` pointing at the immutable store path,
with the git rev and timestamp that produced it. `current` is just a
pointer, so rollback is an instant symlink flip to an artifact that
already passed the whole verification tree — the NixOS model, applied to
your application.

## Layout of a generated project

```
myproject/
├── flake.nix            # meta env; toolchain managed by /amonite.plan
├── clusters.nix         # cluster topology → mkCluster / mkApplication
├── .amonite/            # persistent flow: principles, spec, plan, tasks
├── .claude/commands/    # the /amonite.* flow for your agent
└── tasks/
    └── T001/
        ├── flake.nix    # capsule: encapsulated dev env for this task
        └── task.nix     # single source of truth: env grants + build + verify
```

`task.nix` is imported by both the capsule (isolated dev) and the project
flake (aggregate verification) — the capsule is a workspace, not a fork.

## What amonite does not pretend

Hermetic verification covers what is buildable/runnable in isolation. Checks
that need the real world (live cloud state, external APIs) belong in the
plan's explicit `gate.live` section and stay human-gated. Hiding impurity is
the one sin the flow refuses.

## Status

Early scaffold. The lib self-tests (`nix flake check`), the flow templates,
generations/rollback, and `mkVmVerify` (nixosTest cluster verification,
Linux builders) work; remote-builder support is next. Locks are generated
and committed automatically by `init` / `task new` / `verify`.
