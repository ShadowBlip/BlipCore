{
  description = "OS Flake";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs?ref=nixos-unstable";
    nixos-hardware.url = "github:nixos/nixos-hardware";
    nixos-facter-modules.url = "github:nix-community/nixos-facter-modules";
    lanzaboote = {
      url = "github:nix-community/lanzaboote/v0.4.3";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    chaotic.url = "github:chaotic-cx/nyx/nyxpkgs-unstable";
    rust-overlay.url = "github:oxalica/rust-overlay";
  };

  outputs =
    inputs@{ nixpkgs, rust-overlay, ... }:
    let
      system = "x86_64-linux";
      pkgs = import nixpkgs { inherit system; };
    in
    {

      nixosModules = rec {
        default = shadowblip;
        shadowblip = ./modules;
        nixos-hardware = inputs.nixos-hardware.nixosModules;
        nixos-facter = inputs.nixos-facter-modules.nixosModules.facter;
        lanzaboote = inputs.lanzaboote.nixosModules.lanzaboote;
        chaotic = inputs.chaotic.nixosModules.default;
      };

      packages."x86_64-linux" = {
        ayaneo-platform = pkgs.callPackage ./pkgs/by-name/ay/ayaneo-platform/package.nix {
          kernel = pkgs.linuxPackages_latest.kernel;
          #kernel = inputs.chaotic.legacyPackages.x86_64-linux.linuxPackages_cachyos.kernel;
        };
        gamepad-os-installer = pkgs.callPackage ./pkgs/by-name/ga/gamepad-os-installer/package.nix { };
        gamescope = pkgs.callPackage ./pkgs/by-name/ga/gamescope/package.nix { };
      };

      nixosConfigurations = {
        # Reference: https://haseebmajid.dev/posts/2024-02-04-how-to-create-a-custom-nixos-iso/
        iso = nixpkgs.lib.nixosSystem {
          modules = [
            # https://github.com/NixOS/nixpkgs/tree/master/nixos/modules/installer/cd-dvd
            "${nixpkgs}/nixos/modules/installer/cd-dvd/installation-cd-graphical-base.nix"
            "${nixpkgs}/nixos/modules/installer/cd-dvd/channel.nix"
            ./modules/installer/cd-dvd/installation-cd.nix
            ./modules/installer/cd-dvd/gamepad-os-installer.nix
            {
              nix.extraOptions = ''
                extra-substituters = https://shadowblip.cachix.org
                extra-trusted-public-keys = shadowblip.cachix.org-1:0Sdy0PePLXHFB7KFRfeycqJBGNdRNTLOmj7YY2UqebU=
              '';
            }
          ];
        };
      };

      devShells."x86_64-linux" = {
        # OpenGamepadUI Development Environment
        opengamepadui = import ./shells/opengamepadui.nix {
          system = "x86_64-linux";
          nixpkgs = nixpkgs;
          rust-overlay = rust-overlay;
        };
      };

    };
}
