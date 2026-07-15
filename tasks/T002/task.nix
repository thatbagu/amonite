{ pkgs, amonite }:

amonite.mkTask {
  id = "T002";
  title = "CLI UX guards and tty-aware status colour";

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

    verify-no-arg-exits-1 = ''
      tmp=$(mktemp -d)
      cd "$tmp"
      AMONITE_SHARE="$out" bash "$out/bin/amonite" verify && exit 1 || true
    '';

    verify-no-arg-stderr = ''
      tmp=$(mktemp -d)
      cd "$tmp"
      msg=$(AMONITE_SHARE="$out" bash "$out/bin/amonite" verify 2>&1 || true)
      echo "$msg" | grep -qi 'usage'
    '';

    bad-id-hint = ''
      tmp=$(mktemp -d)
      cd "$tmp"
      export HOME="$tmp"
      git init -q
      git config user.email "test@amonite"
      git config user.name "amonite"
      msg=$(AMONITE_SHARE="$out" bash "$out/bin/amonite" task new not-valid-id "some title" 2>&1 || true)
      echo "$msg" | grep -qE 'T\[0-9\]'
    '';

    status-runs = ''
      tmp=$(mktemp -d)
      cd "$tmp"
      export HOME="$tmp"
      git init -q
      git config user.email "test@amonite"
      git config user.name "amonite"
      AMONITE_SHARE="$out" bash "$out/bin/amonite" init --flow-only
      AMONITE_SHARE="$out" bash "$out/bin/amonite" status
    '';
  };
}
