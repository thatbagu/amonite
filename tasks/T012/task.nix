# Task definition — the single source of truth for this task.
# Referenced by BOTH this capsule's flake (for encapsulated dev/verify)
# and the project flake (for aggregate verification and clustering).
{ pkgs, amonite }:

amonite.mkTask {
  id = "T012"; # amonite task id, matches tasks.md
  title = "mkResearchTask lib function";

  # Source this task builds from. Usually the project root filtered to
  # what the task may see — keep the aperture as narrow as possible.
  # src = ../..;

  # Encapsulation boundary: everything this task's build and dev shell
  # may use. Nothing else is available.
  env = with pkgs; [
    coreutils
  ];

  # Build: produce the task's artifacts under $out.
  build = ''
    echo "REPLACE with build steps" && exit 1
  '';

  # Acceptance criteria from tasks.md, made mechanical. Every entry must
  # exit 0 or the task does not exist as a derivation.
  verify = {
    # unit-tests = ''pytest tests/'';
    # artifact = ''test -s "$out/thing"'';
  };
}
