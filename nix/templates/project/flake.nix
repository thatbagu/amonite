{
  description = "amonite project — meta environment";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-25.05";
    amonite.url = "github:thatbagu/amonite"; # or path:../amonite for local dev
    amonite.inputs.nixpkgs.follows = "nixpkgs";
  };

  outputs = { self, nixpkgs, amonite }:
    let
      systems = [ "x86_64-linux" "aarch64-linux" "x86_64-darwin" "aarch64-darwin" ];
      forAllSystems = f: nixpkgs.lib.genAttrs systems (system: f nixpkgs.legacyPackages.${system});

      # Single computation of the task/cluster graph, shared by packages,
      # checks, and the graph output.
      graphFor = pkgs:
        let
          am = amonite.lib { inherit pkgs; };
          tasks = am.loadTasks { root = ./.; amonite = am; };
          clustersFile = ./clusters.nix;
          clusters =
            if builtins.pathExists clustersFile
            then import clustersFile { inherit pkgs tasks; amonite = am; }
            else { };
        in
        { inherit am tasks clusters; };
    in
    {
      devShells = forAllSystems (pkgs: {
        default = pkgs.mkShell {
          packages = [
            amonite.packages.${pkgs.system}.default  # amonite CLI always available
            pkgs.git
            # amonite:toolchain (managed by /amonite.plan — project-wide
            # packages are added here after the plan fixes the tech stack;
            # keep minimal until then)
          ];
        };
      });

      # Every tasks/*/task.nix, loaded and exposed:
      #   nix build .#task-T001      → build + verify one task
      #   nix flake check            → verify everything decomposed so far
      packages = forAllSystems (pkgs:
        let inherit (graphFor pkgs) tasks clusters;
        in
        nixpkgs.lib.mapAttrs' (id: drv: { name = "task-${id}"; value = drv; }) tasks
        // nixpkgs.lib.mapAttrs' (id: drv: { name = "cluster-${id}"; value = drv; }) clusters
        // nixpkgs.lib.optionalAttrs (clusters ? APP) { default = clusters.APP; });

      checks = forAllSystems (pkgs: self.packages.${pkgs.system});

      # Serializable derivation hierarchy for tooling:
      #   nix eval .#graph.<system> --json   (consumed by `amonite tui`)
      graph = forAllSystems (pkgs:
        let inherit (graphFor pkgs) am tasks clusters;
        in am.mkGraph { inherit tasks clusters; });
    };
}
