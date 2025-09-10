{
  lib,
  stdenv,
  fetchFromGitHub,
  linuxPackages_latest,
  kernel ? linuxPackages_latest.kernel,
}:

let
  # Remove unnecessary build flags
  noUndefineFlags = lib.lists.remove "--eval=undefine modules" kernel.makeFlags;
  flags = lib.lists.remove "O=\$\(buildRoot\)" noUndefineFlags;
in

stdenv.mkDerivation (finalAttr: {
  pname = "ayaneo-platform";
  version = "0.3.4";

  src = fetchFromGitHub {
    owner = "shadowblip";
    repo = finalAttr.pname;
    rev = "8ccdf707e7dd7a7c97307b078122b80e92a4ca62";
    hash = "sha256-rBBwwsInA+0zqktVLsxP+sYCF624y6KTWYOxWVgXhgg=";
  };

  setSourceRoot = ''
    export sourceRoot=$(pwd)/source
  '';

  hardeningDisable = [ "pic" ];

  nativeBuildInputs = kernel.moduleBuildDependencies;

  # https://docs.kernel.org/kbuild/modules.html#how-to-build-external-modules
  makeFlags = flags ++ [
    "-C"
    "${kernel.dev}/lib/modules/${kernel.modDirVersion}/build"
    "EXTRA_CFLAGS=-DOXP_PLATFORM_DRIVER_VERSION=${finalAttr.version}"
    "M=${finalAttr.src}"
    "MO=/tmp"
  ];

  buildFlags = [
    "modules"
  ];

  # https://docs.kernel.org/kbuild/modules.html#module-installation
  installFlags = [
    "INSTALL_MOD_PATH=${placeholder "out"}"
    "INSTALL_MOD_DIR=kernel/drivers/platform/x86"
  ];
  installTargets = [ "modules_install" ];

  meta = with lib; {
    homepage = "https://github.com/shadowblip/ayaneo-platform";
    description = "Linux drivers for AYANEO x86 handhelds providing RGB control";
    license = with licenses; [
      gpl2Only
    ];
    maintainers = with maintainers; [ shadowapex ];
    platforms = [ "x86_64-linux" ];
  };
})
