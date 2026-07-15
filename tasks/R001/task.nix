{ pkgs, amonite }:

let
  alignscoreWeights = pkgs.callPackage ../../nix/pkgs/alignscore.nix {};
  alignscorePy      = pkgs.callPackage ../../nix/pkgs/python-alignscore.nix {};
  python3Env = pkgs.python3.withPackages (ps: [
    ps.scikit-learn
    ps.torch
    ps.transformers
    alignscorePy
  ]);
in

amonite.mkResearchTask {
  id = "R001";
  title = "amonite vs spec-driven frameworks — functional comparison";

  src = ../..;

  env = [ pkgs.coreutils python3Env ];

  tfidfThreshold = 0.08;
  nliThreshold   = 0.60;

  build = ''
    mkdir -p "$out/sources" "$out/nix/research"
    cp -r "$src/research/R001/sources/." "$out/sources/"
    cp "$src/research/R001/report.md"          "$out/report.md"
    cp "$src/nix/research/verify_tfidf.py"     "$out/nix/research/verify_tfidf.py"
    cp "$src/nix/research/verify_nli.py"       "$out/nix/research/verify_nli.py"

    # Tier 1: TF-IDF lexical gate
    python3 "$out/nix/research/verify_tfidf.py" \
      --report "$out/report.md" \
      --sources "$out/sources" \
      --threshold 0.08

    # Tier 2: NLI entailment gate (AlignScore, offline)
    python3 "$out/nix/research/verify_nli.py" \
      --report "$out/report.md" \
      --sources "$out/sources" \
      --threshold 0.60 \
      --weights-dir "${alignscoreWeights}"
  '';
}
