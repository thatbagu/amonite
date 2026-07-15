{ pkgs, amonite }:

amonite.mkTask {
  id = "T006";
  title = "mdBook docs content";

  src = ../..;

  env = with pkgs; [ mdbook bash coreutils ];

  build = ''
    mkdir -p "$out/docs"
    cp -r "$src/docs/." "$out/docs/"
    cp "$src/README.md" "$out/README.md"
  '';

  verify = {
    book-toml-exists = ''test -f "$out/docs/book.toml"'';

    all-pages-exist = ''
      test -f "$out/docs/SUMMARY.md"
      test -f "$out/docs/getting-started.md"
      test -f "$out/docs/architecture.md"
      test -f "$out/docs/contributing.md"
      test -f "$out/docs/cli-reference.md"
    '';

    mdbook-builds = ''
      cd "$out"
      mdbook build docs
    '';

    cli-reference-has-content = ''
      grep -q "amonite" "$out/docs/cli-reference.md"
    '';

    readme-links-pages = ''
      grep -q "github.io" "$out/README.md"
    '';
  };
}
