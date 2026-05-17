#!/usr/bin/env nu

# Port of the logic in install.sh that resolves and downloads dbt Fusion artifacts.
# Pins each component (dbt, dbt-lsp) to the highest version from versions.json for
# which all four target tarballs exist on the CDN. dbt and dbt-lsp can drift —
# upstream releases them on independent cadences (e.g. dbt v176 may exist before
# dbt-lsp v176 is published). For each component we pick the latest *complete* set.

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

const versions_url = "https://public.cdn.getdbt.com/fs/versions.json"

# Collect all unique concrete versions advertised in versions.json, sorted
# newest-first. Mirrors install.sh's determine_version which reads the same
# document — we just consider every named tag instead of only `latest`.
def candidate_versions [] {
    http get $versions_url
        | values
        | get tag
        | each { str replace 'v' '' }
        | uniq
        | sort -nrv
}

# HTTP HEAD probe — install.sh:280 uses `curl -sLI -f` for the same purpose.
def url_exists [url: string] {
    let code = ^curl -sLI -o /dev/null -w "%{http_code}" $url | into int
    $code == 200
}

# Walk candidates newest-first, return the first version where every target's
# tarball responds 200. None means we couldn't satisfy this component at all.
def find_latest [url_prefix: string, candidates: list<string>] {
    for v in $candidates {
        let all_exist = $targets | all { |t|
            let url = $"($url_prefix)-v($v)-($t.target).tar.gz"
            print -e $"  checking ($url)"
            url_exists $url
        }
        if $all_exist {
            print -e $"  -> picking v($v)"
            return $v
        }
    }
    null
}

def fetch_hashes [url_prefix: string, version: string] {
    $targets | reduce --fold {} { |t, acc|
        let url = $"($url_prefix)-v($version)-($t.target).tar.gz"
        let nix32 = ^nix-prefetch-url --type sha256 $url | str trim
        let sri = ^nix hash convert --hash-algo sha256 --to sri $nix32 | str trim
        $acc | merge { $t.target: $sri }
    }
}

def main [] {
    let candidates = candidate_versions
    print -e $"Candidate versions newest-first: ($candidates | str join ', ')"

    let existing = open ./static.json

    let updated = $components | reduce --fold $existing { |c, acc|
        print -e $"\n=== ($c.key) ==="
        let current = $acc | get $c.key
        let latest = find_latest $c.url_prefix $candidates

        if $latest == null {
            print -e $"  no complete version found, keeping current pin v($current.version)"
            $acc
        } else if $latest == $current.version {
            print -e $"  already at v($latest), no change"
            $acc
        } else {
            print -e $"  updating ($c.key): v($current.version) -> v($latest)"
            let hashes = fetch_hashes $c.url_prefix $latest
            $acc | upsert $c.key {
                version: $latest,
                url: $c.url_prefix,
                hashes: $hashes,
            }
        }
    }

    $updated | save -f static.json
}
