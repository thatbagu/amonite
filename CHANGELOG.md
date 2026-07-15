# Changelog

All notable changes to amonite are documented here.
Format: [Keep a Changelog](https://keepachangelog.com/en/1.0.0/).
Versioning: [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## 1.0.0 (2026-07-15)


### Features

* amonite v0.2 — docs, CI/release pipeline, TUI waves, shell completions ([797eb3d](https://github.com/thatbagu/amonite/commit/797eb3d98c99e8b1091911a265f0384135449233))
* **commands:** enforce behavioral verification over grep/file-existence checks ([7fce0cd](https://github.com/thatbagu/amonite/commit/7fce0cd656f4c5ad290b7e59c17a8292321a9c62))
* implement C006 research-verify — mkResearchTask + offline faithfulness verification ([1778eac](https://github.com/thatbagu/amonite/commit/1778eacb6f99f56d8f236de2f1186954b33ba884))
* scaffold C006 research-verify — T012-T015 capsules ([af119f3](https://github.com/thatbagu/amonite/commit/af119f3e2467a3e458f45601cc8843034cd3b5e0))
* US11 hierarchical cluster composition — clusters of clusters ([a8a69a5](https://github.com/thatbagu/amonite/commit/a8a69a570c7f96c797bb2afb653821c8a32dfa39))
* wire full NLI gate into R001/R002 — AlignScore + roberta-base ([f1e154f](https://github.com/thatbagu/amonite/commit/f1e154fa29b18b09f42b5905465534651dbe202b))


### Bug Fixes

* behavioral verify criteria + audit follow-up (T012, T013, T014) ([3f69568](https://github.com/thatbagu/amonite/commit/3f695686d95992fcd82d27739178f18d3a9e85d2))
* set real AlignScore-base.ckpt sha256 hash ([29b5bbd](https://github.com/thatbagu/amonite/commit/29b5bbdffcbd6dbd47ce507a0c998382b09bea42))
* wire AlignScore NLI gate fully — real hashes, compat patches, calibrated thresholds ([eeb0e9e](https://github.com/thatbagu/amonite/commit/eeb0e9e805f18dc7f92ac2ee6bb702043765c49a))

## [Unreleased]

### Added
- `amonite init --flow-only` for grafting the flow layer onto existing flake projects
- nixpkgs-ready `package.nix` with proper meta fields
- Shell completions for bash, zsh, and fish
- CLI UX guards: typed error messages, tty-aware status colour
- Parallel-agent wave planner (`amonite waves`, `task-graph.json`)
- mdBook documentation site deployed to GitHub Pages
- GitHub Actions CI gate (nix flake check, ubuntu + macos matrix, Cachix)
- Tag-based release pipeline with auto-populated changelog body

## [0.1.0] - 2025-01-01

### Added
- Initial release of amonite
- Core library: `mkTask`, `mkCluster`, `mkApplication`
- Spec-driven development compiled to Nix derivations
- `amonite init`, `amonite verify`, `amonite status` CLI commands
- TUI for task graph visualisation

[Unreleased]: https://github.com/thatbagu/amonite/compare/v0.1.0...HEAD
[0.1.0]: https://github.com/thatbagu/amonite/releases/tag/v0.1.0
