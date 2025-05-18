{
  config,
  pkgs,
  lib,
  ...
}:

let
  cfg = config.programs.os-updater;
  os-updater = pkgs.writeShellScriptBin "os-updater" ''
    set -e

    if [[ $EUID -ne 0 ]]; then
      exec pkexec --disable-internal-agent "$0" "$@"
    fi

    help() {
      echo "Updater for a NixOS-based system using flakes"
      echo
      echo "Syntax: os-updater <command>"
      echo "commands:"
      echo "  help              Display this help message"
      echo "  update            Update the flake.lock file with the latest inputs"
      echo "  upgrade           Run 'nixos-rebuild switch'"
      echo "  has-update        Prints '0' if no updates are available"
      echo "  list-branches     List available branches from upstream"
      echo "  set-branch <name> Set the upstream branch to fetch updates from"
      echo "  list-generations  List rollback generations in JSON format"
      echo "  gc                Purge rollback generations"
      echo "  rollback [gen]    Rollback to the given generation version"
      echo
    }

    update() {
      cd /etc/nixos
      nix flake update
    }

    upgrade() {
      nixos-rebuild switch
    }

    check_for_update() {
      cd /etc/nixos
      nix flake update --output-lock-file /tmp/flake.lock
      set +e
      diff /tmp/flake.lock flake.lock > /dev/null 2>&1
      echo $?
      rm -f /tmp/flake.lock
      set -e
    }

    list_branches() {
      git ls-remote --heads https://gitlab.com/shadowapex/os-flake.git | awk '{print $2}' | sed 's|refs/heads/||g'
    }

    set_branch() {
      echo "Setting branch to: $1"
      sed -i "s|gitlab:shadowapex/os-flake?ref=.*\"|gitlab:shadowapex/os-flake?ref=$1\"|g" /etc/nixos/flake.nix
    }

    garbage_collect() {
      nix-collect-garbage -d
    }

    list_generations() {
      #nix profile history --profile /nix/var/nix/profiles/system
      nixos-rebuild list-generations --json
    }

    rollback() {
      if [[ "$1" == "" ]]; then
        echo "Rolling to generation: $1"
        nix-env --switch-generation "$1" -p /nix/var/nix/profiles/system
        /nix/var/nix/profiles/system/bin/switch-to-configuration switch
      else
        echo "Rolling back to previous generation"
        nixos-rebuild switch --rollback
      fi
    }

    # Get the options
    case "$1" in
      "help" | "-h" | "--help") # display help
        help
        ;;
      "rollback")
        rollback "$2"
        ;;
      "gc")
        garbage_collect
        ;;
      "list-generations")
        list_generations
        ;;
      "update")
        update
        ;;
      "upgrade")
        upgrade
        ;;
      "has-update")
        check_for_update
        ;;
      "set-branch")
        if [[ "$2" == "" ]]; then
          help
          exit 1
        fi
        set_branch "$2"
        ;;
      "list-branches")
        list_branches
        ;;
      *) # Invalid command
        echo "Error: Invalid command"
        help
        ;;
    esac
  '';
in

{
  options.programs.os-updater = {
    enable = lib.mkEnableOption "os-updater";
  };

  config = lib.mkIf cfg.enable {
    environment.systemPackages = [
      os-updater
    ];
  };
}
