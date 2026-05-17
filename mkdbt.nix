{
  pkgs,
  systems,
}: {
  pname,
  version,
  target,
  hash,
  urlPrefix,
  description,
}: let
  inherit (pkgs) lib stdenv;
  isLinux = stdenv.hostPlatform.isLinux;
in
  stdenv.mkDerivation {
    inherit pname version;

    src = pkgs.fetchurl {
      inherit hash;
      url = "${urlPrefix}-v${version}-${target}.tar.gz";
    };

    # The tarball expands to a single binary at its root, not into a
    # versioned subdirectory — disable stdenv's default cd-into-subdir.
    sourceRoot = ".";

    nativeBuildInputs = lib.optional isLinux pkgs.autoPatchelfHook;

    # The binary's only non-glibc NEEDED entry is libgcc_s (verified via
    # `ldd`); stdenv.cc.cc.lib provides it. autoPatchelfHook is a no-op on
    # other deps because the binary doesn't reference them.
    buildInputs = lib.optional isLinux stdenv.cc.cc.lib;

    dontConfigure = true;
    dontBuild = true;

    installPhase = ''
      runHook preInstall

      bin=$(find . -type f -perm -u+x -print -quit)
      if [ -z "$bin" ]; then
        echo "mkdbt: no executable found in tarball for ${pname}" >&2
        exit 1
      fi
      install -Dm755 "$bin" "$out/bin/${pname}"

      runHook postInstall
    '';

    meta = {
      inherit description;
      homepage = "https://docs.getdbt.com/docs/fusion/about-fusion";
      license = lib.licenses.unfree;
      platforms = systems;
      mainProgram = pname;
    };
  }
