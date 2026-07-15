{ pkgs }:

pkgs.python3Packages.buildPythonPackage {
  pname = "alignscore";
  version = "0.1.3";
  pyproject = true;

  src = pkgs.fetchFromGitHub {
    owner = "yuh-zha";
    repo  = "AlignScore";
    rev   = "a0936d5afee642a46b22f6c02a163478447aa493";
    hash  = "sha256-6Wp//Oy4eeqgozmkA1Y/nQKn8LlJR3TQ6UF5kdY7I1Y=";
  };

  build-system = [ pkgs.python3Packages.hatchling ];

  # Three API/data breakages vs the old version pins:
  # 1. transformers removed AdamW in 4.21+; lives in torch.optim now
  # 2. pytorch-lightning 2.x requires load_from_checkpoint on the class
  # 3. spacy en_core_web_sm / nltk punkt are unavailable offline in Nix sandbox;
  #    patch both sentence-splitting paths to use a dependency-free regex fallback
  postPatch = ''
    substituteInPlace src/alignscore/model.py \
      --replace-fail \
        'from transformers import AdamW, get_linear_schedule_with_warmup, AutoConfig' \
        'from torch.optim import AdamW; from transformers import get_linear_schedule_with_warmup, AutoConfig'

    substituteInPlace src/alignscore/inference.py \
      --replace-fail \
        'BERTAlignModel(model=model).load_from_checkpoint(checkpoint_path=ckpt_path, strict=False)' \
        'BERTAlignModel.load_from_checkpoint(checkpoint_path=ckpt_path, strict=False, model=model)'

    # Inject a pure-Python sentence splitter right after the imports block
    # and wire it in place of both spacy and nltk.sent_tokenize usages.
    substituteInPlace src/alignscore/inference.py \
      --replace-fail \
        'import spacy' \
        'import re as _re'
    substituteInPlace src/alignscore/inference.py \
      --replace-fail \
        'from nltk.tokenize import sent_tokenize' \
        'def sent_tokenize(t): return [s.strip() for s in _re.split(r"(?<=[.!?])\s+", t.strip()) if s.strip()] or [t]'
    substituteInPlace src/alignscore/inference.py \
      --replace-fail \
        'self.spacy = spacy.load('"'"'en_core_web_sm'"'"')' \
        'self.spacy = None'
    substituteInPlace src/alignscore/inference.py \
      --replace-fail \
        '[each.text for each in self.spacy(premise).sents]' \
        'sent_tokenize(premise)'
    substituteInPlace src/alignscore/inference.py \
      --replace-fail \
        '[each.text for each in self.spacy(hypo).sents]' \
        'sent_tokenize(hypo)'
  '';

  # AlignScore pins old upper bounds; relax them — we test behaviour, not versions
  nativeBuildInputs = [ pkgs.python3Packages.pythonRelaxDepsHook ];
  pythonRelaxDeps = true;

  propagatedBuildInputs = with pkgs.python3Packages; [
    spacy    # patched out at runtime but still listed in wheel metadata
    nltk     # same — replaced by pure-Python fallback
    torch
    transformers
    tqdm
    jsonlines
    numpy
    datasets
    scikit-learn
    pytorch-lightning
    scipy
    tensorboard
    protobuf
  ];

  doCheck = false;
}
