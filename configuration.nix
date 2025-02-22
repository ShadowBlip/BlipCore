# Edit this configuration file to define what should be installed on
# your system.  Help is available in the configuration.nix(5) man page
# and in the NixOS manual (accessible by running ‘nixos-help’).

{ pkgs, ... }:

{
  imports = [
    # Include the results of the hardware scan.
    ./hardware-configuration.nix
  ];

  # Bootloader.
  boot.loader.efi.canTouchEfiVariables = true;
  boot.loader.systemd-boot.enable = true;
  boot.loader.systemd-boot.configurationLimit = 10;

  # Plymouth
  boot.consoleLogLevel = 0;
  boot.initrd.verbose = false;
  boot.loader.timeout = 0;
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

  # Kernel
  boot.kernelPackages = pkgs.linuxPackages_latest;
  boot.kernelParams = [
    "quiet"
    "splash"
    "boot.shell_on_fail"
    "loglevel=3"
    "rd.systemd.show_status=false"
    "rd.udev.log_level=3"
    "udev.log_priority=3"
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

  # Networking
  networking.hostName = "nixos"; # Define your hostname.
  # networking.wireless.enable = true;  # Enables wireless support via wpa_supplicant.

  # Configure network proxy if necessary
  # networking.proxy.default = "http://user:password@proxy:port/";
  # networking.proxy.noProxy = "127.0.0.1,localhost,internal.domain";

  # Enable networking
  networking.networkmanager.enable = true;
  services.avahi.enable = true;
  services.avahi.nssmdns4 = true;

  # Set your time zone.
  time.timeZone = "America/Los_Angeles";

  # Select internationalisation properties.
  i18n.defaultLocale = "en_US.UTF-8";

  i18n.extraLocaleSettings = {
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
    experimental-features = [
      "nix-command"
      "flakes"
    ];
    # Deduplicate and optimize nix store
    auto-optimise-store = true;
    # Allow sudo users to do dangerous nix things
    trusted-users = [
      "root"
      "@wheel"
    ];
  };
  nix.gc = {
    automatic = true;
    dates = "weekly";
  };

  # Allow unfree packages
  nixpkgs.config.allowUnfree = true;

  # Allow executing unpackaged binaries
  services.envfs.enable = true;
  programs.nix-ld.enable = true;
  programs.nix-ld.libraries = with pkgs; [
    libiio
    libevdev
    udev
  ];

  # Configure keymap in X11
  services.xserver.xkb = {
    layout = "us";
    variant = "";
  };

  # Define a user account. Don't forget to set a password with ‘passwd’.
  users.users.gamer = {
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

  # Graphics
  hardware.graphics = {
    enable = true;
    enable32Bit = true;
  };
  services.xserver.videoDrivers = [ "amdgpu" ];

  # Firmware
  services.fwupd.enable = true;

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
    #defaultSession = "steam";
    autoLogin = {
      enable = true;
      user = "gamer";
    };
  };

  # Software

  # List packages installed in system profile. To search, run:
  # $ nix search wget
  environment.pathsToLink = [ "/share" ];
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
    mangohud
    pciutils
    pstree
    ryzenadj
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

  # Flatpak
  xdg.portal.config.common.default = "*";
  xdg.portal.wlr.enable = true;
  xdg.portal.enable = true;
  services.flatpak.enable = true;

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

  # Shell
  programs.zsh = {
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
  programs.fzf = {
    fuzzyCompletion = true;
    keybindings = true;
  };

  # Firefox
  programs.firefox.enable = true;

  # OpenGamepadUI
  programs.opengamepadui = {
    enable = true;
    inputplumber.enable = true;
    powerstation.enable = true;
    package = (
      pkgs.opengamepadui.override {
        withDebug = true;
      }
    );
    args = [
      "--remote-debug"
      "tcp://192.168.0.13:6007"
    ];
    gamescopeSession.enable = true;
    gamescopeSession.env = {
      DBUS_FATAL_WARNINGS = "0";
      LOG_LEVEL = "debug";
    };
  };

  # Steam
  programs.steam.enable = true;
  programs.steam.remotePlay.openFirewall = true;
  programs.steam.localNetworkGameTransfers.openFirewall = true;
  #programs.steam.gamescopeSession.enable = true;
  programs.gamemode.enable = true;

  # Enable the OpenSSH daemon.
  services.openssh.enable = true;

  # This value determines the NixOS release from which the default
  # settings for stateful data, like file locations and database versions
  # on your system were taken. It‘s perfectly fine and recommended to leave
  # this value at the release version of the first install of this system.
  # Before changing this value read the documentation for this option
  # (e.g. man configuration.nix or on https://nixos.org/nixos/options.html).
  system.stateVersion = "24.05"; # Did you read the comment?
}
