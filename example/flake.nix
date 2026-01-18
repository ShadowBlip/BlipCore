{
  description = "A very basic flake";

  inputs = {
    shadowblip.url = "github:shadowblip/blipcore?ref=main";
  };

  outputs =
    inputs@{
      self,
      shadowblip,
    }:
    {

      # Please replace "nixos" with your hostname
      nixosConfigurations.nixos = shadowblip.inputs.nixpkgs.lib.nixosSystem {
        system = "x86_64-linux";
        # Allows `inputs` to be used in configuration
        specialArgs = { inherit inputs; };
        modules = [
          shadowblip.nixosModules.default
          ./configuration.nix
        ];
      };

    };
}
