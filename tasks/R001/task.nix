{ pkgs, amonite }:

amonite.mkResearchTask {
  id = "R001";
  title = "amonite vs spec-driven frameworks — functional comparison";

  src = ../..;

  env = with pkgs; [
    coreutils
    (python3.withPackages (ps: [ ps.scikit-learn ]))
  ];

  tfidfThreshold = 0.08;
  nliThreshold = 0.60;

  build = ''
    mkdir -p "$out/sources" "$out/nix/research"
    cp -r "$src/research/R001/sources/." "$out/sources/"
    cp "$src/research/R001/report.md" "$out/report.md"
    cp "$src/nix/research/verify_tfidf.py" "$out/nix/research/verify_tfidf.py"
    python3 "$out/nix/research/verify_tfidf.py" \
      --report "$out/report.md" \
      --sources "$out/sources" \
      --threshold 0.08
  '';
}
