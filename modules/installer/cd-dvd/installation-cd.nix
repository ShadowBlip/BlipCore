{ pkgs, ... }:

{
  isoImage.edition = "gamescope";

  # Kernel
  boot.kernelPackages = pkgs.lib.mkDefault pkgs.linuxPackages_latest;

  # Nix Settings
  nix.settings = {
    # Enable flakes and new 'nix' command
    experimental-features = [
      "nix-command"
      "flakes"
    ];
    # Allow sudo users to do dangerous nix things
    trusted-users = [
      "root"
      "@wheel"
    ];
  };

  # Allow unfree packages
  nixpkgs.config.allowUnfree = true;
  nixpkgs.hostPlatform = "x86_64-linux";

  # Graphics
  hardware.graphics = {
    enable = true;
    enable32Bit = true;
  };
  services.xserver.videoDrivers = [ "amdgpu" ];

  # Display Manager
  services.xserver.enable = true;
  services.xserver.displayManager = {
    lightdm = {
      enable = true;
      greeter.enable = false;
    };
  };
  services.displayManager = {
    defaultSession = "opengamepadui";
    autoLogin = {
      enable = true;
      user = "nixos";
    };
  };

  # List packages installed in system profile. To search, run:
  # $ nix search wget
  environment.pathsToLink = [ "/share" ];
  environment.systemPackages = with pkgs; [
    bc
    btop-rocm
    ccze
    curl
    ethtool
    evtest
    ffmpeg-full
    file
    fzf
    gamescope
    git
    glxinfo
    gnumake
    hid-tools
    hwdata
    jq
    mangohud
    pciutils
    pstree
    screen
    tree
    unzip
    usbutils
    vulkan-tools
    wget
    xorg.xprop
    xorg.xwininfo
    yq
    zip
  ];

  # Battery/Power
  services.upower = {
    enable = true;
  };

  # Bluetooth
  hardware.bluetooth.enable = true;
  hardware.bluetooth.powerOnBoot = true;

  # Editor
  programs.neovim = {
    enable = true;
    viAlias = true;
    vimAlias = true;
  };

  # OpenGamepadUI
  programs.opengamepadui = {
    enable = true;
    gamescopeSession.enable = true;
    gamescopeSession.env = {
      DBUS_FATAL_WARNINGS = "0";
      LOG_LEVEL = "debug";
    };
  };
}
