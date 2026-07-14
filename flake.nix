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

      packages = forAllSystems (pkgs: {
        amonite-tui = pkgs.buildGoModule {
          pname = "amonite-tui";
          version = "0.1.0";
          src = ./tui;
          vendorHash = "sha256-vj6i7Uc5LXnOF3Gi/GKy+FQ/I6eSyt2kKgZl8C5u2MM=";
          postInstall = ''mv "$out/bin/tui" "$out/bin/amonite-tui"'';
        };
        amonite = pkgs.writeShellApplication {
          name = "amonite";
          runtimeInputs = [ pkgs.git pkgs.jq self.packages.${pkgs.system}.amonite-tui ];
          text = ''
            export AMONITE_SHARE=${self}
          '' + builtins.readFile ./bin/amonite;
        };
        default = self.packages.${pkgs.system}.amonite;
      });

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
          packages = [ self.packages.${pkgs.system}.amonite pkgs.git pkgs.jq ];
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
