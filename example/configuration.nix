{ pkgs, ... }:
{
  # Use a local build of InputPlumber
  services.inputplumber = {
    enable = true;
    package = (pkgs.callPackage ../pkgs/by-name/in/inputplumber/local.nix { });
  };

  # Use a local build of PowerStation
  services.powerstation = {
    enable = true;
    package = (pkgs.callPackage ../pkgs/by-name/po/powerstation/local.nix { });
  };

  # Use a local build of OpenGamepadUI with remote debugging
  programs.opengamepadui = {
    enable = true;
    package = (
      pkgs.callPackage ../pkgs/by-name/op/opengamepadui/local.nix {
        withDebug = true;
      }
    );
    args = [
      "--remote-debug"
      "tcp://192.168.0.13:6007"
    ];
    gamescopeSession.enable = true;
    gamescopeSession.env = {
      LOG_LEVEL = "debug";
    };
  };
}
