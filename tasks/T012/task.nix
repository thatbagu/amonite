{ pkgs, amonite }:

amonite.mkTask {
  id = "T012";
  title = "mkResearchTask lib function";

  src = ../..;

  env = with pkgs; [ nix git coreutils ];

  build = ''echo "T012 not yet implemented" >&2 && exit 1'';

  verify = {
    # lib.nix exports mkResearchTask
    lib-exports-fn = ''
      grep -q "mkResearchTask" "$out/nix/lib.nix"
    '';

    # It accepts tfidfThreshold and nliThreshold overrides (nix eval clean)
    fn-accepts-thresholds = ''
      grep -q "tfidfThreshold" "$out/nix/lib.nix"
      grep -q "nliThreshold" "$out/nix/lib.nix"
    '';

    # Dogfood: flake.nix checks block exercises mkResearchTask
    flake-dogfoods-fn = ''
      grep -q "mkResearchTask" "$out/flake.nix"
    '';

    # sources/ and report.md enforcement present in function body
    enforces-sources-dir = ''
      grep -q "sources" "$out/nix/lib.nix"
    '';

    enforces-report-md = ''
      grep -q "report.md" "$out/nix/lib.nix"
    '';
  };
}
