# Ayaneo 2S-specific configurations
#
# hardware.devices.ayaneo.2s

{ lib, ... }:

let
  products = [
    "AYANEO 2S"
    "GEEK 1S"
  ];

  is_device = builtins.elem (config.facter.report.smbios.system.product or "") products;
in
{
  imports = [
    ./boot.nix
  ];

  options = {
    hardware.devices.ayaneo.2s = {
      enable = lib.mkOption {
        type = lib.types.bool;
        default = is_device;
        description = ''
          Whether to enable Ayaneo 2s-specific configurations.
        '';
      };
    };
  };
}
