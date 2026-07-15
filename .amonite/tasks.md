# Tasks: amonite v0.2 — self-improvement sprint

**Plan**: .amonite/plan.md

<!-- Each task row corresponds 1:1 to tasks/TXXX/task.nix. A task is DONE
     when its derivation builds: `amonite verify TXXX`. Checkboxes here are
     a human-readable mirror; the store is the truth. -->

Format: `[ID] [P?] [Cluster] Title — env grants`

- `[P]` = parallelizable (no dependency on unfinished tasks)
- `[Cluster]` = which cluster this task rolls up into

## C001: cli-hardening (includes wave planner)

- [x] T001 [P] [C001] CLI --flow-only flag and error hint — env: pkgs.bash pkgs.git pkgs.shellcheck
      verify:
        shellcheck-clean: shellcheck --shell=bash passes on bin/amonite
        flow-only-creates-amonite-dir: init --flow-only in empty dir creates .amonite/
        flow-only-skips-flake: init --flow-only in dir with flake.nix leaves flake.nix unchanged
        flow-only-idempotent: running init --flow-only twice exits 0 both times
        existing-flake-hint: init (no flag) on existing flake prints --flow-only in stderr

- [ ] T002 [P] [C001] CLI UX guards and tty-aware status colour — env: pkgs.bash pkgs.git pkgs.shellcheck
      verify:
        shellcheck-clean: shellcheck --shell=bash passes on bin/amonite
        verify-no-arg-exits-1: amonite verify with no argument exits 1
        verify-no-arg-stderr: amonite verify with no argument emits usage to stderr
        bad-id-hint: amonite task new invalid-id "title" prints T[0-9]+ hint to stderr and exits 1
        status-runs: amonite status exits 0 in a valid project directory

- [ ] T005 [C001] Parallel-agent wave planner — env: pkgs.bash pkgs.git pkgs.shellcheck pkgs.jq (depends: T001 T002)
      verify:
        shellcheck-clean: shellcheck --shell=bash passes on bin/amonite
        waves-no-graph-exits-1: amonite waves with no task-graph.json exits 1
        waves-no-graph-stderr: error message mentions task-graph.json
        waves-reads-graph: amonite waves in project with task-graph.json prints wave headers
        lib-depends-field: mkTask with depends=[T001] stores depends in passthru.amonite.depends
        graph-includes-depends: mkGraph node output includes depends field

## C002: distribution

- [ ] T003 [P] [C002] nixpkgs-convention package.nix — env: pkgs.bash pkgs.nix pkgs.git
      verify:
        file-exists: package.nix present in repo root
        meta-description: nix eval .#meta.description is non-empty string
        meta-license: nix eval .#meta.license.spdxId equals "MIT" (or correct identifier)
        meta-mainProgram: nix eval .#meta.mainProgram equals "amonite"
        help-output: amonite --help output contains "init" "verify" "status"

- [ ] T004 [P] [C002] Shell completions (bash, zsh, fish) — env: pkgs.bash pkgs.zsh pkgs.fish
      verify:
        bash-syntax: bash -n share/completions/amonite.bash exits 0
        zsh-syntax: zsh --no-exec share/completions/_amonite exits 0
        fish-syntax: fish --command "source share/completions/amonite.fish" exits 0
        bash-subcommands: sourcing bash completion and running __amonite_complete produces "init verify status task tui generations rollback"

- [ ] T010 [P] [C004] release-please automated release pipeline — env: pkgs.bash pkgs.coreutils
      verify:
        release-please-workflow-exists: test -f "$out/.github/workflows/release-please.yml"
        has-release-please-action: grep -q "release-please-action" "$out/.github/workflows/release-please.yml"
        config-exists: test -f "$out/release-please-config.json"
        manifest-exists: test -f "$out/.release-please-manifest.json"
        release-workflow-updated: grep -q "release-please" "$out/.github/workflows/release.yml" (or tag trigger still present)
        contributing-updated: grep -qi "release-please" "$out/CONTRIBUTING.md"

- [ ] T011 [P] [C005] TUI wave view — env: pkgs.go pkgs.coreutils
      verify:
        tui-builds: nix build .#amonite-tui exits 0
        wave-key-present: grep -q '"w"' "$out/tui/main.go" (or equivalent toggle implementation)
        wave-render-present: grep -q "wave" "$out/tui/main.go" (case-insensitive)
        flake-check: nix flake check exits 0

## C003: docs-site

- [ ] T006 [P] [C003] mdBook docs content — env: pkgs.mdbook pkgs.bash pkgs.coreutils
      verify:
        book-toml-exists: test -f "$out/docs/book.toml" exits 0
        all-pages-exist: test -f for getting-started, architecture, contributing, cli-reference
        mdbook-builds: mdbook build docs exits 0 inside derivation sandbox
        cli-reference-has-content: grep -q "amonite" "$out/docs/cli-reference.md"
        readme-links-pages: grep -q "github.io" "$out/README.md"

- [ ] T007 [P] [C003] GitHub Pages docs CI workflow — env: pkgs.bash pkgs.coreutils
      verify:
        workflow-exists: test -f "$out/.github/workflows/docs.yml"
        triggers-on-docs: grep -q "docs/" "$out/.github/workflows/docs.yml"
        has-deploy-pages: grep -q "deploy-pages" "$out/.github/workflows/docs.yml"
        has-pr-build-check: grep -q "pull_request" "$out/.github/workflows/docs.yml"

## C004: release-pipeline

- [ ] T008 [P] [C004] PR CI gate workflow (nix flake check, matrix, Cachix) — env: pkgs.bash pkgs.coreutils
      verify:
        workflow-exists: test -f "$out/.github/workflows/ci.yml"
        has-matrix-macos: grep -q "macos-latest" "$out/.github/workflows/ci.yml"
        has-cachix: grep -q "cachix" "$out/.github/workflows/ci.yml"
        has-nix-flake-check: grep -q "nix flake check" "$out/.github/workflows/ci.yml"
        targets-main: grep -q "main" "$out/.github/workflows/ci.yml"

- [ ] T009 [P] [C004] Release workflow + CHANGELOG + CONTRIBUTING — env: pkgs.bash pkgs.coreutils
      verify:
        release-workflow-exists: test -f "$out/.github/workflows/release.yml"
        tag-trigger: grep -q "v\[0-9\]" "$out/.github/workflows/release.yml"
        creates-gh-release: grep -q "softprops/action-gh-release" "$out/.github/workflows/release.yml"
        changelog-exists: test -f "$out/CHANGELOG.md"
        changelog-has-unreleased: grep -q "Unreleased" "$out/CHANGELOG.md"
        contributing-exists: test -f "$out/CONTRIBUTING.md"
        contributing-has-conventional: grep -qi "conventional" "$out/CONTRIBUTING.md"

## Cluster verifications

- C001: T001, T002, T005 build; `amonite status` runs; `amonite waves` reads graph; shellcheck clean.
- C002: package.nix and completions present; meta fields valid; syntax checks pass.
- C003: all docs pages exist; `mdbook build docs` exits 0; docs.yml with Pages deploy; README links to github.io.
- C004: ci.yml (matrix+cachix+flake check), release-please.yml, release.yml, CHANGELOG.md, CONTRIBUTING.md all present and correct.
- C005: TUI builds; wave view responds to `w` key; no-graph message shown when task-graph.json absent.
- APP: C001+C002+C003+C004+C005 verified; `amonite --help` lists all subcommands.

## gate.live (impure, manual)

- [ ] `nix profile install nixpkgs#amonite` works after nixpkgs PR is merged
- [ ] Tab completion works end-to-end in an interactive shell session
- [ ] `amonite init --flow-only` applied to a real third-party project succeeds
- [ ] GitHub Actions CI run passes on a real PR (ubuntu-latest + macos-latest)
- [ ] Docs site reachable at https://thatbagu.github.io/amonite/ after first docs push
- [ ] GitHub Release created with correct CHANGELOG.md body when v0.2.0 tag is pushed
