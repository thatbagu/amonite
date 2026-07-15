{ pkgs, amonite }:

amonite.mkTask {
  id = "T008";
  title = "PR CI gate workflow (nix flake check, matrix, Cachix)";

  src = ../..;

  env = with pkgs; [ bash coreutils ];

  build = ''
    mkdir -p "$out/.github/workflows"
    cp "$src/.github/workflows/ci.yml" "$out/.github/workflows/ci.yml"
  '';

  verify = {
    workflow-exists = ''test -f "$out/.github/workflows/ci.yml"'';

    has-matrix-macos = ''
      grep -q "macos-latest" "$out/.github/workflows/ci.yml"
    '';

    has-cachix = ''
      grep -q "cachix" "$out/.github/workflows/ci.yml"
    '';

    has-nix-flake-check = ''
      grep -q "nix flake check" "$out/.github/workflows/ci.yml"
    '';

    targets-main = ''
      grep -q "main" "$out/.github/workflows/ci.yml"
    '';
  };
}
