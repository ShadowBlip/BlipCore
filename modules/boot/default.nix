{
  pkgs,
  config,
  lib,
  ...
}:

let
  hid-steam = pkgs.callPackage ../../pkgs/by-name/hi/hid-steam/package.nix {
    # Make sure the module targets the same kernel as system is using.
    kernel = config.boot.kernelPackages.kernel;
  };
in

{
  # Bootloader.
  boot.loader.efi.canTouchEfiVariables = lib.mkDefault true;
  boot.loader.systemd-boot.enable = lib.mkDefault true;
  boot.loader.systemd-boot.configurationLimit = lib.mkDefault 10;

  # Plymouth
  boot.consoleLogLevel = lib.mkDefault 0;
  boot.initrd.verbose = lib.mkDefault false;
  boot.loader.timeout = lib.mkDefault 0;
  boot.plymouth = lib.mkDefault {
    enable = true;
    theme = "rings";
    themePackages = with pkgs; [
      # By default we would install all themes
      (adi1090x-plymouth-themes.override {
        selected_themes = [ "rings" ];
      })
    ];
  };

  # Kernel
  boot.kernelPackages = lib.mkDefault pkgs.linuxPackages_latest;
  boot.kernelParams = lib.mkOverride 100 [
    "audit=0"
    "boot.shell_on_fail"
    "fbcon=vc:4-6"
    "iomem=relaxed"
    "log_buf_len=4M"
    "loglevel=3"
    "quiet"
    "rd.systemd.show_status=false"
    "rd.udev.log_level=3"
    "splash"
    "udev.log_priority=3"
  ];

  boot.extraModulePackages = [
    hid-steam
  ];

  # Kernel Configuration
  # https://discourse.nixos.org/t/patching-an-in-tree-linux-kernel-module/22137/2
  # https://nixos.wiki/wiki/Linux_kernel#Custom_configuration
  # https://nixos.org/manual/nixos/unstable/index.html#sec-kernel-config
  #nixpkgs.config.packageOverrides = pkgs: pkgs.lib.recursiveUpdate pkgs {
  #  linuxKernel.kernels.linux_5_10 = pkgs.linuxKernel.kernels.linux_5_10.override {
  #    extraConfig = ''
  #      KGDB y
  #    '';
  #  };
  #};

  boot.kernel.sysctl = {
    # From steamos-customizations-jupiter
    # https://github.com/Jovian-Experiments/steamos-customizations-jupiter/commit/bc978e8278ca29a884b1fe70cf2ec9e1e4ba05df
    "kernel.sched_cfs_bandwidth_slice_u" = lib.mkDefault 3000;
    "kernel.sched_latency_ns" = lib.mkDefault 3000000;
    "kernel.sched_min_granularity_ns" = lib.mkDefault 300000;
    "kernel.sched_wakeup_granularity_ns" = lib.mkDefault 500000;
    "kernel.sched_migration_cost_ns" = lib.mkDefault 50000;
    "kernel.sched_nr_migrate" = lib.mkDefault 128;
    "kernel.split_lock_mitigate" = lib.mkDefault 0;

    # > This is required due to some games being unable to reuse their TCP ports
    # > if they're killed and restarted quickly - the default timeout is too large.
    #  - https://github.com/Jovian-Experiments/steamos-customizations-jupiter/commit/4c7b67cc5553ef6c15d2540a08a737019fc3cdf1
    "net.ipv4.tcp_fin_timeout" = lib.mkDefault 5;
  };

}
