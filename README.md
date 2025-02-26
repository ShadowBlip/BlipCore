# OS Flake

This flake will configure your system to boot directly into OpenGamepadUI.

## Requirements

Currently this flake requires NixOS to already be installed and the "flakes"
feature enabled.

To enable flakes on your system, add the following to your `/etc/nixos/configuration.nix`:

```
nix.settings.experimental-features = [ "nix-command" "flakes" ];
```

Then enable it with:

```
sudo nixos-rebuild switch
```

## Usage

Add the following to: `/etc/nixos/flake.nix`:

```
{
  description = "A very basic flake";

  inputs = {
    shadowblip.url = "gitlab:shadowapex/os-flake?ref=main";
  };

  outputs =
    inputs@{
      self,
      shadowblip,
    }:
    {

      # You can replace "nixos" with your hostname
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
```

Then enable it with:

```
sudo nixos-rebuild switch
```

## Updates

To update, run:

```
cd /etc/nixos/
sudo nix flake update
```

## Customization

You can customize your installation like any other NixOS system by editing
`/etc/nixos/configuration.nix` and running `sudo nixos-rebuild switch`.
