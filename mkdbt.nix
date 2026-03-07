{
  pkgs,
  systems,
}: {
  pname,
  version,
  target,
  hash,
  urlPrefix,
}: let
  lib = pkgs.lib;
in
  pkgs.stdenv.mkDerivation {
    inherit pname version;

    src = pkgs.fetchurl {
      inherit hash;
      url = "${urlPrefix}-v${version}-${target}.tar.gz";
    };

    sourceRoot = ".";

    nativeBuildInputs = lib.optionals pkgs.stdenv.hostPlatform.isLinux [
      pkgs.autoPatchelfHook
    ];

    buildInputs = lib.optionals pkgs.stdenv.hostPlatform.isLinux [
      pkgs.stdenv.cc.cc.lib # libstdc++/libgcc_s
      pkgs.openssl
      pkgs.zlib
    ];

    dontConfigure = true;
    dontBuild = true;

    installPhase = ''
      runHook preInstall
      install -Dm755 ${pname} $out/bin/${pname}
      runHook postInstall
    '';

    meta = {
      description =
        if pname == "dbt"
        then "dbt Fusion engine CLI — next-generation dbt, written in Rust"
        else "dbt Fusion Language Server Protocol (LSP) server";
      homepage = "https://docs.getdbt.com/docs/fusion/about-fusion";
      license = lib.licenses.unfree;
      platforms = systems;
      mainProgram = pname;
    };
  }
