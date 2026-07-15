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

  roberta-config     = fetch "https://huggingface.co/roberta-base/resolve/main/config.json"           "sha256-7wGF4qrm4GxfEFooUAaVLDQOIMfb9DyG7IJgGxP8Rek=";
  roberta-tok-config = fetch "https://huggingface.co/roberta-base/resolve/main/tokenizer_config.json" "sha256-mU9GdUxb9AFPGqktNLE3QxnDprP3AhBc1bdCvq7NGM4=";
  roberta-tokenizer  = fetch "https://huggingface.co/roberta-base/resolve/main/tokenizer.json"        "sha256-hHu+q2F01mqIiY9ynVL6jTVfr+G+oQHPlg3UBFgd9w4=";
  roberta-vocab      = fetch "https://huggingface.co/roberta-base/resolve/main/vocab.json"            "sha256-nn9jwtFdZmtS4h0lDS5RO4fJtxPPpph6gu2J5eblBlU=";
  roberta-merges     = fetch "https://huggingface.co/roberta-base/resolve/main/merges.txt"            "sha256-HOFmR3PFDz4MyIQmGak+3EYkUltyixiKngvjO3cmrcU=";
  roberta-model      = fetch "https://huggingface.co/roberta-base/resolve/main/pytorch_model.bin"     "sha256-J4t6lXOcQ5L66bgYu1ND3eIL4biTGPN6bZOeHhueRhs=";

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
