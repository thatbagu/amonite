# Changelog

All notable changes to amonite are documented here.
Format: [Keep a Changelog](https://keepachangelog.com/en/1.0.0/).
Versioning: [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

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
