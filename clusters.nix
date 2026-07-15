{ pkgs, tasks, amonite }:

let
  cliHardening = amonite.mkCluster {
    id = "C001";
    title = "cli-hardening";
    tasks = with tasks; [ T001 T002 T005 ];
    env = [ pkgs.bash pkgs.git pkgs.shellcheck pkgs.coreutils ];
    verify = {
      # T002 carries the most complete CLI (UX guards + colour + waves);
      # confirm shellcheck is still clean on its shipped binary.
      shellcheck-final = ''
        shellcheck --shell=bash "$out/tasks/T002/bin/amonite"
      '';
      # End-to-end: init --flow-only then status must exit 0.
      status-works = ''
        tmp=$(mktemp -d)
        cd "$tmp"
        export HOME="$tmp"
        git init -q
        git config user.email ci@amonite
        git config user.name amonite
        AMONITE_SHARE="$out/tasks/T002" bash "$out/tasks/T002/bin/amonite" \
          init --flow-only
        AMONITE_SHARE="$out/tasks/T002" bash "$out/tasks/T002/bin/amonite" status
      '';
      # waves command exits 1 when no graph exists (expected behaviour).
      waves-no-graph = ''
        tmp=$(mktemp -d)
        cd "$tmp"
        AMONITE_SHARE="$out/tasks/T005" bash "$out/tasks/T005/bin/amonite" \
          waves 2>&1 | grep -q 'task-graph.json'
      '';
    };
  };

  distribution = amonite.mkCluster {
    id = "C002";
    title = "distribution";
    tasks = with tasks; [ T003 T004 ];
    verify = {
      package-nix-present  = ''test -f "$out/tasks/T003/package.nix"'';
      completions-present  = ''
        test -f "$out/tasks/T004/share/completions/amonite.bash"
        test -f "$out/tasks/T004/share/completions/_amonite"
        test -f "$out/tasks/T004/share/completions/amonite.fish"
      '';
    };
  };

  docsSite = amonite.mkCluster {
    id = "C003";
    title = "docs-site";
    tasks = with tasks; [ T006 T007 ];
    verify = {
      docs-content-present = ''
        test -f "$out/tasks/T006/docs/book.toml"
        test -f "$out/tasks/T006/docs/getting-started.md"
        test -f "$out/tasks/T006/docs/cli-reference.md"
      '';
      docs-workflow-present = ''
        test -f "$out/tasks/T007/.github/workflows/docs.yml"
      '';
    };
  };

  releasePipeline = amonite.mkCluster {
    id = "C004";
    title = "release-pipeline";
    tasks = with tasks; [ T008 T009 T010 ];
    verify = {
      ci-workflow-present = ''
        test -f "$out/tasks/T008/.github/workflows/ci.yml"
      '';
      release-workflow-present = ''
        test -f "$out/tasks/T009/.github/workflows/release.yml"
      '';
      changelog-present = ''
        test -f "$out/tasks/T009/CHANGELOG.md"
        grep -q "Unreleased" "$out/tasks/T009/CHANGELOG.md"
      '';
    };
  };

  tuiWaves = amonite.mkCluster {
    id = "C005";
    title = "tui-waves";
    tasks = with tasks; [ T011 ];
    verify = {
      tui-task-present = ''test -f "$out/tasks/T011/tui/main.go"'';
    };
  };

  researchVerify = amonite.mkCluster {
    id = "C006";
    title = "research-verify";
    tasks = with tasks; [ T012 T013 T014 T015 ];
    verify = {
      # mkResearchTask is exported from lib.nix
      lib-fn-present = ''
        grep -q "mkResearchTask" "$out/tasks/T012/nix/lib.nix"
      '';
      # TF-IDF script is installed
      tfidf-script-present = ''
        test -f "$out/tasks/T013/nix/research/verify_tfidf.py"
      '';
      # NLI script is installed
      nli-script-present = ''
        test -f "$out/tasks/T015/nix/research/verify_nli.py"
      '';
      # AlignScore weights derivation declared
      weights-derivation-present = ''
        test -f "$out/tasks/T014/nix/pkgs/alignscore.nix"
      '';
    };
  };

  # US11 implementation cluster — tasks that deliver recursive mkGraph + fixture
  hierarchyImpl = amonite.mkCluster {
    id = "C007";
    title = "hierarchy-composition";
    tasks = with tasks; [ T016 T017 ];
    env = [ pkgs.nix pkgs.coreutils ];
    verify = {
      # Recursive mkGraph: lib.nix must export the updated function
      mkgraph-is-recursive = ''
        grep -q "collectAll" "$out/tasks/T016/nix/lib.nix"
      '';
      # Fixture clusters exist in clusters.nix
      fixture-c008-declared = ''
        grep -q '"C008"' "$out/tasks/T017/clusters.nix"
      '';
      fixture-c009-declared = ''
        grep -q '"C009"' "$out/tasks/T017/clusters.nix"
      '';
    };
  };

  # US11 three-level fixture: proves mkCluster composes uniformly at any depth.
  # C009 (grandparent) → C008 (cluster) → tasks (T001, T003) is the three-level
  # hierarchy; C008 is an ordinary cluster that itself contains tasks.
  hierarchyLeaf = amonite.mkCluster {
    id = "C008";
    title = "hierarchy-leaf";
    tasks = with tasks; [ T001 T003 ];
    verify = {
      leaf-t001-present = ''test -e "$out/tasks/T001"'';
      leaf-t003-present = ''test -e "$out/tasks/T003"'';
    };
  };

  hierarchyRoot = amonite.mkCluster {
    id = "C009";
    title = "hierarchy-root";
    # C008 (a cluster) and T002 (a task) as siblings — proves uniform treatment
    tasks = with tasks; [ hierarchyLeaf T002 ];
    env = [ pkgs.coreutils ];
    verify = {
      sub-cluster-present = ''test -e "$out/tasks/C008"'';
      leaf-task-present   = ''test -e "$out/tasks/T002"'';
      # Three-level artifact chain: grandparent → cluster → task artifact.
      # T001 produces bin/amonite; follow C009→C008→T001 through symlinks.
      three-level-chain = ''
        test -e "$out/tasks/C008/tasks/T001/bin/amonite" \
          || { echo "bin/amonite not reachable through C009→C008→T001 chain"; exit 1; }
      '';
    };
  };

in
{
  C001 = cliHardening;
  C002 = distribution;
  C003 = docsSite;
  C004 = releasePipeline;
  C005 = tuiWaves;
  C006 = researchVerify;
  C007 = hierarchyImpl;
  C008 = hierarchyLeaf;
  C009 = hierarchyRoot;

  APP = amonite.mkApplication {
    id = "APP";
    title = "amonite v0.2";
    tasks = [ cliHardening distribution docsSite releasePipeline tuiWaves researchVerify ];
    env = [ pkgs.bash pkgs.coreutils ];
    verify = {
      help-complete = ''
        msg=$(AMONITE_SHARE="$out/tasks/C001/tasks/T002" \
              bash "$out/tasks/C001/tasks/T002/bin/amonite" --help 2>&1 || true)
        echo "$msg" | grep -q 'init'
        echo "$msg" | grep -q 'waves'
        echo "$msg" | grep -q 'status'
      '';
      research-lib-present = ''
        grep -q "mkResearchTask" "$out/tasks/C006/tasks/T012/nix/lib.nix"
      '';
    };
  };
}
