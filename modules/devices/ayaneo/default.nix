# Ayaneo-specific configurations
#
# hardware.devices.ayaneo

{ lib, config, ... }:

let
  vendors = [
    "AYANEO"
  ];

  is_device = builtins.elem (config.facter.report.smbios.system.manufacturer or "") vendors;
in
{
  imports = [
    ./kernel.nix
  ];

  options = {
    hardware.devices.ayaneo = {
      enable = lib.mkOption {
        type = lib.types.bool;
        default = is_device;
        description = ''
          Whether to enable Ayaneo-specific configurations.
        '';
      };
    };
  };
}
