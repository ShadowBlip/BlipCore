{
  description = "OS Flake";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs?ref=nixos-unstable";
  };

  outputs =
    { self, nixpkgs }:
    {

      nixosModules = rec {
        default = shadowblip;
        shadowblip = ./modules;
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
