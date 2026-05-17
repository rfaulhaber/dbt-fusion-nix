{
  description = "dbt fusion as a nix flake";

  inputs = {
    flake-parts.url = "github:hercules-ci/flake-parts";
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
  };

  outputs = inputs @ {flake-parts, ...}: let
    static = builtins.fromJSON (builtins.readFile ./static.json);
    systems = builtins.attrNames static.targets;

    mkPackages = pkgs: let
      target = static.targets.${pkgs.stdenv.hostPlatform.system};
      mkDbtComponent = import ./mkdbt.nix {inherit pkgs systems;};
      forComponent = pname: description: comp:
        mkDbtComponent {
          inherit pname target description;
          inherit (comp) version;
          urlPrefix = comp.url;
          hash = comp.hashes.${target};
        };
    in {
      dbt = forComponent "dbt" "dbt Fusion engine CLI — next-generation dbt, written in Rust" static.dbt;
      dbt-lsp = forComponent "dbt-lsp" "dbt Fusion Language Server Protocol (LSP) server" static.lsp;
    };
  in
    flake-parts.lib.mkFlake {inherit inputs;} {
      inherit systems;
      flake.overlays.default = final: _prev: mkPackages final;
      perSystem = {
        self',
        pkgs,
        ...
      }: {
        formatter = pkgs.alejandra;
        packages = mkPackages pkgs // {default = self'.packages.dbt;};
      };
    };
}
