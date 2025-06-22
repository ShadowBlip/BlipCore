{
  cargo,
  fetchFromGitHub,
  gamescope,
  godot_4_4,
  hwdata,
  lib,
  mesa-demos,
  nix-update-script,
  pkg-config,
  rustPlatform,
  stdenv,
  udev,
  upower,
  withDebug ? false,
}:

stdenv.mkDerivation (finalAttrs: {
  pname = "gamepad-os-installer";
  version = "0.1.0";

  buildType = if withDebug then "debug" else "release";

  src = fetchFromGitHub {
    owner = "ShadowBlip";
    repo = "gamepad-os-installer";
    rev = "a5e776c902828fb673ad84eb72cd689af61415cb";
    #tag = "v${finalAttrs.version}";
    hash = "sha256-rOE9daFevp3zgt6EoWhxhRZW2w1cLZZHoq1u4mE377s=";
  };

  cargoDeps = rustPlatform.fetchCargoVendor {
    inherit (finalAttrs) src;
    sourceRoot = "source/${finalAttrs.cargoRoot}";
    hash = "sha256-VDg4z57u8QbhXgJ31QN/I5atOP+BYvURZBLL11mJHgE=";
  };
  cargoRoot = "extensions";

  nativeBuildInputs = [
    cargo
    godot_4_4
    pkg-config
    rustPlatform.cargoSetupHook
  ];

  dontStrip = withDebug;

  env =
    let
      versionAndRelease = lib.splitString "-" godot_4_4.version;
    in
    {
      GODOT = lib.getExe godot_4_4;
      GODOT_VERSION = lib.elemAt versionAndRelease 0;
      GODOT_RELEASE = lib.elemAt versionAndRelease 1;
      EXPORT_TEMPLATE = "${godot_4_4.export-template}/share/godot/export_templates";
      BUILD_TYPE = "${finalAttrs.buildType}";
    };

  makeFlags = [ "PREFIX=$(out)" ];

  buildFlags = [ "build" ];

  preBuild = ''
    # Godot looks for export templates in HOME
    export HOME=$(mktemp -d)
    mkdir -p $HOME/.local/share/godot
    ln -s "$EXPORT_TEMPLATE" "$HOME"/.local/share/godot/
  '';

  postInstall =
    let
      runtimeDependencies = [
        gamescope
        hwdata
        mesa-demos
        udev
        upower
      ];
    in
    ''
      # The Godot binary looks in "../lib" for gdextensions
      mkdir -p $out/share/lib
      mv $out/share/gamepad-os-installer/*.so $out/share/lib
      patchelf --add-rpath ${lib.makeLibraryPath runtimeDependencies} $out/share/lib/*.so
    '';

  passthru.updateScript = nix-update-script { };

  meta = {
    license = lib.licenses.gpl3Only;
    platforms = [ "x86_64-linux" ];
    maintainers = with lib.maintainers; [ shadowapex ];
    mainProgram = "gamepad-os-installer";
  };
})
