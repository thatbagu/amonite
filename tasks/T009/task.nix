{ pkgs, amonite }:

amonite.mkTask {
  id = "T009";
  title = "Release workflow + CHANGELOG + CONTRIBUTING";

  src = ../..;

  env = with pkgs; [ bash coreutils ];

  build = ''
    mkdir -p "$out/.github/workflows"
    cp "$src/.github/workflows/release.yml" "$out/.github/workflows/release.yml"
    cp "$src/CHANGELOG.md" "$out/CHANGELOG.md"
    cp "$src/CONTRIBUTING.md" "$out/CONTRIBUTING.md"
  '';

  verify = {
    release-workflow-exists = ''test -f "$out/.github/workflows/release.yml"'';

    tag-trigger = ''
      grep -q 'v\[0-9\]' "$out/.github/workflows/release.yml"
    '';

    creates-gh-release = ''
      grep -q "softprops/action-gh-release" "$out/.github/workflows/release.yml"
    '';

    changelog-exists = ''test -f "$out/CHANGELOG.md"'';

    changelog-has-unreleased = ''
      grep -q "Unreleased" "$out/CHANGELOG.md"
    '';

    contributing-exists = ''test -f "$out/CONTRIBUTING.md"'';

    contributing-has-conventional = ''
      grep -qi "conventional" "$out/CONTRIBUTING.md"
    '';
  };
}
