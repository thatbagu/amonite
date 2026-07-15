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
  id = "R003";
  title = "amonite repository self-audit — spec compliance, verify quality, principle adherence";

  src = ../..;

  env = [ pkgs.coreutils python3Env ];

  tfidfThreshold = 0.06;
  nliThreshold   = 0.35;

  build = ''
    mkdir -p "$out/sources" "$out/nix/research"

    # Gather sources from the live repo
    cp "$src/.amonite/spec.md"       "$out/sources/spec.txt"
    cp "$src/.amonite/principles.md" "$out/sources/principles.txt"
    cp "$src/.amonite/tasks.md"      "$out/sources/tasks.txt"
    cp "$src/nix/lib.nix"            "$out/sources/lib-nix.txt"
    cp "$src/commands/amonite.implement.md" "$out/sources/implement-cmd.txt"

    # Extract verify blocks from all task.nix files as a source
    {
      for f in "$src"/tasks/T*/task.nix; do
        id=$(basename "$(dirname "$f")")
        echo "=== $id ==="
        grep -A30 'verify\s*=' "$f" | head -30 || true
        echo ""
      done
    } > "$out/sources/verify-criteria.txt"

    cp "$src/research/R003/report.md" "$out/report.md"
    cp "$src/nix/research/verify_tfidf.py" "$out/nix/research/verify_tfidf.py"
    cp "$src/nix/research/verify_nli.py"   "$out/nix/research/verify_nli.py"

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
