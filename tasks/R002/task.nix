{ pkgs, amonite }:

amonite.mkResearchTask {
  id = "R002";
  title = "scientific grounding — hermetic builds, reproducibility, spec-driven robustness";

  src = ../..;

  env = with pkgs; [
    coreutils
    (python3.withPackages (ps: [ ps.scikit-learn ]))
  ];

  tfidfThreshold = 0.06;
  nliThreshold = 0.60;

  build = ''
    mkdir -p "$out/sources" "$out/nix/research"
    cp -r "$src/research/R002/sources/." "$out/sources/"
    cp "$src/research/R002/report.md" "$out/report.md"
    cp "$src/nix/research/verify_tfidf.py" "$out/nix/research/verify_tfidf.py"
    python3 "$out/nix/research/verify_tfidf.py" \
      --report "$out/report.md" \
      --sources "$out/sources" \
      --threshold 0.06
  '';
}
