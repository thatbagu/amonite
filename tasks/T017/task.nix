{ pkgs, amonite }:

amonite.mkTask {
  id = "T017";
  title = "Three-level cluster fixture";

  src = ../..;

  env = with pkgs; [ coreutils nix ];

  build = ''
    cp -r . "$out"
    chmod -R u+w "$out"
    find "$out" -xtype l -delete
    echo -n "${pkgs.path}" > "$out/.nixpkgs-path"
  '';

  verify = {
    # Structural: fixture clusters are declared in clusters.nix
    clusters-nix-has-c008 = ''
      grep -q 'id = "C008"' "$out/clusters.nix" \
        || { echo "C008 not declared in clusters.nix"; exit 1; }
    '';
    clusters-nix-has-c009 = ''
      grep -q 'id = "C009"' "$out/clusters.nix" \
        || { echo "C009 not declared in clusters.nix"; exit 1; }
    '';

    # BEHAVIORAL: import clusters.nix directly against baked nixpkgs and
    # confirm C008 / C009 evaluate to derivation sets (no flake network).
    c008-evaluates = ''
      export HOME; HOME=$(mktemp -d)
      export NIX_CONF_DIR="$HOME/nix-conf"
      mkdir -p "$NIX_CONF_DIR"
      printf 'experimental-features = nix-command\n' > "$NIX_CONF_DIR/nix.conf"
      _nixpkgs=$(cat "$out/.nixpkgs-path")
      result=$(nix eval --impure --raw --expr "
        let
          pkgs    = import \"$_nixpkgs\" {};
          amonite = import \"$out/nix/lib.nix\" { inherit pkgs; };
          tasks   = amonite.loadTasks { root = \"$out\"; amonite = amonite; };
          clusters = import \"$out/clusters.nix\" { inherit pkgs tasks amonite; };
        in builtins.typeOf clusters.C008
      ")
      [ "$result" = "set" ] \
        || { echo "C008 did not evaluate to a derivation set: $result"; exit 1; }
    '';

    c009-evaluates = ''
      export HOME; HOME=$(mktemp -d)
      export NIX_CONF_DIR="$HOME/nix-conf"
      mkdir -p "$NIX_CONF_DIR"
      printf 'experimental-features = nix-command\n' > "$NIX_CONF_DIR/nix.conf"
      _nixpkgs=$(cat "$out/.nixpkgs-path")
      result=$(nix eval --impure --raw --expr "
        let
          pkgs    = import \"$_nixpkgs\" {};
          amonite = import \"$out/nix/lib.nix\" { inherit pkgs; };
          tasks   = amonite.loadTasks { root = \"$out\"; amonite = amonite; };
          clusters = import \"$out/clusters.nix\" { inherit pkgs tasks amonite; };
        in builtins.typeOf clusters.C009
      ")
      [ "$result" = "set" ] \
        || { echo "C009 did not evaluate to a derivation set: $result"; exit 1; }
    '';

    # BEHAVIORAL: mkGraph with the fixture clusters emits both C008 and C009
    graph-has-c008 = ''
      export HOME; HOME=$(mktemp -d)
      export NIX_CONF_DIR="$HOME/nix-conf"
      mkdir -p "$NIX_CONF_DIR"
      printf 'experimental-features = nix-command\n' > "$NIX_CONF_DIR/nix.conf"
      _nixpkgs=$(cat "$out/.nixpkgs-path")
      ids=$(nix eval --impure --json --expr "
        let
          pkgs    = import \"$_nixpkgs\" {};
          amonite = import \"$out/nix/lib.nix\" { inherit pkgs; };
          tasks   = amonite.loadTasks { root = \"$out\"; amonite = amonite; };
          clusters = import \"$out/clusters.nix\" { inherit pkgs tasks amonite; };
          g = amonite.mkGraph { inherit tasks clusters; };
        in map (n: n.id) g.nodes
      " 2>/dev/null)
      echo "$ids" | grep -q '"C008"' \
        || { echo "C008 not found in graph nodes: $ids"; exit 1; }
    '';

    graph-has-c009 = ''
      export HOME; HOME=$(mktemp -d)
      export NIX_CONF_DIR="$HOME/nix-conf"
      mkdir -p "$NIX_CONF_DIR"
      printf 'experimental-features = nix-command\n' > "$NIX_CONF_DIR/nix.conf"
      _nixpkgs=$(cat "$out/.nixpkgs-path")
      ids=$(nix eval --impure --json --expr "
        let
          pkgs    = import \"$_nixpkgs\" {};
          amonite = import \"$out/nix/lib.nix\" { inherit pkgs; };
          tasks   = amonite.loadTasks { root = \"$out\"; amonite = amonite; };
          clusters = import \"$out/clusters.nix\" { inherit pkgs tasks amonite; };
          g = amonite.mkGraph { inherit tasks clusters; };
        in map (n: n.id) g.nodes
      " 2>/dev/null)
      echo "$ids" | grep -q '"C009"' \
        || { echo "C009 not found in graph nodes: $ids"; exit 1; }
    '';
  };
}
