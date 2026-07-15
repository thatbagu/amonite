{ pkgs, amonite }:

amonite.mkTask {
  id = "T010";
  title = "release-please automated release pipeline";

  src = ../..;

  env = with pkgs; [ bash coreutils ];

  build = ''
    mkdir -p "$out/.github/workflows"
    cp "$src/.github/workflows/release-please.yml" "$out/.github/workflows/release-please.yml"
    cp "$src/release-please-config.json" "$out/release-please-config.json"
    cp "$src/.release-please-manifest.json" "$out/.release-please-manifest.json"
    cp "$src/CONTRIBUTING.md" "$out/CONTRIBUTING.md"
  '';

  verify = {
    release-please-workflow-exists = ''
      test -f "$out/.github/workflows/release-please.yml"
    '';

    has-release-please-action = ''
      grep -q "release-please-action" "$out/.github/workflows/release-please.yml"
    '';

    config-exists = ''test -f "$out/release-please-config.json"'';

    manifest-exists = ''test -f "$out/.release-please-manifest.json"'';

    contributing-mentions-release-please = ''
      grep -qi "release-please" "$out/CONTRIBUTING.md"
    '';
  };
}
