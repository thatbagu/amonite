{ lib
, stdenvNoCC
, bash
, git
, jq
, buildGoModule
, makeWrapper
}:

let
  version = "0.2.0";

  tui = buildGoModule {
    pname = "amonite-tui";
    inherit version;
    src = ./tui;
    # Dependencies are vendored in tui/vendor/; no hash needed.
    vendorHash = null;
    postInstall = ''mv "$out/bin/tui" "$out/bin/amonite-tui"'';
  };
in
stdenvNoCC.mkDerivation {
  pname = "amonite";
  inherit version;

  src = lib.cleanSource ./.;

  nativeBuildInputs = [ makeWrapper ];

  dontBuild = true;

  installPhase = ''
    runHook preInstall

    # Share layer: templates, commands, nix fragments the CLI reads at runtime
    mkdir -p "$out/share/amonite"
    cp -r bin templates commands nix "$out/share/amonite/"

    # Shell completions
    install -Dm644 share/completions/amonite.bash \
      "$out/share/bash-completion/completions/amonite"
    install -Dm644 share/completions/_amonite \
      "$out/share/zsh/site-functions/_amonite"
    install -Dm644 share/completions/amonite.fish \
      "$out/share/fish/vendor_completions.d/amonite.fish"

    # Wrapper: set AMONITE_SHARE and put runtime deps on PATH
    makeWrapper ${bash}/bin/bash "$out/bin/amonite" \
      --add-flags "-euo pipefail $out/share/amonite/bin/amonite" \
      --set AMONITE_SHARE "$out/share/amonite" \
      --prefix PATH : "${lib.makeBinPath [ git jq tui ]}"

    runHook postInstall
  '';

  passthru = { inherit tui; };

  meta = {
    description = "Spec-driven development that compiles to Nix derivations";
    homepage = "https://github.com/thatbagu/amonite";
    license = lib.licenses.mit;
    maintainers = [ ];
    mainProgram = "amonite";
    platforms = lib.platforms.unix;
  };
}
