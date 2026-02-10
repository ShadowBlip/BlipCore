{
  config,
  lib,
  pkgs,
  inputs,
  ...
}:

let
  cfg = config.hardware.devices.ayaneo;
  nix-cachyos-kernel = inputs.shadowblip.inputs.nix-cachyos-kernel;
in
{
  config = lib.mkIf cfg.enable {
    # Enable the ayaneo-platform kernel driver
    boot.extraModulePackages = [
      (pkgs.callPackage ../../../pkgs/by-name/ay/ayaneo-platform/package.nix {
        stdenv = pkgs.clangStdenv;
        kernel = nix-cachyos-kernel.legacyPackages.x86_64-linux.linuxPackages-cachyos-deckify;
      })
    ];
  };
}
