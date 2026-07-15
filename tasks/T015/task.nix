{ pkgs, amonite }:

let
  # Python environment with scikit-learn for the fixture derivations.
  # This is baked into the fixture flake as a store path at Nix eval time.
  python3Env = pkgs.python3.withPackages (ps: [ ps.scikit-learn ]);
in

amonite.mkTask {
  id = "T015";
  title = "NLI faithfulness verify integration and fixtures";
  depends = [ "T012" "T013" "T014" ];

  src = ../..;

  env = with pkgs; [
    coreutils
    nix
    git
    python3Env
    (python3.withPackages (ps: [
      ps.torch
      ps.transformers
    ]))
  ];

  build = ''
    mkdir -p "$out/nix/research" "$out/nix/pkgs"
    cp "$src/nix/research/verify_tfidf.py" "$out/nix/research/verify_tfidf.py"
    cp "$src/nix/research/verify_nli.py"   "$out/nix/research/verify_nli.py"
    cp "$src/nix/pkgs/alignscore.nix"      "$out/nix/pkgs/alignscore.nix"
    cp "$src/nix/lib.nix"                  "$out/nix/lib.nix"

    # Generate a self-contained fixture flake that uses builtins.derivation
    # (no nixpkgs input needed) with store paths baked in at Nix eval time.
    python3 "$src/tasks/T015/write-fixture-flake.py" \
      "${python3Env}" \
      "${pkgs.coreutils}"

    # Set up writable dirs for the Nix client running in the sandbox.
    # Do NOT override NIX_STATE_DIR: the Nix client needs the real state dir
    # to find nix-daemon.socket and query the store database. Overriding it
    # with a new empty dir causes builtins.storePath to fail (empty database).
    _nix_tmp=$(mktemp -d)
    export HOME="$_nix_tmp/home"
    export XDG_CACHE_HOME="$_nix_tmp/cache"
    export NIX_LOG_DIR="$_nix_tmp/nix-log"
    export NIX_CONF_DIR="$_nix_tmp/nix-conf"
    mkdir -p "$HOME" "$XDG_CACHE_HOME/nix" "$NIX_LOG_DIR" "$NIX_CONF_DIR"
    printf '%s\n' "experimental-features = nix-command flakes" > "$NIX_CONF_DIR/nix.conf"

    # Create a nix wrapper that automatically adds --impure so fixture flakes
    # can reference store paths by builtins.storePath without a nixpkgs input.
    # The verify steps call `nix build` which will resolve to this wrapper.
    _nix_real=$(command -v nix)
    mkdir -p "$_nix_tmp/bin"
    printf '#!/bin/sh\nexec %s --option pure-eval false "$@"\n' "$_nix_real" \
      > "$_nix_tmp/bin/nix"
    chmod +x "$_nix_tmp/bin/nix"
    export PATH="$_nix_tmp/bin:$PATH"
  '';

  verify = {
    # NLI verify script exists and is syntactically valid
    nli-script-exists = ''
      test -f "$out/nix/research/verify_nli.py"
    '';

    nli-script-syntax = ''
      python3 -m py_compile "$out/nix/research/verify_nli.py"
    '';

    # Good fixture: grounded report passes TF-IDF gate (cosine ≥ 0.10)
    good-fixture-passes = ''
      nix build "$out#research-fixture" --no-link 2>&1 && echo PASS || { echo FAIL; exit 1; }
    '';

    # Bad fixture: fabricated claim fails TF-IDF gate (cosine < 0.10)
    bad-fixture-fails = ''
      nix build "$out#research-fixture-bad" --no-link 2>&1 \
        && { echo "FAIL: bad fixture should have failed"; exit 1; } \
        || echo "PASS: bad fixture correctly rejected"
    '';

    # Threshold config: tfidfThreshold present in the fixture flake
    threshold-config-accepted = ''
      grep -q "tfidfThreshold" "$out/flake.nix" || \
      grep -rq "tfidfThreshold" "$out/nix/"
    '';

    # Determinism: building good fixture twice gives same store path
    deterministic = ''
      path1=$(nix build "$out#research-fixture" --no-link --print-out-paths 2>/dev/null)
      path2=$(nix build "$out#research-fixture" --no-link --print-out-paths 2>/dev/null)
      [ "$path1" = "$path2" ] || { echo "non-deterministic: $path1 vs $path2"; exit 1; }
    '';
  };
}
