# Specification: amonite v0.2 — self-improvement sprint

<!-- What and why. No tech stack, no file paths — that belongs in plan.md. -->

## Intent

amonite exists but only runs on freshly generated projects — it cannot yet
be applied to itself or any existing Nix project. Users with existing flakes
cannot enter the flow; there is no way to discover amonite via the standard
Nix package ecosystem; and the CLI has rough edges that trip up new users.

This sprint closes those gaps and adds the two foundations needed for the
project to build momentum: a minimal documentation site (modelled on nixlab —
mdBook, GitHub Pages, no sprawl) and a proper CI + release pipeline so that
every PR is gated and every tagged version produces an auditable release
artifact. Together these give new users somewhere to land and give
maintainers a repeatable path from commit to published release.

## User stories

<!-- Priority-ordered. Each story must be independently deliverable and
     independently verifiable — it will become a cluster. -->

### US1 (P1): Flow-only init for existing Nix projects

As a developer with an existing flake project, I want to graft the amonite
flow layer onto my project without touching my flake.nix, so that I can
adopt amonite incrementally.

**Done when** (observable, will compile into cluster verifications):
- [ ] `amonite init --flow-only` completes without error on a directory
  that already contains a flake.nix.
- [ ] `.amonite/{principles,spec,plan,tasks}.md` and `.claude/commands/*.md`
  are created; flake.nix is unchanged.
- [ ] Running `amonite init --flow-only` a second time skips existing flow
  files and exits 0.
- [ ] `amonite init` (without --flow-only) on an existing flake prints the
  new hint mentioning --flow-only and exits 1.
- [ ] shellcheck passes on bin/amonite.

### US2 (P1): nixpkgs-ready package derivation

As a Nix user, I want to install amonite via `nix profile install` or
home-manager without a flake URL, so that I can discover and install it
through the standard Nix ecosystem.

**Done when**:
- [ ] A standalone `package.nix` exists that can be called as
  `pkgs.callPackage ./package.nix {}` and produces a working amonite binary.
- [ ] The derivation passes `nix-build` locally.
- [ ] The derivation follows nixpkgs conventions (meta.description,
  meta.license, meta.maintainers, meta.mainProgram).
- [ ] `amonite --help` output from the built derivation matches expected
  usage text (verified in-derivation).

### US3 (P2): Shell completions (bash, zsh, fish)

As a CLI user, I want tab-completion for amonite subcommands and `<ID>`
arguments, so that I don't need to memorise or type task IDs by hand.

**Done when**:
- [ ] Completion scripts for bash, zsh, and fish are installed under
  `$out/share/` in the amonite derivation.
- [ ] The bash completion script completes `amonite <TAB>` to the list of
  subcommands (init, task, verify, tui, generations, rollback, status).
- [ ] `amonite verify <TAB>` completes to `APP all` plus any `T*` and `C*`
  entries found under `tasks/` in the current directory.
- [ ] Completion files are syntactically valid (bash -n, zsh compcheck,
  fish --command).

### US4 (P3): CLI UX hardening

As a new amonite user, I want the CLI to guide me when I make mistakes,
so that I don't need to read the source to understand what went wrong.

**Done when**:
- [ ] `amonite verify` with no argument prints usage and exits 1.
- [ ] `amonite task new` with a non-T-prefixed ID prints a clear error
  ("ID must match T[0-9]+, e.g. T001") and exits 1.
- [ ] `amonite status` colorises output: draft items in yellow, ready in
  green, missing in red — when stdout is a terminal (tty check).
- [ ] All error messages go to stderr; all status/progress messages to
  stdout.
- [ ] shellcheck passes with no warnings.

### US5 (P2): Parallel-agent wave planner

As a project lead with many tasks, I want amonite to show me which tasks
can be worked on in parallel right now and which are blocked, so that I
can dispatch multiple agents efficiently without coordination overhead.

**Done when**:
- [ ] `/amonite.plan` produces `.amonite/task-graph.json` with wave
  assignments (wave 1 = no deps, wave N = all deps in earlier waves).
- [ ] `amonite waves` reads `task-graph.json`, overlays live verification
  state (● verified / ○ pending) from the Nix store, and prints one
  wave per block with task IDs, cluster, and status.
- [ ] `amonite waves` exits 1 with a clear message if `task-graph.json`
  does not exist yet.
- [ ] `mkTask` accepts an optional `depends` list of task IDs; `mkGraph`
  includes these in its node output so the TUI can reflect the DAG.
- [ ] shellcheck passes on bin/amonite.

### US6 (P2): Minimal mdBook documentation site

As a developer evaluating amonite, I want a browsable documentation site I
can read before installing anything, so that I can understand what amonite
does and whether it fits my workflow without reading source code.

Documentation follows the nixlab pattern: mdBook, GitHub Pages, three or
four focused pages — no sprawl, no tutorial soup.

**Done when** (observable, will compile into cluster verifications):
- [ ] `docs/book.toml`, `docs/SUMMARY.md`, `docs/getting-started.md`,
  `docs/architecture.md` (moved from root), `docs/contributing.md`,
  and `docs/cli-reference.md` (auto-generated from `amonite --help`
  output as part of the mdbook build step) all exist.
- [ ] `nix run nixpkgs#mdbook -- build docs` exits 0 (verifiable in CI
  and in the derivation check).
- [ ] `.github/workflows/docs.yml` exists; it triggers on push to `main`
  when any `docs/**` file changes and deploys to GitHub Pages via
  `actions/deploy-pages`.
- [ ] The CI job inside `docs.yml` also runs `mdbook build docs` on PRs
  (path filter applied) so broken docs are caught before merge; this
  job exits 0 on a clean checkout.
- [ ] `README.md` contains the GitHub Pages URL and a one-sentence
  description of amonite visible before the fold.
- [ ] shellcheck passes on bin/amonite (N3 invariant; re-verified here
  because the docs workflow touches nothing else).

### US7 (P1): CI gate and automated release pipeline

As a maintainer, I want every pull request to be automatically gated by
`nix flake check` and every merge to `main` to eventually produce a GitHub
Release with a changelog entry, without manual tagging, so that releases
follow naturally from the commit history.

Release model: **release-please** (same model as devenv, treefmt-nix).
Conventional commits merging to `main` accumulate in a release-please PR
("chore: release vX.Y.Z"). When the maintainer merges that PR, the git tag
is created and `release.yml` fires. This gives one-click releases with an
auto-assembled CHANGELOG, without bypassing maintainer intent.

The TUI (`amonite-tui`) is already built by `nix flake check` (it is in
`checks.*.tui`) so CI covers it automatically. No separate TUI build step
is needed. Users install via Nix and build from source; Cachix ensures the
build is cached on first CI run.

**Done when**:
- [ ] `.github/workflows/ci.yml` exists and runs on every PR targeting
  `main`; matrix `ubuntu-latest` + `macos-latest`; Cachix `amonite`
  cache; `nix flake check`; exits 0 on clean checkout of `main`.
- [ ] `.github/workflows/release-please.yml` exists; it runs
  `google-github-actions/release-please-action@v4` on every push to
  `main`; `release-type: simple`; creates/updates the release PR
  automatically.
- [ ] `.github/workflows/release.yml` exists; it triggers on the tag
  push that release-please creates (`v[0-9]+.*`); it creates a GitHub
  Release using `softprops/action-gh-release` with the release notes
  from the release-please PR body.
- [ ] `release-please-config.json` and `.release-please-manifest.json`
  exist at the repo root with correct configuration for the `amonite`
  package.
- [ ] `CHANGELOG.md` exists, follows Keep a Changelog 1.0.0 format,
  and contains an `[Unreleased]` section.
- [ ] `CONTRIBUTING.md` documents Conventional Commits, branch prefixes,
  and states that releases are handled by release-please (no manual
  tagging needed).
- [ ] `nix flake check` exits 0 locally.

### US8 (P3): TUI wave view

As a project lead dispatching agents, I want the TUI to show me task waves
with live verification state, so I can see at a glance which wave is active
and which tasks are blocked vs. runnable.

**Done when**:
- [ ] `amonite tui` has a second tab or toggle (key `w`) that renders
  waves from `.amonite/task-graph.json` grouped by wave number.
- [ ] Each task row in the wave view shows: wave number, task ID, cluster,
  title, and ● / ○ verified state (same store-path check as the tree view).
- [ ] If `.amonite/task-graph.json` is absent, the wave view shows a
  one-line message "no task-graph.json — run /amonite.plan first".
- [ ] `nix build .#amonite-tui` exits 0 after the change.
- [ ] `nix flake check` exits 0 (N1).

### US9 (P1): Research task type with offline faithfulness verification

As a project lead using amonite to run AI research tasks, I want the
framework to verify that a research report is faithful to its source
documents — without a human reviewer or LLM judge — so that hallucinated
or detached outputs fail the build just like broken code.

**Workflow**: the agent fetches source documents and saves them as plain
text alongside the report inside the task's output directory. Verification
then runs entirely in the Nix sandbox (no network) using two deterministic
tiers: a fast lexical gate and a slower NLI claim-level check.

**Done when** (observable, will compile into cluster verifications):

- [ ] `mkResearchTask` is callable in any `task.nix` and produces a valid
  Nix derivation: `nix flake check` exits 0 with a `mkResearchTask` task
  present in `flake.nix`.
- [ ] A research task whose `$out/report.md` has TF-IDF cosine similarity
  < 0.10 against all files in `$out/sources/` fails verification: the
  derivation build exits non-zero with a message naming the gate that
  tripped.
- [ ] A research task whose `$out/report.md` has mean NLI entailment score
  < 0.35 (sentence-level, AlignScore NLI-SP, calibrated for synthesis tasks)
  against `$out/sources/` fails verification: build exits non-zero. Default
  threshold is 0.35; extraction tasks may use higher values; synthesis tasks
  that draw analytical conclusions may need values as low as 0.30.
- [ ] A research task with a report that is faithfully grounded (synthetic
  fixture: report sentences copied verbatim from source) passes both gates:
  `nix build .#research-fixture` exits 0.
- [ ] A research task with a fabricated claim not present in any source
  (synthetic fixture: one sentence inserted that contradicts sources) fails
  the NLI gate: `nix build .#research-fixture-bad` exits non-zero.
- [ ] AlignScore model weights are packaged as a Nix derivation:
  `nix build .#alignscore-weights` exits 0, producing the checkpoint files
  needed by the verify script.
- [ ] Thresholds are configurable per task:
  `mkResearchTask { tfidfThreshold = 0.05; nliThreshold = 0.60; }` is
  valid Nix and overrides the defaults without touching lib.nix internals.
- [ ] Verify is deterministic: running `nix build .#research-fixture` twice
  on the same inputs produces the same store path (content-addressed).
- [ ] `nix flake check` exits 0 on the project root after all changes.

### US10 (spec amendment): VM verification as first-class derivation

*N2 amendment — adds mkVmVerify as the fifth lib function.*

As a task author needing full-system integration tests, I want to declare a
NixOS VM test inside a cluster's task list so that the cluster cannot build
until the VM test passes, exactly like any other task.

**Done when**:
- [ ] `mkVmVerify { id; nodes; testScript; }` is callable in any `task.nix`
  or `clusters.nix` and returns a derivation a cluster can depend on.
- [ ] The derivation is a standard `pkgs.testers.runNixOSTest` result —
  no custom orchestration, no state files.
- [ ] On darwin with no linux-builder, `nix build .#task-VM001` fails with
  a clear "linux builder required" message rather than a silent skip.
- [ ] `nix flake check` exits 0 on x86_64-linux.
- [ ] The architecture docs list mkVmVerify as the 5th lib function.

### US11 (P1): Hierarchical cluster composition — clusters of clusters

As a project lead managing a large system, I want to compose clusters into
larger clusters without limit, so that I can model any decomposition depth
the project requires without hitting a framework ceiling.

The composition rule must be uniform: a cluster of clusters behaves exactly
like a cluster of tasks — it verifies its members before it can build, and
the full derivation graph reflects every node at every depth.  No new lib
functions are introduced; mkCluster handles tasks and sub-clusters
identically.

**Done when** (observable, will compile into cluster verifications):

- [ ] `mkCluster { members = [ clusterA clusterB ]; }` evaluates to a valid
  Nix derivation and is accepted by `nix flake check` without error.
- [ ] A parent cluster whose sub-cluster has a failing verify criterion also
  fails to build: the parent derivation exits non-zero and the log names the
  failing member cluster.
- [ ] `amonite verify CNNN` works on any cluster at any nesting depth:
  verifying a grandparent cluster transitively verifies every descendant
  cluster and task.
- [ ] The `graph.<system>` flake output includes every node (task and cluster)
  at every nesting depth; running `amonite tui --dump` shows the full
  hierarchy with no nodes missing.
- [ ] Three-level nesting is demonstrated end-to-end via a fixture in
  `clusters.nix`: a grandparent cluster whose members include at least one
  cluster that itself has task members; all three levels build and verify.
- [ ] `nix flake check` exits 0 after all changes (N1).
- [ ] No new lib functions are added (N2: surface stays at five).

## Out of scope

- Home-manager module (separate PR after nixpkgs submission).
- Remote builder configuration.
- amonite daemon / persistent state beyond the Nix store.
- Windows/WSL support.

## Open questions

<!-- none — OQ1/OQ2/OQ3 resolved:
  OQ1: CI matrix = ubuntu-latest (x86_64-linux) + macos-latest (aarch64-darwin).
  OQ2: Cachix enabled; cache name = "amonite".
  OQ3: CLI reference page included, generated from `amonite --help` in the docs build.
-->
