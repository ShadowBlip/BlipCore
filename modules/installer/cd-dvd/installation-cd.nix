{ pkgs, ... }:

{
  # https://github.com/NixOS/nixpkgs/blob/master/nixos/modules/installer/cd-dvd/iso-image.nix
  isoImage.edition = "gamescope";
  isoImage.grubTheme = pkgs.minimal-grub-theme;

  # Kernel
  boot.kernelPackages = pkgs.lib.mkDefault pkgs.linuxPackages_latest;

  # Plymouth
  boot.consoleLogLevel = 0;
  boot.initrd.verbose = false;
  boot.plymouth = {
    enable = true;
    theme = "rings";
    themePackages = with pkgs; [
      # By default we would install all themes
      (adi1090x-plymouth-themes.override {
        selected_themes = [ "rings" ];
      })
    ];
  };

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

  # Enable networking
  networking.networkmanager.enable = true;
  services.avahi.enable = true;
  services.avahi.nssmdns4 = true;

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
    defaultSession = "gamepad-os-installer";
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

  # Installer
  programs.gamepad-os-installer = {
    enable = true;
    gamescopeSession.enable = true;
    package = (pkgs.callPackage ../../../pkgs/by-name/ga/gamepad-os-installer/package.nix { });
    #package = (pkgs.callPackage ../../../pkgs/by-name/ga/gamepad-os-installer/local.nix { });
  };

  # Audio
  security.rtkit.enable = true;
  services.pulseaudio.enable = false;
  services.pipewire = {
    enable = true;
    alsa.enable = true;
    alsa.support32Bit = true;
    pulse.enable = true;
    jack.enable = true;
    extraConfig = {
      pipewire."92-latency" = {
        "context.properties" = {
          "default.clock.rate" = 48000;
          "default.clock.quantum" = 1024;
          "default.clock.min-quantum" = 1024;
          "default.clock.max-quantum" = 1024;
        };
      };
      pipewire-pulse."92-latency" = {
        "context.properties" = [
          {
            name = "libpipewire-module-protocol-pulse";
            args = { };
          }
        ];
        "pulse.properties" = {
          "pulse.min.req" = "1024/48000";
          "pulse.default.req" = "1024/48000";
          "pulse.max.req" = "1024/48000";
          "pulse.min.quantum" = "1024/48000";
          "pulse.max.quantum" = "1024/48000";
        };
        "stream.properties" = {
          "node.latency" = "1024/48000";
          "resample.quality" = 1;
        };
      };
    };
  };
}
