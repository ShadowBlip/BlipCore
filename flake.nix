{
  description = "OS Flake";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs?ref=nixos-unstable-small";
    nixos-hardware.url = "github:nixos/nixos-hardware";
    nixos-facter-modules.url = "github:nix-community/nixos-facter-modules";
    lanzaboote = {
      url = "github:nix-community/lanzaboote/v0.4.3";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    rust-overlay.url = "github:oxalica/rust-overlay";
    nix-cachyos-kernel.url = "github:xddxdd/nix-cachyos-kernel/release";
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
      };

      packages."x86_64-linux" = {
        ayaneo-platform = pkgs.callPackage ./pkgs/by-name/ay/ayaneo-platform/package.nix {
          kernel = inputs.nix-cachyos-kernel.legacyPackages.x86_64-linux.linux-cachyos-deckify;
        };
        gamepad-os-installer = pkgs.callPackage ./pkgs/by-name/ga/gamepad-os-installer/package.nix { };
        gamescope = pkgs.callPackage ./pkgs/by-name/ga/gamescope/package.nix { };
      };

      nixosConfigurations = {
        # Reference: https://haseebmajid.dev/posts/2024-02-04-how-to-create-a-custom-nixos-iso/
        iso = nixpkgs.lib.nixosSystem {
          specialArgs = { inherit inputs; };
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
