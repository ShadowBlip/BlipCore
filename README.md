# OS Flake

This flake will configure your system to boot directly into OpenGamepadUI.

## Installation

### From the installer ISO

An installer ISO is available that will install NixOS and configure the OS
to use this git repository as its default configuration source:

[Download](https://gitlab.com/shadowapex/os-flake/-/packages/38791510)

**NOTE: This is still very alpha level, and will wipe the entire disk**

### From an existing NixOS installation

Alternatively, this flake can be used with an existing NixOS installation with the "flakes"
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

```bash
sudo nixos-rebuild switch
```

## Enabling Secure Boot

Secure Boot is supported via [Lanzaboote](https://github.com/nix-community/lanzaboote). You can enable it with the following steps:

1. Boot into your device firmware and configure Secure Boot for "Setup Mode"

```bash
sudo systemctl reboot --firmware-setup
```

2. Reboot into the OS to generate and enroll keys:

```bash
sudo sbctl create-keys
sudo sbctl enroll-keys --microsoft
sudo reboot
```

3. Boot into your device firmware and enable Secure Boot

## Updates

To update, run:

```bash
cd /etc/nixos/
sudo nix flake update
```

Then use `nixos-rebuild` to apply the latest updates:

```bash
sudo nixos-rebuild switch
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

## Building the installer ISO

You can build the installer ISO image using the `Makefile`:

```bash
make iso
```
