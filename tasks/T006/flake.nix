{
  # amonite task — encapsulated environment for one unit of work.
  #
  # The agent implementing this task works inside `nix develop ./tasks/T006`
  # and sees ONLY the toolchain granted in task.nix. The same task.nix is
  # imported by the project flake for aggregate verification, so this flake
  # is a development capsule, not a fork of truth.
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
          # The capsule: exactly the packages the task derivation grants.
          packages = (task pkgs).nativeBuildInputs or [ ];
        };
      });
    };
}
