{
  lib,
  rustPlatform,
  fetchFromGitHub,
  pkg-config,
  pam,
}:

rustPlatform.buildRustPackage rec {
  pname = "login_ng";
  version = "0.6.6";

  src = fetchFromGitHub {
    owner = "NeroReflex";
    repo = "login_ng";
    tag = version;
    hash = "sha256-22AI+JtYLPK+RgLcfm75gqOUtSAsXvkLnnPkc948oKg=";
  };

  doCheck = false;
  useFetchCargoVendor = true;
  cargoHash = "sha256-vGMrp5NtDb10xNaIJmr6+C8FFec33XObK39YAjohGW8=";

  nativeBuildInputs = [
    pkg-config
    rustPlatform.bindgenHook
  ];

  buildInputs = [
    pam
  ];

  postInstall = ''
    cp -r rootfs/etc $out/
    cp -r rootfs/usr/* $out/
  '';

  meta = {
    description = "A greeter written in rust that also supports autologin with systemd-homed";
    homepage = "https://github.com/NeroReflex/login_ng";
    license = lib.licenses.gpl3Plus;
    maintainers = with lib.maintainers; [ shadowapex ];
    mainProgram = "login_ng";
  };
}
