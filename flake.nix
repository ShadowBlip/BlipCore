{
  description = "OS Flake";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs?ref=nixos-unstable";
    nixpkgs-1e5b65.url = "github:nixos/nixpkgs?ref=1e5b653dff12029333a6546c11e108ede13052eb";
    nixos-hardware.url = "github:nixos/nixos-hardware";
    nixos-facter-modules.url = "github:nix-community/nixos-facter-modules";
  };

  outputs =
    inputs@{ nixpkgs, ... }:
    {

      nixosModules = rec {
        default = shadowblip;
        shadowblip = ./modules;
        nixos-hardware = inputs.nixos-hardware.nixosModules;
        nixos-facter = inputs.nixos-facter-modules.nixosModules.facter;
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
          ];
        };
      };

    };
}
