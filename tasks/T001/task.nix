# Task definition — the single source of truth for this task.
# Referenced by BOTH this capsule's flake (for encapsulated dev/verify)
# and the project flake (for aggregate verification and clustering).
{ pkgs, amonite }:

amonite.mkTask {
  id = "T001";
  title = "CLI --flow-only flag and error hint";

  src = ../..;

  env = with pkgs; [ bash git shellcheck coreutils ];

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

    flow-only-creates-amonite-dir = ''
      tmp=$(mktemp -d)
      cd "$tmp"
      export HOME="$tmp"
      git init -q
      git config user.email "test@amonite"
      git config user.name "amonite"
      AMONITE_SHARE="$out" bash "$out/bin/amonite" init --flow-only
      test -d .amonite
    '';

    flow-only-skips-flake = ''
      tmp=$(mktemp -d)
      cd "$tmp"
      export HOME="$tmp"
      git init -q
      git config user.email "test@amonite"
      git config user.name "amonite"
      printf '{ outputs = _: {}; }' > flake.nix
      git add flake.nix
      AMONITE_SHARE="$out" bash "$out/bin/amonite" init --flow-only
      grep -q 'outputs' flake.nix
    '';

    flow-only-idempotent = ''
      tmp=$(mktemp -d)
      cd "$tmp"
      export HOME="$tmp"
      git init -q
      git config user.email "test@amonite"
      git config user.name "amonite"
      AMONITE_SHARE="$out" bash "$out/bin/amonite" init --flow-only
      AMONITE_SHARE="$out" bash "$out/bin/amonite" init --flow-only
    '';

    existing-flake-hint = ''
      tmp=$(mktemp -d)
      cd "$tmp"
      export HOME="$tmp"
      git init -q
      git config user.email "test@amonite"
      git config user.name "amonite"
      printf '{ outputs = _: {}; }' > flake.nix
      git add flake.nix
      msg=$(AMONITE_SHARE="$out" bash "$out/bin/amonite" init 2>&1 || true)
      echo "$msg" | grep -q -- '--flow-only'
    '';
  };
}
