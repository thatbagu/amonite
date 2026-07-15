{ pkgs, amonite }:

let
  alignscoreWeights = pkgs.callPackage ../../nix/pkgs/alignscore.nix {};
  python3Env = pkgs.python3.withPackages (ps: [
    ps.scikit-learn
    ps.torch
    ps.transformers
    (ps.callPackage ../../nix/pkgs/python-alignscore.nix {})
  ]);
in

amonite.mkResearchTask {
  id = "R002";
  title = "scientific grounding — hermetic builds, reproducibility, spec-driven robustness";

  src = ../..;

  env = [ pkgs.coreutils python3Env ];

  tfidfThreshold = 0.06;
  nliThreshold   = 0.35;

  build = ''
    mkdir -p "$out/sources" "$out/nix/research"
    cp -r "$src/research/R002/sources/." "$out/sources/"
    cp "$src/research/R002/report.md"          "$out/report.md"
    cp "$src/nix/research/verify_tfidf.py"     "$out/nix/research/verify_tfidf.py"
    cp "$src/nix/research/verify_nli.py"       "$out/nix/research/verify_nli.py"

    # Tier 1: TF-IDF lexical gate
    python3 "$out/nix/research/verify_tfidf.py" \
      --report "$out/report.md" \
      --sources "$out/sources" \
      --threshold 0.06

    # Tier 2: NLI entailment gate (AlignScore, offline)
    python3 "$out/nix/research/verify_nli.py" \
      --report "$out/report.md" \
      --sources "$out/sources" \
      --threshold 0.35 \
      --weights-dir "${alignscoreWeights}"
  '';
}
