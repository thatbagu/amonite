{
  description = "amonite — spec-driven development that compiles to Nix derivations";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-25.05";
  };

  outputs = { self, nixpkgs }:
    let
      systems = [ "x86_64-linux" "aarch64-linux" "x86_64-darwin" "aarch64-darwin" ];
      forAllSystems = f: nixpkgs.lib.genAttrs systems (system: f nixpkgs.legacyPackages.${system});
    in
    {
      # Core library: mkTask / mkCluster / mkApplication.
      # Instantiate with a pkgs set: amonite.lib { inherit pkgs; }
      lib = import ./nix/lib.nix;

      templates = {
        project = {
          path = ./nix/templates/project;
          description = "amonite project: meta environment flake + spec flow scaffolding";
        };
        task = {
          path = ./nix/templates/task;
          description = "amonite task: encapsulated flake environment for one task";
        };
        default = self.templates.project;
      };

      packages = forAllSystems (pkgs:
        let
          amonite-lib = self.lib { inherit pkgs; };
          tasks    = amonite-lib.loadTasks { root = ./.; amonite = amonite-lib; };
          clusters = import ./clusters.nix { inherit pkgs tasks; amonite = amonite-lib; };
          pkg      = pkgs.callPackage ./package.nix { src = self; };
        in
        {
          # package.nix is the single source of truth for the derivation and
          # vendorHash; the flake just delegates to it.
          amonite     = pkg;
          amonite-tui = pkg.passthru.tui;
          default     = pkg;  # installable CLI; APP is exposed as cluster-APP
        }
        # Expose task and cluster derivations for `amonite verify T001` / `amonite verify C001`
        // (nixpkgs.lib.mapAttrs' (id: drv: { name = "task-${id}";    value = drv; }) tasks)
        // (nixpkgs.lib.mapAttrs' (id: drv: { name = "cluster-${id}"; value = drv; }) clusters)
      );

      # Graph output consumed by `amonite tui`.
      graph = forAllSystems (pkgs:
        let
          amonite-lib = self.lib { inherit pkgs; };
          tasks    = amonite-lib.loadTasks { root = ./.; amonite = amonite-lib; };
          clusters = import ./clusters.nix { inherit pkgs tasks; amonite = amonite-lib; };
        in
        amonite-lib.mkGraph { inherit tasks clusters; }
      );

      apps = forAllSystems (pkgs: {
        default = {
          type = "app";
          program = "${self.packages.${pkgs.system}.amonite}/bin/amonite";
        };
      });

      # Minimal by default: the meta shell carries only what the flow itself
      # needs. Project toolchains live in generated project flakes, task
      # toolchains in generated task flakes.
      devShells = forAllSystems (pkgs: {
        default = pkgs.mkShell {
          # amonite:toolchain — kept minimal (principle E3); task-specific
          # tools are granted per-task in their task.nix env lists.
          packages = [
            self.packages.${pkgs.system}.amonite
            pkgs.git
            pkgs.jq
            pkgs.shellcheck  # bin/amonite linting (N3)
            pkgs.go          # TUI development
            pkgs.mdbook      # local docs builds (US6)
          ];
        };
      });

      # Dogfood: amonite verifies itself. A sample task and cluster are built
      # through the library so a broken lib.nix fails `nix flake check`.
      checks = forAllSystems (pkgs:
        let
          amonite = self.lib { inherit pkgs; };
          sampleTask = amonite.mkTask {
            id = "T000";
            title = "lib self-test task";
            env = [ pkgs.coreutils ];
            build = ''
              echo "hello from amonite" > "$out/artifact.txt"
            '';
            verify = {
              artifact-exists = ''test -s "$out/artifact.txt"'';
              artifact-content = ''grep -q amonite "$out/artifact.txt"'';
            };
          };
          sampleCluster = amonite.mkCluster {
            id = "C000";
            title = "lib self-test cluster";
            tasks = [ sampleTask ];
            verify = {
              member-present = ''test -e "$out/tasks/T000/artifact.txt"'';
            };
          };
        in
        {
          lib-task = sampleTask;
          lib-cluster = sampleCluster;
          tui = self.packages.${pkgs.system}.amonite-tui;
          cli = pkgs.runCommand "amonite-cli-check" { nativeBuildInputs = [ pkgs.shellcheck ]; } ''
            shellcheck --shell=bash ${./bin/amonite}
            touch "$out"
          '';
        });
    };
}
