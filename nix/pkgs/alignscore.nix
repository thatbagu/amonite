{ pkgs }:

pkgs.stdenvNoCC.mkDerivation {
  name = "alignscore-base-weights";

  src = pkgs.fetchurl {
    url = "https://huggingface.co/yzha/AlignScore/resolve/main/AlignScore-base.ckpt";
    outputHashAlgo = "sha256";
    outputHash = pkgs.lib.fakeHash;
  };

  dontUnpack = true;
  dontBuild = true;

  installPhase = ''
    mkdir -p "$out/checkpoints"
    cp "$src" "$out/checkpoints/AlignScore-base.ckpt"
  '';

  meta = {
    description = "AlignScore-base model checkpoint for NLI faithfulness verification";
    license = pkgs.lib.licenses.mit;
  };
}
