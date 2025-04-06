# ASUS ROG Ally RC71L-specific configurations
#
# hardware.devices.onexplayer

{ lib, config, ... }:

let
  products = [
    "ROG Ally RC71L_RC71L"
  ];

  is_device = builtins.elem (config.facter.report.smbios.system.product or "") products;
in

{
  options = {
    hardware.devices.rog_ally_rc71l = {
      enable = lib.mkOption {
        type = lib.types.bool;
        default = is_device;
        description = ''
          Whether to enable ASUS ROG Ally RC71L-specific configurations.
        '';
      };
    };
  };
}
