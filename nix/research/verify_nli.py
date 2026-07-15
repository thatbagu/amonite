#!/usr/bin/env python3
"""NLI faithfulness verification script.

Checks that a research report is semantically entailed by its source documents
using a cross-encoder NLI model. Exits 0 if mean entailment score meets the
threshold, 1 if it does not, 2 if the model weights are not available.
"""
import argparse
import sys
from pathlib import Path


def main():
    p = argparse.ArgumentParser(
        description="Verify report faithfulness via NLI entailment scoring"
    )
    p.add_argument("--report", required=True, help="Path to the report file")
    p.add_argument("--sources", required=True, help="Directory of source documents")
    p.add_argument(
        "--threshold",
        type=float,
        default=0.65,
        help="Minimum mean entailment score (default: 0.65)",
    )
    p.add_argument(
        "--weights-dir",
        required=True,
        help="Directory containing the NLI model weights",
    )
    args = p.parse_args()

    weights_dir = Path(args.weights_dir)
    if not weights_dir.exists() or not any(weights_dir.iterdir()):
        print(
            "ERROR: weights-dir is empty — run: nix build .#alignscore-weights",
            file=sys.stderr,
        )
        sys.exit(2)

    try:
        from transformers import pipeline
    except ImportError:
        print("ERROR: transformers not installed", file=sys.stderr)
        sys.exit(1)

    report_path = Path(args.report)
    if not report_path.exists():
        print(f"ERROR: report file not found: {report_path}", file=sys.stderr)
        sys.exit(1)

    sources_dir = Path(args.sources)
    if not sources_dir.exists():
        print(f"ERROR: sources directory not found: {sources_dir}", file=sys.stderr)
        sys.exit(1)

    report = report_path.read_text().strip()
    if not report:
        print("ERROR: report is empty", file=sys.stderr)
        sys.exit(1)

    source_files = [
        f for f in sources_dir.iterdir() if f.suffix in (".txt", ".md") and f.is_file()
    ]
    source_text = " ".join(f.read_text() for f in source_files)

    sentences = [s.strip() for s in report.split(". ") if s.strip()]
    if not sentences:
        print("ERROR: no sentences in report", file=sys.stderr)
        sys.exit(1)

    nli = pipeline("text-classification", model=str(weights_dir), device=-1)
    scores = []
    for sent in sentences:
        result = nli(
            f"{source_text} [SEP] {sent}", truncation=True, max_length=512
        )
        # Extract entailment score; result may be a list of dicts
        if isinstance(result, list) and isinstance(result[0], dict):
            entailment = next(
                (r["score"] for r in result if "entail" in r["label"].lower()), 0.0
            )
        else:
            entailment = 0.0
        scores.append(entailment)

    mean_score = sum(scores) / len(scores)
    print(f"mean NLI entailment: {mean_score:.4f} (threshold: {args.threshold})")

    if mean_score < args.threshold:
        print(
            "FAIL: report not sufficiently entailed by sources", file=sys.stderr
        )
        sys.exit(1)

    print("PASS")


if __name__ == "__main__":
    main()
