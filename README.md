# dbt-fusion-nix

Nix flake for [dbt Fusion](https://docs.getdbt.com/docs/fusion/about-fusion) — the next-generation dbt engine written in Rust.

**This project has no affiliation with dbt.**

Packages the `dbt` CLI and `dbt-lsp` language server for `x86_64-linux`, `aarch64-linux`, `x86_64-darwin`, and `aarch64-darwin`.

## Usage

### Run directly

```sh
nix run github:rfaulhaber/dbt-fusion-nix        # dbt CLI
nix run github:rfaulhaber/dbt-fusion-nix#dbt-lsp # LSP server
```

### In a flake

```nix
{
  inputs.dbt-fusion.url = "github:rfaulhaber/dbt-fusion-nix";

  outputs = { dbt-fusion, ... }: {
    # use packages directly
    packages.x86_64-linux.default = dbt-fusion.packages.x86_64-linux.dbt;

    # or apply the overlay to your nixpkgs
    nixpkgs.overlays = [ dbt-fusion.overlays.default ];
    # then: pkgs.dbt, pkgs.dbt-lsp
  };
}
```

### Imperatively

```sh
NIXPKGS_ALLOW_UNFREE=1 nix profile install github:rfaulhaber/dbt-fusion-nix --impure
```

> **Note:** dbt Fusion is unfree software, so `--impure` with `NIXPKGS_ALLOW_UNFREE=1` (or the equivalent nixpkgs config) is required.

## Outputs

| Output | Description |
|---|---|
| `packages.<system>.dbt` | dbt Fusion CLI |
| `packages.<system>.dbt-lsp` | dbt Fusion LSP server |
| `packages.<system>.default` | Alias for `dbt` |
| `overlays.default` | Nixpkgs overlay providing `dbt` and `dbt-lsp` |

## Updating

A nightly GitHub Action runs `update_static.nu` to check for new releases and update `static.json` with fresh hashes. To update manually:

```sh
nu update_static.nu
```

Requires [Nushell](https://www.nushell.sh/) and `nix-prefetch-url`.
