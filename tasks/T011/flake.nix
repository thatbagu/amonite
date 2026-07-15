{
  description = "amonite task capsule";

  inputs = {

    amonite.url = "path:/home/egor/Code/amonite";
    nixpkgs.follows = "amonite/nixpkgs";
  };

  outputs = { self, nixpkgs, amonite }:
    let
      systems = [ "x86_64-linux" "aarch64-linux" "x86_64-darwin" "aarch64-darwin" ];
      forAllSystems = f: nixpkgs.lib.genAttrs systems (system: f nixpkgs.legacyPackages.${system});
      task = pkgs: import ./task.nix { inherit pkgs; amonite = amonite.lib { inherit pkgs; }; };
    in
    {
      packages = forAllSystems (pkgs: { default = task pkgs; });
      checks = forAllSystems (pkgs: { task = task pkgs; });
      devShells = forAllSystems (pkgs: {
        default = pkgs.mkShell {
          packages = (task pkgs).nativeBuildInputs or [ ];
        };
      });
    };
}
