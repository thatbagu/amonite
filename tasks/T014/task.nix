{ pkgs, amonite }:

amonite.mkTask {
  id = "T014";
  title = "AlignScore model weights Nix derivation";

  src = ../..;

  env = with pkgs; [ coreutils curl cacert ];

  build = ''echo "T014 not yet implemented" >&2 && exit 1'';

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
