{ pkgs, amonite }:

amonite.mkTask {
  id = "T003";
  title = "nixpkgs-convention package.nix";

  src = ../..;

  env = with pkgs; [ bash coreutils ];

  build = ''
    mkdir -p "$out"
    cp "$src/package.nix" "$out/package.nix"
  '';

  verify = {
    file-exists = ''test -f "$out/package.nix"'';

    # nix-instantiate --parse requires the Nix daemon (banned in sandbox).
    # Structural greps are sufficient; flake check validates syntax at eval time.
    nix-structure = ''
      grep -q 'stdenvNoCC.mkDerivation' "$out/package.nix"
      grep -q 'installPhase' "$out/package.nix"
      grep -q 'fetchFromGitHub' "$out/package.nix"
    '';

    meta-description = ''grep -q 'description' "$out/package.nix"'';
    meta-license     = ''grep -q 'licenses\.mit' "$out/package.nix"'';
    meta-mainProgram = ''grep -q 'mainProgram.*amonite' "$out/package.nix"'';

    help-output = ''
      msg=$(AMONITE_SHARE="$src" bash "$src/bin/amonite" --help 2>&1 || true)
      echo "$msg" | grep -q 'init'
      echo "$msg" | grep -q 'verify'
      echo "$msg" | grep -q 'status'
    '';
  };
}
