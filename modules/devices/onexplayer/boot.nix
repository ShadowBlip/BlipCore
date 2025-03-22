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
    boot.kernelParams = lib.mkOverride 100 [
      "fbcon=rotate:3"
    ];
  };
}
