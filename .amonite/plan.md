# Implementation Plan: amonite v0.2 — self-improvement sprint

**Spec**: .amonite/spec.md · **Principles check**: pass — updated for US6/US7 (P1/P2/P3, E1–E4, N1–N3 all satisfied)

## Technical context

- **Language/runtime**: bash (CLI), Go 1.22 (TUI), Nix (lib + package derivation)
- **Key dependencies**: git, nix, bubbletea/lipgloss (TUI, already vendored)
- **Storage**: none beyond the Nix store and .amonite/ flow files
- **Target**: x86_64-linux, aarch64-linux, x86_64-darwin, aarch64-darwin

## Meta environment (compiles into project flake devShell)

<!-- Minimal: shellcheck for linting, go for TUI work, mdbook for local
     docs builds. Everything else is already in the flake. -->

- pkgs.shellcheck
- pkgs.go
- pkgs.mdbook

## Architecture

Six independent deliverables that share no runtime coupling:

1. **bin/amonite** — bash CLI extended with `--flow-only` flag and UX fixes.
   Self-contained; verified by shellcheck + behavioural tests in derivation.

2. **package.nix** — nixpkgs-convention standalone derivation. Wraps the
   existing flake package logic into `callPackage`-compatible form with
   proper `meta` attributes.

3. **share/completions/** — static completion scripts (bash, zsh, fish)
   generated/written by hand, installed into `$out/share/bash-completion/`,
   `$out/share/zsh/site-functions/`, `$out/share/fish/vendor_completions.d/`.
   Dynamic `tasks/T*` completion uses a shell function that reads the CWD at
   completion time — no Nix involvement needed.

4. **bin/amonite UX hardening** — additional guards in bash CLI: arg
   validation, ID format check, tty-aware colour in `status`. Part of the
   same task as (1) since they touch the same file.

5. **docs/** — mdBook source tree: `book.toml`, `SUMMARY.md`,
   `getting-started.md`, `architecture.md` (pre-existing), `contributing.md`,
   `cli-reference.md` (generated from `amonite --help` at build time).
   Verified hermetically by running `mdbook build docs` inside the task
   derivation. The cli-reference page is produced by running the amonite
   binary from `$src` and capturing `--help` output into a markdown file.

6. **.github/workflows/** + **CHANGELOG.md** + **CONTRIBUTING.md** —
   three GitHub Actions workflows and two project hygiene files:
   - `ci.yml`: triggers on PRs to `main`; matrix `ubuntu-latest` +
     `macos-latest`; installs Nix via `cachix/install-nix-action`; pushes/
     pulls Cachix cache `amonite`; runs `nix flake check`.
   - `docs.yml`: triggers on push to `main` when `docs/**` changes; builds
     mdBook; deploys to GitHub Pages via `actions/deploy-pages`. Also runs
     a `mdbook build` check on PRs targeting `main`.
   - `release.yml`: triggers on `v[0-9]+.[0-9]+.[0-9]+` tag push; creates
     a GitHub Release via `softprops/action-gh-release` with the matching
     `CHANGELOG.md` section as the release body.
   - `CHANGELOG.md`: Keep a Changelog 1.0.0 format.
   - `CONTRIBUTING.md`: branch prefixes, Conventional Commits, release
     tagging procedure.
   Verified structurally in task derivations (file existence + grep for key
   strings). Actual CI execution and GitHub Release creation are gate.live.

## Verification strategy

| Layer | How verified | Hermetic? |
|-------|--------------|-----------|
| --flow-only flag | derivation: run amonite init --flow-only in a scratch tree, assert .amonite/ present, flake.nix absent | yes |
| --flow-only idempotency | derivation: run twice, assert exit 0 both times | yes |
| error hint on existing flake | derivation: run amonite init on tree with flake.nix, grep stderr for --flow-only | yes |
| shellcheck | derivation: shellcheck --shell=bash bin/amonite exits 0 | yes |
| package.nix builds | nix-build package.nix (in task derivation via nix-build --dry-run) | yes |
| package meta | derivation: nix eval the meta fields, assert non-empty | yes |
| amonite --help output | derivation: run binary, grep for expected subcommand strings | yes |
| completion syntax | derivation: bash -n, zsh --no-exec, fish --no-execute on each file | yes |
| completion subcommands | derivation: source bash completion, exercise __amonite_complete, assert expected tokens | yes |
| UX: verify no-arg | derivation: run amonite verify, assert exit 1 + stderr non-empty | yes |
| UX: bad ID format | derivation: run amonite task new badid title, grep stderr for T[0-9]+ hint | yes |
| gate.live | nixpkgs PR accepted; `nix profile install nixpkgs#amonite` works | NO |
| docs pages all exist | derivation: test -f for each of 5 pages under $out/docs/ | yes |
| mdbook builds | derivation: mdbook build docs exits 0 inside sandbox | yes |
| cli-reference has content | derivation: grep -q amonite $out/docs/cli-reference.md | yes |
| docs.yml exists + triggers on docs/ | derivation: test -f + grep docs/ | yes |
| docs.yml deploys to Pages | derivation: grep -q deploy-pages .github/workflows/docs.yml | yes |
| README links to Pages URL | derivation: grep -q github.io README.md | yes |
| ci.yml exists + matrix | derivation: test -f + grep macos-latest | yes |
| ci.yml has Cachix | derivation: grep -q cachix .github/workflows/ci.yml | yes |
| ci.yml runs nix flake check | derivation: grep -q "nix flake check" | yes |
| release.yml exists + v* trigger | derivation: test -f + grep tag pattern | yes |
| release.yml creates GH release | derivation: grep -q softprops/action-gh-release | yes |
| CHANGELOG has [Unreleased] | derivation: grep -q Unreleased CHANGELOG.md | yes |
| CONTRIBUTING has Conventional Commits | derivation: grep -qi conventional CONTRIBUTING.md | yes |
| gate.live | GitHub Actions CI run passes on a real PR | NO |
| gate.live | docs site reachable at github.io/amonite after first docs push | NO |
| gate.live | GitHub Release created when v0.2.0 tag is pushed | NO |

## Cluster topology (planned)

- C001 cli-hardening ← T001 (--flow-only flag), T002 (UX guards + status colour), T005 (wave planner)
- C002 distribution   ← T003 (package.nix), T004 (completions)
- C003 docs-site      ← T006 (mdBook content), T007 (GitHub Pages CI workflow)
- C004 release-pipeline ← T008 (PR CI gate workflow), T009 (release workflow + CHANGELOG + CONTRIBUTING)
- APP                 ← C001, C002, C003, C004

## Risks / complexity

| Risk | Mitigation |
|------|------------|
| nix-build in hermetic sandbox cannot call nix | use nix eval --raw for meta checks; skip nix-build in derivation, gate.live instead |
| zsh completion syntax varies by version | target zsh 5.9 (nixpkgs stable); test with `zsh --no-exec` only |
| fish completion test needs fish binary in env | add pkgs.fish to T004 env grants |
| mdbook may attempt network access for external themes | pin to a local theme; book.toml must not reference any remote resource; `mdbook build` in sandbox will fail at network call if misconfigured — caught hermetically |
| GitHub Actions YAML not validated structurally in sandbox | grep-based checks cover key strings; full YAML validation happens when CI runs on GitHub (gate.live); no yaml parser added (E4: no new runtimes) |
