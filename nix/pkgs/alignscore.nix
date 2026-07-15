{ pkgs }:

let
  inherit (pkgs) lib;

  ckpt = pkgs.fetchurl {
    url = "https://huggingface.co/yzha/AlignScore/resolve/main/AlignScore-base.ckpt";
    sha256 = "sha256-au22N/BZarKbrvkelEZqV/Ay4C/uplSXhRiRn+CYFgc=";
  };

  # roberta-base files — fetched individually as FODs so Nix can cache each
  # separately. Run `nix build .#alignscore-weights` once; hash mismatches
  # will give the correct sha256 to paste in here.
  fetch = url: sha256: pkgs.fetchurl { inherit url sha256; };

  roberta-config     = fetch "https://huggingface.co/roberta-base/resolve/main/config.json"           lib.fakeHash;
  roberta-tok-config = fetch "https://huggingface.co/roberta-base/resolve/main/tokenizer_config.json" lib.fakeHash;
  roberta-tokenizer  = fetch "https://huggingface.co/roberta-base/resolve/main/tokenizer.json"        lib.fakeHash;
  roberta-vocab      = fetch "https://huggingface.co/roberta-base/resolve/main/vocab.json"            lib.fakeHash;
  roberta-merges     = fetch "https://huggingface.co/roberta-base/resolve/main/merges.txt"            lib.fakeHash;
  roberta-model      = fetch "https://huggingface.co/roberta-base/resolve/main/pytorch_model.bin"     lib.fakeHash;

in pkgs.runCommand "alignscore-weights" {} ''
  mkdir -p "$out/checkpoints" "$out/roberta-base"
  cp ${ckpt}              "$out/checkpoints/AlignScore-base.ckpt"
  cp ${roberta-config}    "$out/roberta-base/config.json"
  cp ${roberta-tok-config} "$out/roberta-base/tokenizer_config.json"
  cp ${roberta-tokenizer} "$out/roberta-base/tokenizer.json"
  cp ${roberta-vocab}     "$out/roberta-base/vocab.json"
  cp ${roberta-merges}    "$out/roberta-base/merges.txt"
  cp ${roberta-model}     "$out/roberta-base/pytorch_model.bin"
''
