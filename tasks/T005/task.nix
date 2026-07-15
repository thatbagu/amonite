{ pkgs, amonite }:

amonite.mkTask {
  id = "T005";
  title = "Parallel-agent wave planner";
  depends = [ "T001" "T002" ];

  src = ../..;

  env = with pkgs; [ bash git shellcheck jq coreutils ];

  build = ''
    mkdir -p "$out/bin" "$out/templates" "$out/commands"
    cp "$src/bin/amonite" "$out/bin/amonite"
    cp -r "$src/templates/." "$out/templates/"
    cp -r "$src/commands/." "$out/commands/"
    cp -r "$src/nix" "$out/nix"
    chmod +x "$out/bin/amonite"
  '';

  verify = {
    shellcheck-clean = ''
      shellcheck --shell=bash "$out/bin/amonite"
    '';

    waves-no-graph-exits-1 = ''
      tmp=$(mktemp -d)
      cd "$tmp"
      AMONITE_SHARE="$out" bash "$out/bin/amonite" waves && exit 1 || true
    '';

    waves-no-graph-stderr = ''
      tmp=$(mktemp -d)
      cd "$tmp"
      msg=$(AMONITE_SHARE="$out" bash "$out/bin/amonite" waves 2>&1 || true)
      echo "$msg" | grep -q 'task-graph.json'
    '';

    waves-reads-graph = ''
      tmp=$(mktemp -d)
      cd "$tmp"
      mkdir -p .amonite
      printf '{"waves":[{"wave":1,"tasks":[{"id":"T001","title":"test task","cluster":"C001","depends":[]}]}]}' \
        > .amonite/task-graph.json
      result=$(AMONITE_SHARE="$out" bash "$out/bin/amonite" waves 2>&1 || true)
      echo "$result" | grep -q 'Wave'
    '';

    lib-depends-field = ''
      # mkTask must accept a `depends` argument and store it in passthru.
      grep -q ', depends ? \[ \]' "$out/nix/lib.nix"
      grep -q 'inherit id title depends' "$out/nix/lib.nix"
    '';
  };
}
