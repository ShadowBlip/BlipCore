# OneXPlayer-specific configurations
#
# hardware.devices.onexplayer

{ lib, config, ... }:

let
  products = [
    "AOKZOE A1 AR07"
    "AOKZOE A1 Pro"
    "ONE XPLAYER"
    "ONEXPLAYER 1 T08"
    "ONEXPLAYER 1S A08"
    "ONEXPLAYER 1S T08"
    "ONEXPLAYER mini A07"
    "ONEXPLAYER mini GA72"
    "ONEXPLAYER mini GT72"
    "ONEXPLAYER Mini Pro"
    "ONEXPLAYER GUNDAM GA72"
    "ONEXPLAYER 2 ARP23"
    "ONEXPLAYER 2 PRO ARP23H"
    "ONEXPLAYER 2 PRO ARP23P"
    "ONEXPLAYER 2 PRO ARP23P EVA-01"
  ];

  is_onexplayer = builtins.elem config.hardware.dmi.product_name products;
in

{
  imports = [
    ./gamescope.nix
  ];

  options = {
    hardware.devices.onexplayer = {
      enable = lib.mkOption {
        type = lib.types.bool;
        default = is_onexplayer;
        description = ''
          Whether to enable OneXPlayer-specific configurations.
        '';
      };
    };
  };
}
