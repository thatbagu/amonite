# Project Principles

<!-- Persistent constitution. Every plan and task decomposition is checked
     against this file. Amend deliberately; agents may not weaken it. -->

## Product principles

- P1: [REPLACE — e.g. "Offline-first: every feature must work without network"]
- P2: [REPLACE]

## Engineering principles

- E1: Every task's acceptance criteria MUST be mechanical: expressible as
  `verify` entries in its task.nix. "Looks correct" is not a criterion.
- E2: A task that cannot be verified hermetically MUST declare its impure
  boundary explicitly in the plan (see `gate.live` in plan.md).
- E3: Toolchain grants are minimal: a task's `env` lists only what that
  task needs. Widening an env is a plan change, not an implementation detail.
- E4: [REPLACE — project-specific: language, style, testing norms]

## Non-negotiables

- N1: `nix flake check` green on the project root before any cluster is
  declared complete.
- N2: [REPLACE — e.g. "no network calls in build/verify phases"]
