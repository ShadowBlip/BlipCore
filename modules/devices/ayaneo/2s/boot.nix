{
  config,
  lib,
  options,
  ...
}:

let
  cfg = config.hardware.devices.ayaneo.2s;
in
{
  config = lib.mkIf cfg.enable {
    boot.kernelParams = options.boot.kernelParams ++ [
      "fbcon=rotate:1"
    ];
  };
}
