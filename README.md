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

```bash
sudo nixos-rebuild switch
```

Then generate a hardware report with `nixos-facter`:

```bash
nix-shell -p nixos-facter --run "sudo nixos-facter -o /etc/nixos/facter.json"
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

## Testing

You can test building this flake configuration without switching to it with:

```bash
make test
```

This command will create a `result` symlink in the current directory with
the built OS configuration.

You can also simulate building the flake for a specific device by setting the
`DEVICE` variable and passing it the name of the device found in `./test/devices`:

```bash
make test DEVICE=oxp-mini
```

You can build the flake for _all_ supported images with:

```bash
make test-all
```

## Remote Updating

You can build this flake locally and push it to a remote device with:

```bash
make deploy SSH_HOST=x.x.x.x
```
