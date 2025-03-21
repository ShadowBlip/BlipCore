{ lib, ... }:

{
  imports = [
    ./onexplayer
  ];

  # These options should be discovered and set at install time
  options = {
    hardware.dmi = {
      product_name = lib.mkOption {
        type = lib.types.str;
        default = "";
        description = ''
          Detected product name of the device from /sys/class/dmi/id/product_name
        '';
      };

      product_sku = lib.mkOption {
        type = lib.types.str;
        default = "";
        description = ''
          Detected product sku of the device from /sys/class/dmi/id/product_sku
        '';
      };

      vendor_name = lib.mkOption {
        type = lib.types.str;
        default = "";
        description = ''
          Detected vendor name of the device from /sys/class/dmi/id/sys_vendor
        '';
      };
    };
  };
}
