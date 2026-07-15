{ pkgs, amonite }:

amonite.mkTask {
  id = "T016";
  title = "Recursive mkGraph in nix/lib.nix";

  src = ../..;

  env = with pkgs; [ coreutils nix ];

  build = ''
    cp -r . "$out"
    chmod -R u+w "$out"
    find "$out" -xtype l -delete
    echo -n "${pkgs.path}" > "$out/.nixpkgs-path"
  '';

  verify = {
    # BEHAVIORAL: mkGraph is a lambda (not a value) in the updated lib.nix
    mkgraph-is-fn = ''
      export HOME; HOME=$(mktemp -d)
      export NIX_CONF_DIR="$HOME/nix-conf"
      mkdir -p "$NIX_CONF_DIR"
      printf 'experimental-features = nix-command\n' > "$NIX_CONF_DIR/nix.conf"
      _nixpkgs=$(cat "$out/.nixpkgs-path")
      result=$(nix eval --impure --raw --expr "
        builtins.typeOf ((import \"$out/nix/lib.nix\" {
          pkgs = import \"$_nixpkgs\" {};
        }).mkGraph)
      ")
      [ "$result" = "lambda" ] || { echo "mkGraph is not a lambda: $result"; exit 1; }
    '';

    # BEHAVIORAL: a cluster nested inside another cluster appears as a node.
    # Build an inline two-level graph and confirm the sub-cluster is in nodes.
    recurses-into-members = ''
      export HOME; HOME=$(mktemp -d)
      export NIX_CONF_DIR="$HOME/nix-conf"
      mkdir -p "$NIX_CONF_DIR"
      printf 'experimental-features = nix-command\n' > "$NIX_CONF_DIR/nix.conf"
      _nixpkgs=$(cat "$out/.nixpkgs-path")
      found=$(nix eval --impure --json --expr "
        let
          pkgs = import \"$_nixpkgs\" {};
          lib  = import \"$out/nix/lib.nix\" { inherit pkgs; };
          leaf = lib.mkTask {
            id = \"T_leaf\"; title = \"leaf\";
            build = \"mkdir -p \\\"\$out\\\"\";
          };
          inner = lib.mkCluster {
            id = \"C_inner\"; title = \"inner\";
            tasks = [ leaf ];
          };
          outer = lib.mkCluster {
            id = \"C_outer\"; title = \"outer\";
            tasks = [ inner ];
          };
          g = lib.mkGraph { tasks = {}; clusters = { C_outer = outer; }; };
        in map (n: n.id) g.nodes
      " 2>/dev/null)
      echo "$found" | grep -q '"C_inner"' \
        || { echo "sub-cluster C_inner not found in recursive graph nodes: $found"; exit 1; }
    '';

    # BEHAVIORAL: a cluster referenced by two parents appears exactly once.
    dedup-stable = ''
      export HOME; HOME=$(mktemp -d)
      export NIX_CONF_DIR="$HOME/nix-conf"
      mkdir -p "$NIX_CONF_DIR"
      printf 'experimental-features = nix-command\n' > "$NIX_CONF_DIR/nix.conf"
      _nixpkgs=$(cat "$out/.nixpkgs-path")
      count=$(nix eval --impure --json --expr "
        let
          pkgs = import \"$_nixpkgs\" {};
          lib  = import \"$out/nix/lib.nix\" { inherit pkgs; };
          shared = lib.mkTask {
            id = \"T_shared\"; title = \"shared\";
            build = \"mkdir -p \\\"\$out\\\"\";
          };
          parentA = lib.mkCluster { id = \"C_A\"; title = \"A\"; tasks = [ shared ]; };
          parentB = lib.mkCluster { id = \"C_B\"; title = \"B\"; tasks = [ shared ]; };
          root    = lib.mkCluster { id = \"C_root\"; title = \"root\"; tasks = [ parentA parentB ]; };
          g       = lib.mkGraph { tasks = {}; clusters = { C_root = root; }; };
          sharedNodes = builtins.filter (n: n.id == \"T_shared\") g.nodes;
        in builtins.length sharedNodes
      " 2>/dev/null)
      [ "$count" = "1" ] \
        || { echo "shared task appears $count times in nodes (expected 1)"; exit 1; }
    '';

    # Structural: confirm the recursive implementation is in lib.nix
    collectall-present = ''
      grep -q "collectAll" "$out/nix/lib.nix" \
        || { echo "collectAll not found — mkGraph may not be recursive"; exit 1; }
    '';
  };
}
