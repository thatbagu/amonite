#!/usr/bin/env python3
import argparse, sys
from pathlib import Path
from sklearn.feature_extraction.text import TfidfVectorizer
from sklearn.metrics.pairwise import cosine_similarity

def main():
    p = argparse.ArgumentParser()
    p.add_argument("--report", required=True)
    p.add_argument("--sources", required=True)
    p.add_argument("--threshold", type=float, default=0.10)
    args = p.parse_args()

    report = Path(args.report).read_text()
    sources_dir = Path(args.sources)
    sources = []
    for f in sources_dir.iterdir():
        if f.suffix in (".txt", ".md"):
            sources.append(f.read_text())

    if not sources:
        print("ERROR: no source files found", file=sys.stderr)
        sys.exit(1)

    docs = [report] + sources
    vecs = TfidfVectorizer().fit_transform(docs)
    sims = cosine_similarity(vecs[0:1], vecs[1:]).flatten()
    max_sim = float(sims.max())
    print(f"max TF-IDF cosine similarity: {max_sim:.4f} (threshold: {args.threshold})")

    if max_sim < args.threshold:
        print("FAIL: report not sufficiently grounded in sources", file=sys.stderr)
        sys.exit(1)
    print("PASS")

if __name__ == "__main__":
    main()
