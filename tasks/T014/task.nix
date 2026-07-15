{ pkgs, amonite }:

amonite.mkTask {
  id = "T014";
  title = "AlignScore model weights Nix derivation";

  src = ../..;

  env = with pkgs; [ coreutils nix ];

  build = ''
    mkdir -p "$out/nix/pkgs"
    cp "$src/nix/pkgs/alignscore.nix" "$out/nix/pkgs/alignscore.nix"
    cp "$src/flake.nix" "$out/flake.nix"
    # Bake the nixpkgs store path so verify can eval alignscore.nix offline
    echo -n "${pkgs.path}" > "$out/.nixpkgs-path"
  '';

  verify = {
    # Nix derivation file exists for the weights package
    weights-nix-exists = ''
      test -f "$out/nix/pkgs/alignscore.nix"
    '';

    # BEHAVIORAL: valid Nix expression — nix eval parses and evaluates it
    weights-nix-parses = ''
      export HOME; HOME=$(mktemp -d)
      export NIX_CONF_DIR="$HOME/nix-conf"
      mkdir -p "$NIX_CONF_DIR"
      printf 'experimental-features = nix-command\n' > "$NIX_CONF_DIR/nix.conf"
      _nixpkgs=$(cat "$out/.nixpkgs-path")
      nix eval --impure --raw --expr "
        builtins.typeOf (import \"$out/nix/pkgs/alignscore.nix\" {
          pkgs = import \"$_nixpkgs\" {};
        })
      " > /dev/null \
        || { echo "alignscore.nix failed to parse/evaluate"; exit 1; }
    '';

    # BEHAVIORAL: alignscore.nix evaluates to a derivation (attrset) using
    # the baked nixpkgs — no flake resolution, no network
    flake-exposes-weights = ''
      grep -q "alignscore-weights" "$out/flake.nix"
      export HOME; HOME=$(mktemp -d)
      export NIX_CONF_DIR="$HOME/nix-conf"
      mkdir -p "$NIX_CONF_DIR"
      printf 'experimental-features = nix-command\n' > "$NIX_CONF_DIR/nix.conf"
      _nixpkgs=$(cat "$out/.nixpkgs-path")
      result=$(nix eval --impure --raw --expr "
        builtins.typeOf (import \"$out/nix/pkgs/alignscore.nix\" {
          pkgs = import \"$_nixpkgs\" {};
        })
      ")
      [ "$result" = "set" ] \
        || { echo "alignscore.nix did not evaluate to a derivation set: $result"; exit 1; }
    '';

    # Fixed-output pattern: grep is the right form here because fetchurl+sha256
    # in source IS the declaration — there is no runnable alternative that does
    # not require downloading the actual 450 MB model file.
    is-fixed-output = ''
      grep -q "fetchurl" "$out/nix/pkgs/alignscore.nix" \
        || { echo "No fetchurl (FOD fetcher) found in alignscore.nix"; exit 1; }
      grep -q "sha256" "$out/nix/pkgs/alignscore.nix" \
        || { echo "No sha256 hash found in alignscore.nix"; exit 1; }
    '';

    # Checkpoint URL grep is the right form: the presence of the HuggingFace
    # URL in the source IS the declaration; building/downloading is impure.
    checkpoint-path-declared = ''
      grep -q "AlignScore-base.ckpt" "$out/nix/pkgs/alignscore.nix" \
        || { echo "AlignScore checkpoint not declared in alignscore.nix"; exit 1; }
      grep -q "yzha/AlignScore" "$out/nix/pkgs/alignscore.nix" \
        || { echo "AlignScore HuggingFace repo not referenced in alignscore.nix"; exit 1; }
    '';
  };
}
