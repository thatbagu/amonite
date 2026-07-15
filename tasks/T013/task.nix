{ pkgs, amonite }:

amonite.mkTask {
  id = "T013";
  title = "TF-IDF faithfulness verify script";

  src = ../..;

  env = with pkgs; [
    coreutils
    (python3.withPackages (ps: [ ps.scikit-learn ]))
  ];

  build = ''echo "T013 not yet implemented" >&2 && exit 1'';

  verify = {
    # Script is installed and syntactically valid
    script-exists = ''
      test -f "$out/nix/research/verify_tfidf.py"
    '';

    script-syntax = ''
      python3 -m py_compile "$out/nix/research/verify_tfidf.py"
    '';

    # Fast gate: report with zero lexical overlap fails (cosine < 0.10)
    rejects-detached-report = ''
      tmp=$(mktemp -d)
      mkdir -p "$tmp/sources"
      echo "The mitochondria is the powerhouse of the cell." > "$tmp/sources/source.txt"
      echo "Quantum entanglement enables faster-than-light communication." > "$tmp/report.md"
      python3 "$out/nix/research/verify_tfidf.py" \
        --report "$tmp/report.md" \
        --sources "$tmp/sources" \
        --threshold 0.10 \
        && exit 1 || true
    '';

    # Grounded report (verbatim copy of source) passes
    accepts-grounded-report = ''
      tmp=$(mktemp -d)
      mkdir -p "$tmp/sources"
      echo "The mitochondria is the powerhouse of the cell." > "$tmp/sources/source.txt"
      echo "The mitochondria is the powerhouse of the cell." > "$tmp/report.md"
      python3 "$out/nix/research/verify_tfidf.py" \
        --report "$tmp/report.md" \
        --sources "$tmp/sources" \
        --threshold 0.10
    '';

    # Exits 0 fast (under 5 seconds for small inputs)
    runs-fast = ''
      tmp=$(mktemp -d)
      mkdir -p "$tmp/sources"
      echo "amonite is a spec-driven development framework." > "$tmp/sources/s.txt"
      echo "amonite compiles specs to Nix derivations." > "$tmp/report.md"
      timeout 5 python3 "$out/nix/research/verify_tfidf.py" \
        --report "$tmp/report.md" --sources "$tmp/sources" --threshold 0.05
    '';
  };
}
