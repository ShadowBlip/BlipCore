{
  pkgs,
  lib,
  inputs,
  ...
}:

{
  imports = [
    inputs.shadowblip.nixosModules.nixos-facter
    ./boot
    ./devices
    ./updater
  ];

  # Networking
  networking.hostName = lib.mkDefault "nixos"; # Define your hostname.
  # networking.wireless.enable = true;  # Enables wireless support via wpa_supplicant.

  # Configure network proxy if necessary
  # networking.proxy.default = "http://user:password@proxy:port/";
  # networking.proxy.noProxy = "127.0.0.1,localhost,internal.domain";

  # Enable networking
  networking.networkmanager.enable = lib.mkDefault true;
  services.avahi.enable = lib.mkDefault true;
  services.avahi.nssmdns4 = lib.mkDefault true;

  # Select internationalisation properties.
  i18n.defaultLocale = lib.mkDefault "en_US.UTF-8";
  i18n.extraLocaleSettings = lib.mkDefault {
    LC_ADDRESS = "en_US.UTF-8";
    LC_IDENTIFICATION = "en_US.UTF-8";
    LC_MEASUREMENT = "en_US.UTF-8";
    LC_MONETARY = "en_US.UTF-8";
    LC_NAME = "en_US.UTF-8";
    LC_NUMERIC = "en_US.UTF-8";
    LC_PAPER = "en_US.UTF-8";
    LC_TELEPHONE = "en_US.UTF-8";
    LC_TIME = "en_US.UTF-8";
  };

  # Nix Settings
  nix.settings = {
    # Enable flakes and new 'nix' command
    experimental-features = lib.mkDefault [
      "nix-command"
      "flakes"
    ];
    # Deduplicate and optimize nix store
    auto-optimise-store = lib.mkDefault true;
    # Allow sudo users to do dangerous nix things
    trusted-users = [
      "root"
      "@wheel"
    ];
  };
  nix.gc = {
    automatic = lib.mkDefault true;
    dates = lib.mkDefault "weekly";
    options = lib.mkDefault "--delete-older-than 14d";
  };

  # Allow unfree packages
  nixpkgs.config.allowUnfree = lib.mkDefault true;

  # Allow executing unpackaged binaries
  services.envfs.enable = lib.mkDefault true;
  programs.nix-ld.enable = lib.mkDefault true;
  programs.nix-ld.libraries = lib.mkDefault [
    pkgs.libiio
    pkgs.libevdev
    pkgs.udev
  ];

  # Configure keymap in X11
  services.xserver.xkb = lib.mkDefault {
    layout = "us";
    variant = "";
  };

  # Define a user account. Don't forget to set a password with ‘passwd’.
  users.users.gamer = lib.mkDefault {
    isNormalUser = true;
    description = "Gamer";
    initialPassword = "gamer";
    shell = pkgs.zsh;
    extraGroups = [
      "networkmanager"
      "wheel"
    ];
    packages = with pkgs; [
      fzf
    ];
  };

  # Audio
  security.rtkit.enable = lib.mkDefault true;
  services.pulseaudio.enable = lib.mkDefault false;
  services.pipewire = lib.mkDefault {
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

  # Graphics
  hardware.graphics = lib.mkDefault {
    enable = true;
    enable32Bit = true;
  };
  services.xserver.videoDrivers = lib.mkDefault [ "amdgpu" ];

  # Firmware
  services.fwupd.enable = lib.mkDefault true;

  # Display Manager
  services.xserver.enable = lib.mkDefault true;
  services.xserver.displayManager = {
    lightdm = {
      enable = lib.mkDefault true;
      greeter.enable = lib.mkDefault false;
    };
  };
  services.displayManager = {
    defaultSession = lib.mkDefault "opengamepadui";
    #defaultSession = "steam";
    autoLogin = {
      enable = lib.mkDefault true;
      user = lib.mkDefault "gamer";
    };
  };

  # Software

  # List packages installed in system profile. To search, run:
  # $ nix search wget
  environment.pathsToLink = lib.mkDefault [ "/share" ];
  environment.systemPackages = with pkgs; [
    appimage-run
    bc
    btop-rocm
    bubblewrap
    ccze
    curl
    distrobox
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
    legendary-gl
    legendary-heroic
    mangohud
    moonlight-qt
    nixos-facter
    pciutils
    pstree
    ryzenadj
    screen
    tree
    umu-launcher
    unzip
    usbutils
    vulkan-tools
    wget
    xorg.xprop
    xorg.xwininfo
    yq
    zip
  ];

  # Flatpak
  xdg.portal.config.common.default = lib.mkDefault "*";
  xdg.portal.wlr.enable = lib.mkDefault true;
  xdg.portal.enable = lib.mkDefault true;
  services.flatpak.enable = lib.mkDefault true;

  # Battery/Power
  services.upower = {
    enable = lib.mkDefault true;
  };

  # Bluetooth
  hardware.bluetooth.enable = lib.mkDefault true;
  hardware.bluetooth.powerOnBoot = lib.mkDefault true;

  # Editor
  programs.neovim = lib.mkDefault {
    enable = true;
    viAlias = true;
    vimAlias = true;
  };

  # Shell
  system.userActivationScripts.zshrc = "touch .zshrc";
  programs.zsh = lib.mkDefault {
    enable = true;
    enableCompletion = true;
    autosuggestions.enable = true;
    syntaxHighlighting.enable = true;
    ohMyZsh = {
      enable = true;
      plugins = [
        "git"
        "fzf"
      ];
      theme = "agnoster";
    };
    histSize = 10000000;
  };
  programs.fzf = lib.mkDefault {
    fuzzyCompletion = true;
    keybindings = true;
  };

  # Firefox
  programs.firefox.enable = lib.mkDefault true;

  # OpenGamepadUI
  programs.opengamepadui = {
    enable = lib.mkDefault true;
    inputplumber.enable = lib.mkDefault true;
    powerstation.enable = lib.mkDefault true;
    gamescopeSession.enable = lib.mkDefault true;
    gamescopeSession.env = {
      DBUS_FATAL_WARNINGS = "0";
      LOG_LEVEL = "debug";
    };
  };

  # Steam
  programs.steam.enable = lib.mkDefault true;
  programs.steam.remotePlay.openFirewall = lib.mkDefault true;
  programs.steam.localNetworkGameTransfers.openFirewall = lib.mkDefault true;
  #programs.steam.gamescopeSession.enable = true;
  programs.gamemode.enable = lib.mkDefault true;

  # Sunshine Streaming
  services.sunshine = {
    enable = true;
    autoStart = true;
    capSysAdmin = true;
    openFirewall = true;
  };

  # Enable the OpenSSH daemon.
  services.openssh.enable = lib.mkDefault true;

  # OS Updater script
  programs.os-updater.enable = lib.mkDefault true;
}
