{
  lib,
  stdenv,
  fetchFromGitHub,
  linuxPackages_latest,
  kernel ? linuxPackages_latest.kernel,
}:

stdenv.mkDerivation (finalAttr: {
  pname = "ayaneo-platform";
  version = "0.3.4";

  src = fetchFromGitHub {
    owner = "shadowblip";
    repo = finalAttr.pname;
    rev = "750b6754b1e241dac68deaabdb2683e3cc4e1dd1";
    hash = "sha256-J6jcXKQxLENEt1YykcwO4pdT+srGIkAAbdKl16xUklM=";
  };

  hardeningDisable = [ "pic" ];

  nativeBuildInputs = kernel.moduleBuildDependencies;

  env = {
    EXTRA_CFLAGS = "-DOXP_PLATFORM_DRIVER_VERSION=${finalAttr.version}";
    KERNEL_DIR = "${kernel.dev}/lib/modules/${kernel.modDirVersion}/build";
  };

  buildPhase = ''
    runHook preBuild
    make -C $KERNEL_DIR M=$(pwd) modules
    runHook postBuild
  '';

  installPhase = ''
    runHook preInstall
    install *.ko -Dm444 -t $out/lib/modules/${kernel.modDirVersion}/kernel/drivers/platform/x86
    runHook postInstall
  '';

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
