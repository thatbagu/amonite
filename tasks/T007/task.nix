{ pkgs, amonite }:

amonite.mkTask {
  id = "T007";
  title = "GitHub Pages docs CI workflow";

  src = ../..;

  env = with pkgs; [ bash coreutils ];

  build = ''
    mkdir -p "$out/.github/workflows"
    cp "$src/.github/workflows/docs.yml" "$out/.github/workflows/docs.yml"
  '';

  verify = {
    workflow-exists = ''test -f "$out/.github/workflows/docs.yml"'';

    triggers-on-docs = ''
      grep -q "docs/" "$out/.github/workflows/docs.yml"
    '';

    has-deploy-pages = ''
      grep -q "deploy-pages" "$out/.github/workflows/docs.yml"
    '';

    has-pr-build-check = ''
      grep -q "pull_request" "$out/.github/workflows/docs.yml"
    '';
  };
}
