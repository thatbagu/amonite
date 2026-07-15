{ pkgs, tasks, amonite }:

let
  cliHardening = amonite.mkCluster {
    id = "C001";
    title = "cli-hardening";
    tasks = with tasks; [ T001 T002 T005 ];
    env = [ pkgs.bash pkgs.git pkgs.shellcheck pkgs.coreutils ];
    # Assemble a working CLI installation from the most feature-complete task (T005):
    # T001 scaffolds, T002 adds UX guards, T005 adds waves — use T005's output.
    # $out/bin/amonite is the invocable script; $out/share/amonite is its data root.
    build = ''
      mkdir -p "$out/bin" "$out/share/amonite"
      cp "$out/tasks/T005/bin/amonite"    "$out/bin/amonite"
      chmod +x "$out/bin/amonite"
      cp -r "$out/tasks/T005/templates/." "$out/share/amonite/templates/"
      cp -r "$out/tasks/T005/commands/."  "$out/share/amonite/commands/"
      cp -r "$out/tasks/T005/nix/."       "$out/share/amonite/nix/"
    '';
    verify = {
      shellcheck-final = ''
        shellcheck --shell=bash "$out/bin/amonite"
      '';
      status-works = ''
        tmp=$(mktemp -d)
        cd "$tmp"
        export HOME="$tmp"
        git init -q
        git config user.email ci@amonite
        git config user.name amonite
        AMONITE_SHARE="$out/share/amonite" bash "$out/bin/amonite" init --flow-only
        AMONITE_SHARE="$out/share/amonite" bash "$out/bin/amonite" status
      '';
      waves-no-graph = ''
        tmp=$(mktemp -d)
        cd "$tmp"
        AMONITE_SHARE="$out/share/amonite" bash "$out/bin/amonite" \
          waves 2>&1 | grep -q 'task-graph.json'
      '';
    };
  };

  distribution = amonite.mkCluster {
    id = "C002";
    title = "distribution";
    tasks = with tasks; [ T003 T004 ];
    env = [ pkgs.coreutils ];
    # Install completions to XDG-conventional paths so this cluster's output
    # composes into a full installation without extra path surgery.
    build = ''
      mkdir -p "$out/share/bash-completion/completions" \
               "$out/share/zsh/site-functions" \
               "$out/share/fish/vendor_completions.d"
      cp "$out/tasks/T004/share/completions/amonite.bash" \
         "$out/share/bash-completion/completions/amonite"
      cp "$out/tasks/T004/share/completions/_amonite" \
         "$out/share/zsh/site-functions/_amonite"
      cp "$out/tasks/T004/share/completions/amonite.fish" \
         "$out/share/fish/vendor_completions.d/amonite.fish"
    '';
    verify = {
      package-nix-present  = ''test -f "$out/tasks/T003/package.nix"'';
      completions-installed = ''
        test -f "$out/share/bash-completion/completions/amonite"
        test -f "$out/share/zsh/site-functions/_amonite"
        test -f "$out/share/fish/vendor_completions.d/amonite.fish"
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

in
{
  C001 = cliHardening;
  C002 = distribution;
  C003 = docsSite;
  C004 = releasePipeline;
  C005 = tuiWaves;
  C006 = researchVerify;

  APP = amonite.mkApplication {
    id = "APP";
    title = "amonite v0.2";
    tasks = [ cliHardening distribution docsSite releasePipeline tuiWaves researchVerify ];
    env = [ pkgs.bash pkgs.coreutils ];
    # Assemble a complete FHS-style installation from verified cluster outputs.
    # $out/bin + $out/share mirror a standard layout: AMONITE_SHARE="$out/share/amonite"
    # $out/bin/amonite runs immediately. Completions land in shell-specific share paths.
    build = ''
      mkdir -p "$out/bin" "$out/share/amonite" \
               "$out/share/bash-completion/completions" \
               "$out/share/zsh/site-functions" \
               "$out/share/fish/vendor_completions.d"
      cp "$out/tasks/C001/bin/amonite"         "$out/bin/amonite"
      chmod +x "$out/bin/amonite"
      cp -r "$out/tasks/C001/share/amonite/."  "$out/share/amonite/"
      cp "$out/tasks/C002/share/bash-completion/completions/amonite" \
         "$out/share/bash-completion/completions/amonite"
      cp "$out/tasks/C002/share/zsh/site-functions/_amonite" \
         "$out/share/zsh/site-functions/_amonite"
      cp "$out/tasks/C002/share/fish/vendor_completions.d/amonite.fish" \
         "$out/share/fish/vendor_completions.d/amonite.fish"
    '';
    verify = {
      help-complete = ''
        msg=$(AMONITE_SHARE="$out/share/amonite" \
              bash "$out/bin/amonite" --help 2>&1 || true)
        echo "$msg" | grep -q 'init'
        echo "$msg" | grep -q 'waves'
        echo "$msg" | grep -q 'status'
      '';
      completions-installed = ''
        test -f "$out/share/bash-completion/completions/amonite"
        test -f "$out/share/zsh/site-functions/_amonite"
        test -f "$out/share/fish/vendor_completions.d/amonite.fish"
      '';
      research-lib-present = ''
        grep -q "mkResearchTask" "$out/share/amonite/nix/lib.nix"
      '';
    };
  };
}
