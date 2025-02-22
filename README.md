# OS Flake

Locally switch

```bash
sudo nixos-rebuild switch --flake /path/to/your/flake#your-hostname
```

Remotely switch

```bash
sudo nixos-rebuild switch --flake github:owner/repo#your-hostname
```

Using `--impure` may be necessary in order to import `/etc/nixos/hardware-configuration.nix`

* Maybe use disko instead of `/etc/nixos/hardware-configuration.nix`?
https://github.com/nix-community/disko

```bash
nixos-rebuild --target-host gamer@192.168.0.41 --use-remote-sudo --impure --flake .#nixos switch
```

# Updater

- Check repo for new release
- New release will run rebuild against branch?
