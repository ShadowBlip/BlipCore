{ config, lib, ... }:

let
  cfg = config.hardware.devices.onexplayer;
in
{
  options = {
    hardware.devices.onexplayer = {
      enableGamescopeRotation = lib.mkOption {
        default = cfg.enable;
        defaultText = lib.literalExpression "config.hardware.devices.onexplayer.enable";
        type = lib.types.bool;
        description = ''
          Whether to rotate the display panel in gamescope.
        '';
      };
    };
  };

  config = lib.mkIf cfg.enable {
    programs.opengamepadui.gamescopeSession.args = [
      "--prefer-output"
      "*,eDP-1"
      "--default-touch-mode"
      "4"
      "--hide-cursor-delay"
      "3000"
      "--fade-out-duration"
      "200"
      "--generate-drm-mode"
      "fixed"
      "--force-orientation"
      "left"
    ];
  };
}
