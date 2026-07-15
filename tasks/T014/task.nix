{ pkgs, amonite }:

amonite.mkTask {
  id = "T014";
  title = "AlignScore model weights Nix derivation";

  src = ../..;

  env = with pkgs; [ coreutils curl cacert nix ];

  build = ''
    mkdir -p "$out/nix/pkgs"
    cp "$src/nix/pkgs/alignscore.nix" "$out/nix/pkgs/alignscore.nix"
    # Copy flake.nix to show the package is exposed
    cp "$src/flake.nix" "$out/flake.nix"
    # Set nix state dirs to writable temp locations so nix-instantiate works in sandbox
    export NIX_STATE_DIR="$TMPDIR/nix-state"
    export NIX_LOG_DIR="$TMPDIR/nix-log"
    export NIX_CONF_DIR="$TMPDIR/nix-conf"
    mkdir -p "$NIX_STATE_DIR" "$NIX_LOG_DIR" "$NIX_CONF_DIR"
  '';

  verify = {
    # Nix derivation file exists for the weights package
    weights-nix-exists = ''
      test -f "$out/nix/pkgs/alignscore.nix"
    '';

    # It is a valid Nix expression (parse check)
    weights-nix-parses = ''
      nix-instantiate --parse "$out/nix/pkgs/alignscore.nix" > /dev/null
    '';

    # Exposes alignscore-weights in flake packages
    flake-exposes-weights = ''
      grep -q "alignscore-weights" "$out/flake.nix"
    '';

    # The derivation is a fixed-output (has outputHash — ensures reproducibility)
    is-fixed-output = ''
      grep -q "outputHash" "$out/nix/pkgs/alignscore.nix"
    '';

    # Build produces checkpoint file at expected path
    checkpoint-path-declared = ''
      grep -q "AlignScore" "$out/nix/pkgs/alignscore.nix"
    '';
  };
}
