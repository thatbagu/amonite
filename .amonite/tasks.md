# Tasks: amonite v0.3 — hierarchical clusters (US11)

**Plan**: .amonite/plan.md

<!-- Each task row corresponds 1:1 to tasks/TXXX/task.nix. A task is DONE
     when its derivation builds: `amonite verify TXXX`. Checkboxes here are
     a human-readable mirror; the store is the truth. -->

Format: `[ID] [P?] [Cluster] Title — env grants`

- `[P]` = parallelizable (no dependency on unfinished tasks)
- `[Cluster]` = which cluster this task rolls up into

## C001: cli-hardening (includes wave planner)

- [x] T001 [P] [C001] CLI --flow-only flag and error hint ● — env: pkgs.bash pkgs.git pkgs.shellcheck
      verify:
        shellcheck-clean: shellcheck --shell=bash passes on bin/amonite
        flow-only-creates-amonite-dir: init --flow-only in empty dir creates .amonite/
        flow-only-skips-flake: init --flow-only in dir with flake.nix leaves flake.nix unchanged
        flow-only-idempotent: running init --flow-only twice exits 0 both times
        existing-flake-hint: init (no flag) on existing flake prints --flow-only in stderr

- [x] T002 [P] [C001] CLI UX guards and tty-aware status colour — env: pkgs.bash pkgs.git pkgs.shellcheck
      verify:
        shellcheck-clean: shellcheck --shell=bash passes on bin/amonite
        verify-no-arg-exits-1: amonite verify with no argument exits 1
        verify-no-arg-stderr: amonite verify with no argument emits usage to stderr
        bad-id-hint: amonite task new invalid-id "title" prints T[0-9]+ hint to stderr and exits 1
        status-runs: amonite status exits 0 in a valid project directory

- [x] T005 [C001] Parallel-agent wave planner — env: pkgs.bash pkgs.git pkgs.shellcheck pkgs.jq (depends: T001 T002)
      verify:
        shellcheck-clean: shellcheck --shell=bash passes on bin/amonite
        waves-no-graph-exits-1: amonite waves with no task-graph.json exits 1
        waves-no-graph-stderr: error message mentions task-graph.json
        waves-reads-graph: amonite waves in project with task-graph.json prints wave headers
        lib-depends-field: mkTask with depends=[T001] stores depends in passthru.amonite.depends
        graph-includes-depends: mkGraph node output includes depends field

## C002: distribution

- [x] T003 [P] [C002] nixpkgs-convention package.nix — env: pkgs.bash pkgs.nix pkgs.git
      verify:
        file-exists: package.nix present in repo root
        meta-description: nix eval .#meta.description is non-empty string
        meta-license: nix eval .#meta.license.spdxId equals "MIT" (or correct identifier)
        meta-mainProgram: nix eval .#meta.mainProgram equals "amonite"
        help-output: amonite --help output contains "init" "verify" "status"

- [x] T004 [P] [C002] Shell completions (bash, zsh, fish) — env: pkgs.bash pkgs.zsh pkgs.fish
      verify:
        bash-syntax: bash -n share/completions/amonite.bash exits 0
        zsh-syntax: zsh --no-exec share/completions/_amonite exits 0
        fish-syntax: fish --command "source share/completions/amonite.fish" exits 0
        bash-subcommands: sourcing bash completion and running __amonite_complete produces "init verify status task tui generations rollback"

- [x] T010 [P] [C004] release-please automated release pipeline — env: pkgs.bash pkgs.coreutils
      verify:
        release-please-workflow-exists: test -f "$out/.github/workflows/release-please.yml"
        has-release-please-action: grep -q "release-please-action" "$out/.github/workflows/release-please.yml"
        config-exists: test -f "$out/release-please-config.json"
        manifest-exists: test -f "$out/.release-please-manifest.json"
        release-workflow-updated: grep -q "release-please" "$out/.github/workflows/release.yml" (or tag trigger still present)
        contributing-updated: grep -qi "release-please" "$out/CONTRIBUTING.md"

- [x] T011 [P] [C005] TUI wave view — env: pkgs.go pkgs.coreutils
      verify:
        tui-builds: nix build .#amonite-tui exits 0
        wave-key-present: grep -q '"w"' "$out/tui/main.go" (or equivalent toggle implementation)
        wave-render-present: grep -q "wave" "$out/tui/main.go" (case-insensitive)
        flake-check: nix flake check exits 0

## C003: docs-site

- [x] T006 [P] [C003] mdBook docs content — env: pkgs.mdbook pkgs.bash pkgs.coreutils
      verify:
        book-toml-exists: test -f "$out/docs/book.toml" exits 0
        all-pages-exist: test -f for getting-started, architecture, contributing, cli-reference
        mdbook-builds: mdbook build docs exits 0 inside derivation sandbox
        cli-reference-has-content: grep -q "amonite" "$out/docs/cli-reference.md"
        readme-links-pages: grep -q "github.io" "$out/README.md"

- [x] T007 [P] [C003] GitHub Pages docs CI workflow — env: pkgs.bash pkgs.coreutils
      verify:
        workflow-exists: test -f "$out/.github/workflows/docs.yml"
        triggers-on-docs: grep -q "docs/" "$out/.github/workflows/docs.yml"
        has-deploy-pages: grep -q "deploy-pages" "$out/.github/workflows/docs.yml"
        has-pr-build-check: grep -q "pull_request" "$out/.github/workflows/docs.yml"

## C004: release-pipeline

- [x] T008 [P] [C004] PR CI gate workflow (nix flake check, matrix, Cachix) — env: pkgs.bash pkgs.coreutils
      verify:
        workflow-exists: test -f "$out/.github/workflows/ci.yml"
        has-matrix-macos: grep -q "macos-latest" "$out/.github/workflows/ci.yml"
        has-cachix: grep -q "cachix" "$out/.github/workflows/ci.yml"
        has-nix-flake-check: grep -q "nix flake check" "$out/.github/workflows/ci.yml"
        targets-main: grep -q "main" "$out/.github/workflows/ci.yml"

- [x] T009 [P] [C004] Release workflow + CHANGELOG + CONTRIBUTING — env: pkgs.bash pkgs.coreutils
      verify:
        release-workflow-exists: test -f "$out/.github/workflows/release.yml"
        tag-trigger: grep -q "v\[0-9\]" "$out/.github/workflows/release.yml"
        creates-gh-release: grep -q "softprops/action-gh-release" "$out/.github/workflows/release.yml"
        changelog-exists: test -f "$out/CHANGELOG.md"
        changelog-has-unreleased: grep -q "Unreleased" "$out/CHANGELOG.md"
        contributing-exists: test -f "$out/CONTRIBUTING.md"
        contributing-has-conventional: grep -qi "conventional" "$out/CONTRIBUTING.md"

## C006: research-verify

- [ ] T012 [P] [C006] mkResearchTask lib function — env: pkgs.nix pkgs.git pkgs.coreutils
      verify:
        lib-exports-fn: grep -q "mkResearchTask" nix/lib.nix
        fn-accepts-thresholds: grep -q "tfidfThreshold" and "nliThreshold" in lib.nix
        flake-dogfoods-fn: grep -q "mkResearchTask" flake.nix
        enforces-sources-dir: grep -q "sources" in mkResearchTask body
        enforces-report-md: grep -q "report.md" in mkResearchTask body

- [ ] T013 [P] [C006] TF-IDF faithfulness verify script — env: pkgs.coreutils pkgs.python3+scikit-learn
      verify:
        script-exists: test -f nix/research/verify_tfidf.py
        script-syntax: python3 -m py_compile verify_tfidf.py exits 0
        rejects-detached-report: cosine < 0.10 fixture → exits non-zero
        accepts-grounded-report: verbatim copy fixture → exits 0
        runs-fast: timeout 5s for small input

- [ ] T014 [P] [C006] AlignScore model weights Nix derivation — env: pkgs.coreutils pkgs.curl pkgs.cacert
      verify:
        weights-nix-exists: test -f nix/pkgs/alignscore.nix
        weights-nix-parses: nix-instantiate --parse exits 0
        flake-exposes-weights: grep -q "alignscore-weights" flake.nix
        is-fixed-output: grep -q "outputHash" in derivation
        checkpoint-path-declared: grep -q "AlignScore" in derivation

- [ ] T015 [C006] NLI faithfulness verify integration and fixtures — env: pkgs.coreutils pkgs.python3+torch+transformers (depends: T012 T013 T014)
      verify:
        nli-script-exists: test -f nix/research/verify_nli.py
        nli-script-syntax: python3 -m py_compile exits 0
        good-fixture-passes: nix build .#research-fixture exits 0
        bad-fixture-fails: nix build .#research-fixture-bad exits non-zero
        threshold-config-accepted: tfidfThreshold present in flake.nix or nix/
        deterministic: two builds of research-fixture produce same store path

## C007-hierarchy: hierarchical cluster composition (US11)

- [x] T016 [P] [C007-hierarchy] Recursive mkGraph in nix/lib.nix ● — env: pkgs.nix pkgs.coreutils
      verify:
        mkgraph-is-fn: nix eval confirms mkGraph is a lambda in the updated lib.nix
        recurses-into-members: inline fixture with a cluster-of-cluster evaluates; nix eval
          on the graph output shows child cluster node present in nodes list
        dedup-stable: a cluster referenced as member of two parents appears exactly once
          in the nodes list (nix eval confirms count = 1)
        nix-flake-evaluates: nix flake check --dry-run exits 0 (evaluation only)

- [x] T017 [P] [C007-hierarchy] Three-level cluster fixture in clusters.nix ● — env: pkgs.nix pkgs.coreutils
      verify:
        clusters-nix-has-c007: grep -q '"C007"' clusters.nix (or id = "C007")
        clusters-nix-has-c008: grep -q '"C008"' clusters.nix (or id = "C008")
        c007-evaluates: nix eval .#packages.x86_64-linux.cluster-C007 --impure exits 0
        c008-evaluates: nix eval .#packages.x86_64-linux.cluster-C008 --impure exits 0
        graph-has-c007: nix eval .#graph.x86_64-linux.nodes --json | grep -q '"C007"'
        graph-has-c008: nix eval .#graph.x86_64-linux.nodes --json | grep -q '"C008"'

## Cluster verifications

- C001: T001, T002, T005 build; `amonite status` runs; `amonite waves` reads graph; shellcheck clean.
- C002: package.nix and completions present; meta fields valid; syntax checks pass.
- C003: all docs pages exist; `mdbook build docs` exits 0; docs.yml with Pages deploy; README links to github.io.
- C004: ci.yml (matrix+cachix+flake check), release-please.yml, release.yml, CHANGELOG.md, CONTRIBUTING.md all present and correct.
- C005: TUI builds; wave view responds to `w` key; no-graph message shown when task-graph.json absent.
- C006: T012+T013+T014+T015 build; mkResearchTask in lib.nix; TF-IDF and NLI scripts present; good fixture passes, bad fixture fails.
- C007-hierarchy: T016+T017 build; mkGraph recursion verified by nix eval; C007 and C008 fixture clusters build and verify; C008's verify reads T001 artifact through the two-level symlink chain; `amonite tui --dump` output contains C007 and C008.
- APP: C001+C002+C003+C004+C005+C006 verified; `amonite --help` lists all subcommands; mkResearchTask present in lib.nix.

## gate.live (impure, manual)

- [ ] `nix profile install nixpkgs#amonite` works after nixpkgs PR is merged
- [ ] Tab completion works end-to-end in an interactive shell session
- [ ] `amonite init --flow-only` applied to a real third-party project succeeds
- [ ] GitHub Actions CI run passes on a real PR (ubuntu-latest + macos-latest)
- [ ] Docs site reachable at https://thatbagu.github.io/amonite/ after first docs push
- [ ] GitHub Release created with correct CHANGELOG.md body when v0.2.0 tag is pushed
