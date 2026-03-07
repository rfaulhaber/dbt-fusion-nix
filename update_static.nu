#!/usr/bin/env nu

const targets = [
    [system target];
    ["x86_64-linux" "x86_64-unknown-linux-gnu"]
    ["aarch64-linux" "aarch64-unknown-linux-gnu"]
    ["x86_64-darwin" "x86_64-apple-darwin"]
    ["aarch64-darwin" "aarch64-apple-darwin"]
]

const components = [
    [key url_prefix];
    ["dbt" "https://public.cdn.getdbt.com/fs/cli/fs"]
    ["lsp" "https://public.cdn.getdbt.com/fs/lsp/fs-lsp"]
]

def main [] {
  let latest_version = http get https://public.cdn.getdbt.com/fs/versions.json
    | get latest.tag
    | str replace 'v' ''

  let static = open ./static.json

  let out = $components
    | reduce --fold $static { |c, acc|
        let hashes = $targets
            | reduce --fold {} { |t, hacc|
                let url = $"($c.url_prefix)-v($latest_version)-($t.target).tar.gz"
                let nix32 = ^nix-prefetch-url --type sha256 $url | str trim
                let hash = ^nix hash convert --hash-algo sha256 --to sri $nix32 | str trim
                $hacc | merge { $t.target: $hash }
            }

        $acc | upsert $c.key ($acc | get $c.key | upsert hashes $hashes)
    }

  $out
    | upsert version $latest_version
    | save -f static.json
}
