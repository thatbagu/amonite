#!/usr/bin/env python3
"""
NLI faithfulness verification using AlignScore.

Requires --weights-dir pointing to the nix build .#alignscore-weights output,
which must contain:
  checkpoints/AlignScore-base.ckpt
  roberta-base/   (config.json, tokenizer.json, vocab.json, merges.txt,
                   tokenizer_config.json, pytorch_model.bin)

Exit codes:
  0 — pass (mean entailment >= threshold)
  1 — fail (mean entailment < threshold)
  2 — weights or deps missing
"""
import argparse
import os
import sys
from pathlib import Path


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument("--report",      required=True)
    parser.add_argument("--sources",     required=True)
    parser.add_argument("--threshold",   type=float, default=0.35)
    parser.add_argument("--weights-dir", required=True,
                        help="$out from nix build .#alignscore-weights")
    args = parser.parse_args()

    weights_dir = Path(args.weights_dir)
    ckpt_path   = weights_dir / "checkpoints" / "AlignScore-base.ckpt"
    roberta_dir = weights_dir / "roberta-base"

    if not ckpt_path.exists():
        print(f"ERROR: checkpoint not found: {ckpt_path}", file=sys.stderr)
        print("       Run: nix build .#alignscore-weights", file=sys.stderr)
        sys.exit(2)
    if not roberta_dir.exists():
        print(f"ERROR: roberta-base not found: {roberta_dir}", file=sys.stderr)
        sys.exit(2)

    # Disable all network access — everything must be in the Nix store already
    os.environ["TRANSFORMERS_OFFLINE"] = "1"
    os.environ["HF_DATASETS_OFFLINE"]  = "1"

    try:
        from alignscore import AlignScore
    except ImportError:
        print("ERROR: alignscore not installed — add python-alignscore to task env",
              file=sys.stderr)
        sys.exit(2)

    report_text  = Path(args.report).read_text()
    sources_dir  = Path(args.sources)
    source_texts = [
        f.read_text()
        for f in sorted(sources_dir.iterdir())
        if f.suffix in (".txt", ".md")
    ]
    if not source_texts:
        print(f"ERROR: no .txt/.md files in {args.sources}", file=sys.stderr)
        sys.exit(1)
    source_combined = " ".join(source_texts)

    sentences = [s.strip() for s in report_text.split(". ") if s.strip()]
    if not sentences:
        print("ERROR: no sentences in report", file=sys.stderr)
        sys.exit(1)

    print(f"Loading AlignScore — checkpoint: {ckpt_path.name}, base: {roberta_dir}")
    scorer = AlignScore(
        model=str(roberta_dir),   # local path, no HuggingFace download
        batch_size=8,
        device="cpu",
        ckpt_path=str(ckpt_path),
        evaluation_mode="nli_sp",
    )

    contexts = [source_combined] * len(sentences)
    scores   = scorer.score(contexts=contexts, claims=sentences)

    mean_score = sum(scores) / len(scores)
    print(f"\nNLI entailment ({len(sentences)} sentences):")
    for sent, score in zip(sentences, scores):
        flag = "✓" if score >= args.threshold else "✗"
        print(f"  {flag} [{score:.3f}] {sent[:90]}")
    print(f"\nMean: {mean_score:.4f}  Threshold: {args.threshold}")

    if mean_score < args.threshold:
        print("FAIL: report not sufficiently entailed by sources", file=sys.stderr)
        sys.exit(1)
    print("PASS")


if __name__ == "__main__":
    main()
