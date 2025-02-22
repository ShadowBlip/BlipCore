{
  description = "A very basic flake";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs?ref=nixos-unstable";
    # Local folder (if using an absolute path, the 'path:' prefix can be omitted).
    #custom-config = {
    #  url = "path:/etc/nixos-custom";
    #  flake = false;
    #};
  };

  outputs =
    { self, nixpkgs }:
    {

      # Please replace "nixos" with your hostname
      nixosConfigurations.nixos = nixpkgs.lib.nixosSystem {
        system = "x86_64-linux";
        modules = [
          # Import the previous configuration.nix we used,
          # so the old configuration file still takes effect
          ./configuration.nix
        ];
      };

    };
}
