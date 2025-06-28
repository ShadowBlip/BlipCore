{
  config,
  lib,
  options,
  ...
}:

let
  cfg = config.hardware.devices.asus.ally.rc71l;
in
{
  config = lib.mkIf cfg.enable {
    boot.kernelParams = options.boot.kernelParams ++ [
      "amd_pstate=active"
    ];
  };
}
