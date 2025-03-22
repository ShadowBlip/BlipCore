{
  config,
  pkgs,
  lib,
  ...
}:

let
  cfg = config.programs.os-updater;
  os-updater = pkgs.writeShellScriptBin "os-updater" ''
    set -eu

    if [[ $EUID -ne 0 ]]; then
      exec pkexec --disable-internal-agent "$0" "$@"
    fi

    help() {
      echo "Updater for a NixOS-based system using flakes"
      echo
      echo "Syntax: os-updater <command>"
      echo "commands:"
      echo "  help        Display this help message"
      echo "  update      Update the flake.lock file with the latest inputs"
      echo "  upgrade     Run 'nixos-rebuild switch'"
      echo "  has-update  Prints '0' if no updates are available"
      echo "  set-branch  Set the upstream branch to fetch updates from"
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
      diff /tmp/flake.lock flake.lock > /dev/null 2>&1
      echo $?
      rm -f /tmp/flake.lock
    }

    set_branch() {
      echo "Setting branch to: ${1}"
    }

    # Get the options
    case $1 in
      "help" | "-h" | "--help") # display help
        help
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
        set_branch $2
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
