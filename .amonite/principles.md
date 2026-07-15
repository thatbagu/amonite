# Project Principles

<!-- Persistent constitution. Every plan and task decomposition is checked
     against this file. Amend deliberately; agents may not weaken it. -->

## Product principles

- P1: Minimal surface — amonite's power comes from the Nix model, not feature
  accumulation. Every addition must justify itself against the stated non-goals
  in docs/architecture.md. When in doubt, reject.
- P2: Self-applicable — amonite must be buildable and verifiable by amonite
  itself. Dogfooding is a first-class invariant; any change that breaks the
  self-build breaks the project.
- P3: Distribution follows the user — target users are Nix users. The
  canonical install paths are nixpkgs and nix flakes; no Python, no npm.

## Engineering principles

- E1: Every task's acceptance criteria MUST be mechanical: expressible as
  `verify` entries in its task.nix. "Looks correct" is not a criterion.
- E2: A task that cannot be verified hermetically MUST declare its impure
  boundary explicitly in the plan (see `gate.live` in plan.md).
- E3: Toolchain grants are minimal: a task's `env` lists only what that
  task needs. Widening an env is a plan change, not an implementation detail.
- E4: The CLI runtime is bash + Go; the Nix lib is pure Nix. No new language
  runtimes. If a feature requires Python/Node/Ruby it is the wrong feature.

## Non-negotiables

- N1: `nix flake check` green on the project root before any cluster is
  declared complete.
- N2: The lib surface has five names: mkTask, mkCluster, mkApplication,
  mkResearchTask, mkVmVerify — representing four distinct implementations
  plus one alias (mkApplication = mkCluster, vocabulary for the deliverable).
  mkResearchTask enforces sources-alongside-report and offline faithfulness
  verification (TF-IDF + NLI; NLI threshold 0.35 is a gross hallucination
  detector, not a sentence-level faithfulness guarantee).
  mkVmVerify is a Linux-only helper (pkgs.testers.runNixOSTest); it is gated
  by isLinux in checks and requires a linux-builder on darwin.
  No further names without an explicit spec amendment.
- N3: shellcheck must pass on bin/amonite at all times; it is part of
  the nix flake check suite.
