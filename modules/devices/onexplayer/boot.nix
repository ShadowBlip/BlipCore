{
  config,
  lib,
  ...
}:

let
  cfg = config.hardware.devices.onexplayer;
in
{
  options = {
    hardware.devices.onexplayer = {
      enableConsoleRotation = lib.mkOption {
        default = cfg.enable;
        defaultText = lib.literalExpression "config.hardware.devices.onexplayer.enable";
        type = lib.types.bool;
        description = ''
          Whether to rotate the console.
        '';
      };
    };
  };

  config = lib.mkIf cfg.enable {
    # Configure the panel orientation for the console and plymouth
    boot.kernelParams = lib.mkOverride 100 [
      "fbcon=rotate:3"
      "video=eDP-1:panel_orientation=left_side_up"
    ];

    # Add a udev rule to enable takeover of the turbo button
    services.udev.extraRules = lib.mkDefault ''
      KERNEL=="oxp-platform", SUBSYSTEM=="platform", RUN="/run/current-system/sw/bin/sh -c 'echo 1 > /sys/bus/platform/devices/oxp-platform/tt_toggle'", TAG+="uaccess"
    '';
  };
}
