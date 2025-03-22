{
  alsa-lib,
  autoPatchelfHook,
  cargo,
  dbus,
  fetchFromGitHub,
  gamescope,
  godot_4,
  godot_4-export-templates,
  hwdata,
  lib,
  libGL,
  libpulseaudio,
  mesa-demos,
  nix-update-script,
  pkg-config,
  rustPlatform,
  stdenv,
  udev,
  upower,
  vulkan-loader,
  xorg,
  withDebug ? false,
}:

stdenv.mkDerivation (finalAttrs: {
  pname = "gamepad-os-installer";
  version = "0.1.0";

  buildType = if withDebug then "debug" else "release";

  src = fetchFromGitHub {
    owner = "ShadowBlip";
    repo = "gamepad-os-installer";
    rev = "fb74613275d3824adb0ca94be35c532436aa35e4";
    #tag = "v${finalAttrs.version}";
    hash = "sha256-bw7o1TM+PmNJYnie+U3Zrlr3hMEwfmsO+XdK5hOzuIk=";
  };

  cargoDeps = rustPlatform.fetchCargoVendor {
    inherit (finalAttrs) src;
    sourceRoot = "source/${finalAttrs.cargoRoot}";
    hash = "sha256-z1h9+p/lYlErHTJi0b2N04PFlTAwM3wMDzbBHphuxtU=";
  };
  cargoRoot = "extensions";

  nativeBuildInputs = [
    autoPatchelfHook
    cargo
    godot_4
    godot_4-export-templates
    pkg-config
    rustPlatform.cargoSetupHook
  ];

  runtimeDependencies = [
    alsa-lib
    dbus
    gamescope
    hwdata
    libGL
    libpulseaudio
    mesa-demos
    udev
    upower
    vulkan-loader
    xorg.libX11
    xorg.libXcursor
    xorg.libXext
    xorg.libXi
    xorg.libXrandr
    xorg.libXres
    xorg.libXtst
  ];

  dontStrip = withDebug;

  env =
    let
      versionAndRelease = lib.splitString "-" godot_4.version;
    in
    {
      GODOT = lib.getExe godot_4;
      GODOT_VERSION = lib.elemAt versionAndRelease 0;
      GODOT_RELEASE = lib.elemAt versionAndRelease 1;
      EXPORT_TEMPLATE = "${godot_4-export-templates}";
      BUILD_TYPE = "${finalAttrs.buildType}";
    };

  makeFlags = [ "PREFIX=$(out)" ];

  buildFlags = [ "build" ];

  preBuild = ''
    # Godot looks for export templates in HOME
    export HOME=$(mktemp -d)
    mkdir -p $HOME/.local/share/godot/export_templates
    ln -s "${godot_4-export-templates}" "$HOME/.local/share/godot/export_templates/$GODOT_VERSION.$GODOT_RELEASE"
  '';

  postInstall = ''
    # The Godot binary looks in "../lib" for gdextensions
    mkdir -p $out/share/lib
    mv $out/share/gamepad-os-installer/*.so $out/share/lib
  '';

  passthru.updateScript = nix-update-script { };

  meta = {
    license = lib.licenses.gpl3Only;
    platforms = [ "x86_64-linux" ];
    maintainers = with lib.maintainers; [ shadowapex ];
    mainProgram = "gamepad-os-installer";
  };
})
