{ pkgs, amonite }:

amonite.mkTask {
  id = "T015";
  title = "NLI faithfulness verify integration and fixtures";
  depends = [ "T012" "T013" "T014" ];

  src = ../..;

  env = with pkgs; [
    coreutils
    (python3.withPackages (ps: [
      ps.scikit-learn
      ps.torch
      ps.transformers
    ]))
  ];

  build = ''echo "T015 not yet implemented" >&2 && exit 1'';

  verify = {
    # NLI verify script exists and is syntactically valid
    nli-script-exists = ''
      test -f "$out/nix/research/verify_nli.py"
    '';

    nli-script-syntax = ''
      python3 -m py_compile "$out/nix/research/verify_nli.py"
    '';

    # Good fixture: grounded report passes NLI gate
    good-fixture-passes = ''
      nix build "$out#research-fixture" --no-link 2>&1 && echo PASS || { echo FAIL; exit 1; }
    '';

    # Bad fixture: fabricated claim fails NLI gate
    bad-fixture-fails = ''
      nix build "$out#research-fixture-bad" --no-link 2>&1 \
        && { echo "FAIL: bad fixture should have failed NLI gate"; exit 1; } \
        || echo "PASS: bad fixture correctly rejected"
    '';

    # Threshold config: mkResearchTask accepts custom thresholds
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
