{
  description = "dbt fusion as a nix flake";

  inputs = {
    flake-parts.url = "github:hercules-ci/flake-parts";
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
  };

  outputs = inputs @ {flake-parts, ...}:
    flake-parts.lib.mkFlake {inherit inputs;} {
      systems = ["x86_64-linux" "aarch64-linux" "aarch64-darwin" "x86_64-darwin"];
      flake.overlays.default = final: prev: let
        static = builtins.fromJSON (builtins.readFile ./static.json);
        targets = static.targets;
        system = final.stdenv.hostPlatform.system;
        target = targets.${system};
        systems = builtins.attrNames targets;
        mkDbtComponent = import ./mkdbt.nix {pkgs = final; inherit systems;};
        components = {
          dbt = static.dbt;
          dbt-lsp = static.lsp;
        };
      in
        builtins.mapAttrs (pname: comp:
          mkDbtComponent {
            inherit pname target;
            version = static.version;
            urlPrefix = comp.url;
            hash = comp.hashes.${target};
          })
        components;
      perSystem = {
        self',
        pkgs,
        system,
        ...
      }: let
        static = builtins.fromJSON (builtins.readFile ./static.json);
        targets = static.targets;
        target = targets.${system};
        systems = builtins.attrNames targets;
        mkDbtComponent = import ./mkdbt.nix {inherit pkgs systems;};

        components = {
          dbt = static.dbt;
          dbt-lsp = static.lsp;
        };
      in {
        formatter = pkgs.alejandra;
        packages =
          builtins.mapAttrs (pname: comp:
            mkDbtComponent {
              inherit pname target;
              version = static.version;
              urlPrefix = comp.url;
              hash = comp.hashes.${target};
            })
          components
          // {default = self'.packages.dbt;};
      };
    };
}
