{ lib
, stdenvNoCC
, fetchFromGitHub
, buildGoModule
, makeWrapper
, bash
, git
, jq
# Overridable so the flake can pass the local store path during development.
, src ? fetchFromGitHub {
    owner = "thatbagu";
    repo = "amonite";
    rev = "v0.2.0";
    # Run `nix-prefetch-url --unpack <tarball-url>` after tagging to get this.
    hash = "sha256-AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA=";
  }
}:

let
  version = "0.2.0";

  tui = buildGoModule {
    pname = "amonite-tui";
    inherit version;
    # Vendor directory committed at tui/vendor/; no module hash needed.
    src = "${src}/tui";
    vendorHash = null;
    postInstall = ''mv "$out/bin/tui" "$out/bin/amonite-tui"'';
  };
in
stdenvNoCC.mkDerivation {
  pname = "amonite";
  inherit version src;

  nativeBuildInputs = [ makeWrapper ];

  dontBuild = true;

  installPhase = ''
    runHook preInstall

    # Share layer: templates, commands, nix fragments the CLI reads at runtime.
    mkdir -p "$out/share/amonite"
    cp -r bin templates commands nix "$out/share/amonite/"

    # Shell completions.
    install -Dm644 share/completions/amonite.bash \
      "$out/share/bash-completion/completions/amonite"
    install -Dm644 share/completions/_amonite \
      "$out/share/zsh/site-functions/_amonite"
    install -Dm644 share/completions/amonite.fish \
      "$out/share/fish/vendor_completions.d/amonite.fish"

    # Wrapper: bake AMONITE_SHARE and put runtime deps on PATH.
    makeWrapper ${bash}/bin/bash "$out/bin/amonite" \
      --add-flags "-euo pipefail $out/share/amonite/bin/amonite" \
      --set AMONITE_SHARE "$out/share/amonite" \
      --prefix PATH : "${lib.makeBinPath [ git jq tui ]}"

    runHook postInstall
  '';

  passthru = { inherit tui; };

  meta = with lib; {
    description = "Spec-driven development that compiles to Nix derivations";
    longDescription = ''
      amonite turns the spec→plan→tasks flow into a Nix derivation graph.
      Each task's acceptance criteria run hermetically inside its build;
      a task that exists in the Nix store has passed its checks. Clusters
      compose verified tasks; the final derivation is the working application.
    '';
    homepage = "https://github.com/thatbagu/amonite";
    license = licenses.mit;
    # nixpkgs PR must add to lib/maintainers.nix:
    #   thatbagu = { github = "thatbagu"; githubId = 52824960; name = "Egor Kosaretskiy"; };
    maintainers = with maintainers; [ ];
    mainProgram = "amonite";
    platforms = platforms.unix;
  };
}
