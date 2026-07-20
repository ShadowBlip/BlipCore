{
  description = "OS Flake";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs?ref=nixos-unstable";
    nixpkgs-staging.url = "github:nixos/nixpkgs?ref=staging";
    nixos-hardware.url = "github:nixos/nixos-hardware";
    nixos-facter-modules.url = "github:nix-community/nixos-facter-modules";
    lanzaboote = {
      url = "github:nix-community/lanzaboote/v1.1.0";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    rust-overlay.url = "github:oxalica/rust-overlay";
    nix-cachyos-kernel.url = "github:xddxdd/nix-cachyos-kernel/release";
  };

  outputs =
    inputs@{
      self,
      nixpkgs,
      nixpkgs-staging,
      rust-overlay,
      ...
    }:

    let
      pkgs-x86_64 = nixpkgs.legacyPackages."x86_64-linux";
      pkgs-aarch64 = nixpkgs.legacyPackages."aarch64-linux";
    in
    {

      nixosModules = rec {
        default = shadowblip;
        shadowblip = ./modules;
        nixos-hardware = inputs.nixos-hardware.nixosModules;
        nixos-facter = inputs.nixos-facter-modules.nixosModules.facter;
        lanzaboote = inputs.lanzaboote.nixosModules.lanzaboote;
      };

      packages."x86_64-linux" = with pkgs-x86_64; {
        ayaneo-platform = callPackage ./pkgs/by-name/ay/ayaneo-platform/package.nix {
          kernel = inputs.nix-cachyos-kernel.legacyPackages.x86_64-linux.linux-cachyos-deckify;
        };
        gamepad-os-installer = callPackage ./pkgs/by-name/ga/gamepad-os-installer/package.nix { };
        gamescope = callPackage ./pkgs/by-name/ga/gamescope/package.nix { };

        # For packages that should be cross-compiled
        pkgsCross.aarch64-multiplatform = with pkgs-x86_64.pkgsCross.aarch64-multiplatform; {
          gamescope = callPackage ./pkgs/by-name/ga/gamescope/package.nix { };
          linux-armada = callPackage ./pkgs/by-name/li/linux-armada/package.nix { };
        };
      };
      packages."aarch64-linux" = with pkgs-aarch64; {
        gamescope = callPackage ./pkgs/by-name/ga/gamescope/package.nix { };
        linux-armada = callPackage ./pkgs/by-name/li/linux-armada/package.nix { };
      };

      nixosConfigurations = {
        # Reference: https://haseebmajid.dev/posts/2024-02-04-how-to-create-a-custom-nixos-iso/
        iso-x86_64 = nixpkgs.lib.nixosSystem {
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

        iso-aarch64 = pkgs-aarch64.nixos {
          imports = [
            ({ pkgs, ... }: {
              boot.kernelPackages = pkgs.linuxPackagesFor self.packages."aarch64-linux".linux-armada;
            })

            # https://github.com/NixOS/nixpkgs/tree/master/nixos/modules/installer/cd-dvd
            "${nixpkgs}/nixos/modules/installer/cd-dvd/installation-cd-graphical-base.nix"
            "${nixpkgs}/nixos/modules/installer/cd-dvd/channel.nix"
          ];
        };

        iso-aarch64-cross = pkgs-aarch64.nixos {
          imports = [
            ({ pkgs, ... }: {
              # the platform that performs the build step
              #nixpkgs.localSystem.system = "x86_64-linux";

              # the platform that will execute the resulting binaries
              # add this to enable cross-compilation.
              #nixpkgs.crossSystem = {
              #  config = "aarch64-unknown-linux-gnu";
              #  system = "aarch64-linux";
              #};

              # Tests are not happy for mypy, so use an overlay to disable them.
              #nixpkgs.overlays = [
              #  (final: prev: {
              #    pythonPackagesExtensions = prev.pythonPackagesExtensions ++ [
              #      (python-final: python-prev: {
              #        mypy = python-prev.mypy.overridePythonAttrs (oldAttrs: {
              #          doCheck = false;
              #        });
              #      })
              #    ];
              #  })
              #  (final: prev: {
              #    openblas = nixpkgs-staging.legacyPackages."aarch64-linux".openblas;
              #  })
              #];

              boot.kernelPackages =
                pkgs.linuxPackagesFor
                  self.packages."x86_64-linux".pkgsCross.aarch64-multiplatform.linux-armada;

              # NOTE: systemd will fail to build on non-staging branch
              # https://github.com/NixOS/nixpkgs/pull/540766
              #systemd.package = nixpkgs.legacyPackages."aarch64-linux".systemd.override {
              #  linuxHeaders = self.packages."aarch64-linux".linux-armada.dev;
              #  withLibBPF = false;
              #};

              #systemd.package =
              #  with nixpkgs.legacyPackages."aarch64-linux";
              #  systemd.overrideAttrs (old: {
              #    NIX_CFLAGS_COMPILE = (old.NIX_CFLAGS_COMPILE or [ ]) ++ [
              #      "-I${linuxHeaders}/include"
              #    ];
              #  });
            })

            # https://github.com/NixOS/nixpkgs/tree/master/nixos/modules/installer/cd-dvd
            "${nixpkgs}/nixos/modules/installer/cd-dvd/installation-cd-graphical-base.nix"
            "${nixpkgs}/nixos/modules/installer/cd-dvd/channel.nix"
          ];

        };

        sdcard = nixpkgs-staging.legacyPackages.x86_64-linux.pkgsCross.aarch64-multiplatform.nixos {
          imports = [
            ({ pkgs, ... }: {
              # the platform that performs the build step
              nixpkgs.localSystem.system = "x86_64-linux";

              # the platform that will execute the resulting binaries
              # add this to enable cross-compilation.
              nixpkgs.crossSystem = {
                config = "aarch64-unknown-linux-gnu";
                system = "aarch64-linux";
              };

              # Tests are not happy for mypy, so use an overlay to disable them.
              nixpkgs.overlays = [
                (final: prev: {
                  pythonPackagesExtensions = prev.pythonPackagesExtensions ++ [
                    (python-final: python-prev: {
                      mypy = python-prev.mypy.overridePythonAttrs (oldAttrs: {
                        doCheck = false;
                      });
                    })
                  ];
                })
              ];

              #nixpkgs.config.packageOverrides = pkgs: {
              #  python3Packages = pkgs.python3Packages.override {
              #    packageOverrides = pySelf: pySuper: {
              #      mypy = pySuper.mypy.overrideAttrs (oldAttrs: {
              #        doCheck = false;
              #      });
              #    };
              #  };
              #};

              boot.kernelPackages = pkgs.linuxPackagesFor self.packages."aarch64-linux".linux-armada;

              # NOTE: systemd will fail to build on non-staging branch
              # https://github.com/NixOS/nixpkgs/pull/540766
              #systemd.package = nixpkgs.legacyPackages."aarch64-linux".systemd.override {
              #  linuxHeaders = self.packages."aarch64-linux".linux-armada.dev;
              #  withLibBPF = false;
              #};

              #systemd.package =
              #  with nixpkgs.legacyPackages."aarch64-linux";
              #  systemd.overrideAttrs (old: {
              #    NIX_CFLAGS_COMPILE = (old.NIX_CFLAGS_COMPILE or [ ]) ++ [
              #      "-I${linuxHeaders}/include"
              #    ];
              #  });
            })
            "${nixpkgs-staging}/nixos/modules/installer/sd-card/sd-image-aarch64-installer.nix"

          ];
        };

        sdcard_old = nixpkgs-staging.lib.nixosSystem {
          system = "aarch64-linux";
          specialArgs = { inherit inputs; };
          modules = [
            {
              # the platform that performs the build step
              nixpkgs.localSystem.system = "x86_64-linux";

              # the platform that will execute the resulting binaries
              # add this to enable cross-compilation.
              nixpkgs.crossSystem = {
                config = "aarch64-unknown-linux-gnu";
                system = "aarch64-linux";
              };
            }
            # https://github.com/NixOS/nixpkgs/tree/master/nixos/modules/installer/sd-card
            "${nixpkgs-staging}/nixos/modules/installer/sd-card/sd-image-aarch64-installer.nix"
            {
              nix.extraOptions = ''
                extra-substituters = https://shadowblip.cachix.org
                extra-trusted-public-keys = shadowblip.cachix.org-1:0Sdy0PePLXHFB7KFRfeycqJBGNdRNTLOmj7YY2UqebU=
              '';
            }
            {
              boot.kernelPackages =
                nixpkgs-staging.legacyPackages."aarch64-linux".linuxPackagesFor
                  self.packages."aarch64-linux".linux-armada;

              # NOTE: systemd will fail to build on non-staging branch
              # https://github.com/NixOS/nixpkgs/pull/540766
              #systemd.package = nixpkgs.legacyPackages."aarch64-linux".systemd.override {
              #  linuxHeaders = self.packages."aarch64-linux".linux-armada.dev;
              #  withLibBPF = false;
              #};

              #systemd.package =
              #  with nixpkgs.legacyPackages."aarch64-linux";
              #  systemd.overrideAttrs (old: {
              #    NIX_CFLAGS_COMPILE = (old.NIX_CFLAGS_COMPILE or [ ]) ++ [
              #      "-I${linuxHeaders}/include"
              #    ];
              #  });
            }
          ];
        };

      };

      images = {
        iso-x86_64 = self.nixosConfigurations.iso-x86_64.config.system.build.isoImage;
        iso-aarch64 = self.nixosConfigurations.iso-aarch64.config.system.build.isoImage;
        iso-aarch64-cross = self.nixosConfigurations.iso-aarch64-cross.config.system.build.isoImage;
        sdcard = self.nixosConfigurations.sdcard.config.system.build.sdImage;
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
