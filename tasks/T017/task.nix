{ pkgs, amonite }:

amonite.mkTask {
  id = "T017";
  title = "Architecture cleanup verification";

  src = ../..;

  env = with pkgs; [ coreutils nix ];

  build = ''
    cp -r . "$out"
    chmod -R u+w "$out"
    find "$out" -xtype l -delete
    echo -n "${pkgs.path}" > "$out/.nixpkgs-path"
  '';

  verify = {
    # integrate was renamed to build in mkCluster — no dead param in public API
    integrate-param-gone = ''
      grep -n "integrate" "$out/nix/lib.nix" | grep -v "^Binary\|#" \
        | grep -q "integrate" \
        && { echo "integrate still appears as a param name in lib.nix"; exit 1; } \
        || echo "PASS: integrate param removed"
    '';

    # Fixture clusters must NOT be in clusters.nix (they live in flake.nix checks)
    no-fixture-clusters-in-packages = ''
      grep -q 'id = "C008"' "$out/clusters.nix" \
        && { echo "C008 fixture leaked into clusters.nix (should be in checks only)"; exit 1; } \
        || true
      grep -q 'id = "C009"' "$out/clusters.nix" \
        && { echo "C009 fixture leaked into clusters.nix (should be in checks only)"; exit 1; } \
        || true
      echo "PASS: no fixture clusters in clusters.nix"
    '';

    # Three-level hierarchy fixture must be in flake.nix checks
    hierarchy-fixture-in-checks = ''
      grep -q "lib-nested-cluster" "$out/flake.nix" \
        || { echo "lib-nested-cluster check not found in flake.nix"; exit 1; }
    '';

    # VM verify check must be Linux-gated (isLinux guard) — not on darwin
    vm-verify-linux-gated = ''
      grep -q "lib-vm-verify" "$out/flake.nix" \
        || { echo "lib-vm-verify check not found in flake.nix"; exit 1; }
      grep -q "isLinux" "$out/flake.nix" \
        || { echo "isLinux guard not found in flake.nix"; exit 1; }
    '';

    # BEHAVIORAL: mkGraph still recurses correctly after all refactoring
    recursive-graph-still-works = ''
      export HOME; HOME=$(mktemp -d)
      export NIX_CONF_DIR="$HOME/nix-conf"
      mkdir -p "$NIX_CONF_DIR"
      printf 'experimental-features = nix-command\n' > "$NIX_CONF_DIR/nix.conf"
      _nixpkgs=$(cat "$out/.nixpkgs-path")
      found=$(nix eval --impure --json --expr "
        let
          pkgs = import \"$_nixpkgs\" {};
          lib  = import \"$out/nix/lib.nix\" { inherit pkgs; };
          leaf  = lib.mkTask { id = \"T_l\"; title = \"l\"; build = \"mkdir -p \\\"\$out\\\"\"; };
          inner = lib.mkCluster { id = \"C_i\"; title = \"i\"; tasks = [ leaf ]; };
          outer = lib.mkCluster { id = \"C_o\"; title = \"o\"; tasks = [ inner ]; };
          g = lib.mkGraph { tasks = {}; clusters = { C_o = outer; }; };
        in map (n: n.id) g.nodes
      " 2>/dev/null)
      echo "$found" | grep -q '"C_i"' \
        || { echo "sub-cluster not found in recursive graph after refactor: $found"; exit 1; }
    '';
  };
}
