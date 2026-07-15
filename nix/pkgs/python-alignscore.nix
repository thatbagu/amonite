{ pkgs }:

let
  # pytorch-lightning was renamed to lightning in newer releases;
  # pick whichever name nixpkgs 25.05 ships.
  pl = pkgs.python3Packages."pytorch-lightning"
    or pkgs.python3Packages.lightning;
in

pkgs.python3Packages.buildPythonPackage rec {
  pname = "alignscore";
  version = "0.1.0";

  src = pkgs.fetchPypi {
    inherit pname version;
    sha256 = pkgs.lib.fakeHash;
  };

  propagatedBuildInputs = with pkgs.python3Packages; [
    transformers
    torch
    scikit-learn
    tqdm
    numpy
    sentencepiece
    pl
  ];

  doCheck = false;
}
