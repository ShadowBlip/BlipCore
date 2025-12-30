{
  system,
  nixpkgs,
  rust-overlay,
}:

let
  overlays = [ (import rust-overlay) ];
  pkgs = import nixpkgs { inherit system overlays; };
  rust_version = "latest";
  rust = pkgs.rust-bin.stable.${rust_version}.default.override {
    extensions = [
      "rust-src" # for rust-analyzer
      "rust-analyzer"
    ];
  };
in

pkgs.mkShell {
  nativeBuildInputs = with pkgs; [
    autoPatchelfHook
    pkg-config
    godot_4_4
    godot_4_4-export-templates-bin
    scons
    gnumake
    dbus.dev
    xorg.libX11.dev
    xorg.libXres.dev
    xorg.libXtst
    xorg.libXi.dev
    squashfsTools
    openssl
    zip
    gettext
  ];

  buildInputs = with pkgs; [
    # Rust
    rust

    dbus
    gamescope
    mesa-demos
    hwdata

    # From godot_4 pkg runtime dependencies
    vulkan-loader
    libGL
    xorg.libX11
    xorg.libXcursor
    xorg.libXinerama
    xorg.libXext
    xorg.libXrandr
    xorg.libXrender
    xorg.libXi
    xorg.libXfixes
    libxkbcommon
    alsa-lib
  ];

  RUST_BACKTRACE = 1;

  shellHook = with pkgs; ''
    export LIBCLANG_PATH="${llvmPackages.libclang.lib}/lib"
    export CMAKE_INCLUDE_PATH="${dbus}/include/dbus-1.0/":$CMAKE_INCLUDE_PATH
    export GODOT=${godot_4_4}/bin/godot4
    $GODOT --version
  '';
}
