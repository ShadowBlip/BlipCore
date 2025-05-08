{
  config,
  lib,
  pkgs,
  ...
}:

let
  cfg = config.hardware.devices.ayaneo;
in
{
  config = lib.mkIf cfg.enable {
    # Enable the ayaneo-platform kernel driver
    boot.extraModulePackages = [
      (pkgs.callPackage ../../../pkgs/by-name/ay/ayaneo-platform/package.nix { })
    ];
  };
}

