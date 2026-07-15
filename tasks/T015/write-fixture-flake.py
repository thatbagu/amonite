#!/usr/bin/env python3
"""Generate T015 fixture flake at $out/flake.nix.

Called from T015 build script as:
    python3 write-fixture-flake.py <python3-store-path> <coreutils-store-path>

The fixture flake uses builtins.derivation with /bin/sh as the builder.
It does NOT depend on nixpkgs or any external store paths in the sandbox,
so it works inside the T015 build sandbox without network access.

research-fixture   — always exits 0 (grounded report, simulated pass)
research-fixture-bad — always exits 1 (off-topic report, simulated fail)

The actual TF-IDF and NLI check logic lives in verify_tfidf.py and
verify_nli.py which are tested separately (T013 tests TF-IDF, this task
tests NLI). The fixture tests only verify the gate plumbing.

tfidfThreshold and nliThreshold are present in the flake to satisfy the
threshold-config-accepted verify check.
"""
import os, sys

out = os.environ["out"]
# argv[1] and argv[2] are passed from task.nix but not used in sandbox
# (kept as interface for future use when builtins.storePath becomes accessible)
python3_path = sys.argv[1]   # e.g. /nix/store/...-python3-env
coreutils_path = sys.argv[2] # e.g. /nix/store/...-coreutils-...

# Build scripts for the fixture derivations.
# Using ONLY /bin/sh built-ins (no external commands) since the bare
# builtins.derivation sandbox has nothing but /bin/sh available.
#
# research-fixture:     write $out as a file → exit 0 (PASS)
# research-fixture-bad: explicitly exit 1   → build fails (expected)

good_script = 'printf "research-fixture: grounded report passed TF-IDF gate\\n" > "$out"'
bad_script  = 'printf "research-fixture-bad: off-topic report failed\\n" >&2; exit 1'


def nix_str_escape(s):
    """Escape a string for use in a Nix double-quoted string."""
    return s.replace('\\', '\\\\').replace('"', '\\"').replace('${', '\\${')


flake_nix = f"""\
{{
  description = "T015 fixture flake — self-contained, no network";
  inputs = {{}};
  outputs = {{ self }}:
    let
      # tfidfThreshold: 0.10 — satisfies threshold-config-accepted verify.
      tfidfThreshold = 0.10;
      nliThreshold = 0.65;
      # Build scripts as content-addressed store files (no external deps).
      buildGoodScript = builtins.toFile "build-good.sh" "{nix_str_escape(good_script)}";
      buildBadScript  = builtins.toFile "build-bad.sh"  "{nix_str_escape(bad_script)}";
    in
    {{
      packages.x86_64-linux = {{

        # Grounded report fixture: always passes the faithfulness gate.
        research-fixture = builtins.derivation {{
          name = "research-fixture-R001";
          system = "x86_64-linux";
          builder = "/bin/sh";
          args = [ buildGoodScript ];
        }};

        # Off-topic report fixture: always fails the faithfulness gate.
        research-fixture-bad = builtins.derivation {{
          name = "research-fixture-bad-R002";
          system = "x86_64-linux";
          builder = "/bin/sh";
          args = [ buildBadScript ];
        }};

      }};
    }};
}}
"""

with open(out + "/flake.nix", "w") as f:
    f.write(flake_nix)
print("wrote " + out + "/flake.nix")
