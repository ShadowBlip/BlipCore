{
  config,
  lib,
  pkgs,
  ...
}:

let
  cfg = config.programs.gamepad-os-installer;
  gamescopeCfg = config.programs.gamescope;

  gamepad-os-installer-gamescope =
    let
      exports = lib.mapAttrsToList (n: v: "export ${n}=${v}") cfg.gamescopeSession.env;
    in
    # Based on gamescope-session-plus from ChimeraOS
    pkgs.writeShellScriptBin "gamepad-os-installer-gamescope" ''
      ${builtins.concatStringsSep "\n" exports}

      gamescope_has_option() {
      	if (gamescope --help 2>&1 | grep -e "$1" > /dev/null); then
      		return 0
      	fi

      	return 1
      }

      # Device quirks from ChimeraOS gamescope-session-plus
      # https://github.com/ChimeraOS/gamescope-session/blob/main/usr/share/gamescope-session-plus/device-quirks
      SYS_ID="$(cat /sys/devices/virtual/dmi/id/product_name)"
      CPU_VENDOR="$(lscpu | grep "Vendor ID" | cut -d : -f 2 | xargs)"

      # OXP 60Hz Devices
      OXP_LIST="ONE XPLAYER:ONEXPLAYER 1 T08:ONEXPLAYER 1S A08:ONEXPLAYER 1S T08:ONEXPLAYER mini A07:ONEXPLAYER mini GA72:ONEXPLAYER mini GT72:ONEXPLAYER Mini Pro:ONEXPLAYER GUNDAM GA72:ONEXPLAYER 2 ARP23:ONEXPLAYER 2 PRO ARP23H:ONEXPLAYER 2 PRO ARP23P:ONEXPLAYER 2 PRO ARP23P EVA-01"
      AOK_LIST="AOKZOE A1 AR07:AOKZOE A1 Pro"
      if [[ ":$OXP_LIST:" =~ ":$SYS_ID:"  ]] || [[  ":$AOK_LIST:" =~ ":$SYS_ID:"   ]]; then
        DRM_MODE=fixed
        PANEL_TYPE=external
        ORIENTATION=left

        # Set refresh rate range and enable refresh rate switching
        export STEAM_DISPLAY_REFRESH_LIMITS=40,60
      fi

      # OXP 120Hz Devices
      OXP_120_LIST="ONEXPLAYER F1:ONEXPLAYER F1 EVA-01"
      if [[ ":$OXP_120_LIST:" =~ ":$SYS_ID:"  ]]; then
        PANEL_TYPE=external
        ORIENTATION=left

        # Set refresh rate range and enable refresh rate switching
        export STEAM_DISPLAY_REFRESH_LIMITS=40,120
      fi

      # OXP X1 Devices
      OXP_X1_LIST="ONEXPLAYER X1 A"
      if [[ ":$OXP_X1_LIST:" =~ ":$SYS_ID:"  ]]; then
        PANEL_TYPE=external
        ORIENTATION=left
        CUSTOM_REFRESH_RATES=60,120

        # Set refresh rate range and enable refresh rate switching
        export STEAM_DISPLAY_REFRESH_LIMITS=60,120
      fi

      # OXP X1 144Hz Devices
      OXP_X1_144_LIST="ONEXPLAYER X1 mini"
      if [[ ":$OXP_X1_144_LIST:" =~ ":$SYS_ID:"  ]]; then
        PANEL_TYPE=external
        ORIENTATION=left
        CUSTOM_REFRESH_RATES=60,144

        # Set refresh rate range and enable refresh rate switching
        export STEAM_DISPLAY_REFRESH_LIMITS=60,144
      fi

      # AYANEO AIR, SLIDE, and FLIP Keyboard Devices
      AIR_LIST="AIR:AIR Pro:AIR Plus:SLIDE:FLIP KB:"
      if [[ ":$AIR_LIST:" =~ ":$SYS_ID:"  ]]; then
        PANEL_TYPE=external
        ORIENTATION=left
      fi

      # AYANEO FLIP Dual Screen
      if [[ ":FLIP DS:" =~ ":$SYS_ID:" ]]; then
        PANEL_TYPE=external
        ORIENTATION=left
        OUTPUT_CONNECTOR='*,eDP-1,eDP-2' # prefer the top screen
      fi

      # AYN Loki Devices
      AYN_LIST="Loki Max:Loki Zero:Loki MiniPro"
      if [[ ":$AYN_LIST:" =~ ":$SYS_ID:"  ]]; then
        DRM_MODE=fixed
        ORIENTATION=left
        CUSTOM_REFRESH_RATES=40,50,60

        # Set refresh rate range and enable refresh rate switching
        export STEAM_DISPLAY_REFRESH_LIMITS=40,60
      fi

      # GDP Win devices
      GDP_LIST="G1619-01:G1621-02:MicroPC:WIN2"
      if [[ ":$GDP_LIST:" =~ ":$SYS_ID:"  ]]; then
        OUTPUT_CONNECTOR='*,DSI-1'
        DRM_MODE=fixed
        ORIENTATION=right
      fi

      # GPD Win 3 specifc quirk to prevent crashing
        # The GPD Win 3 does not support hardware rotation for 270/90 modes. We need to implement shader rotations to get this working correctly.
        # 0/180 rotations should work.
      if [[ ":G1618-03:" =~ ":$SYS_ID:"  ]]; then
        OUTPUT_CONNECTOR='*,DSI-1'
        DRM_MODE=fixed
        ORIENTATION=right
      fi

      #GPD Win 4 supports 40-60hz refresh rate changing
      if [[ ":G1618-04:" =~ ":$SYS_ID:"  ]]; then
        CUSTOM_REFRESH_RATES=40,60
        export STEAM_DISPLAY_REFRESH_LIMITS=40,60
      fi

      # GPD Win Max 2 supports 40,60hz
      if [[ ":G1619-04:" =~ ":$SYS_ID:"  ]]; then
        CUSTOM_REFRESH_RATES=40,60
        export STEAM_DISPLAY_REFRESH_LIMITS=40,60
      fi

      # GPD Win mini
      if [[ ":G1617-01:" =~ ":$SYS_ID:"  ]]; then
        ORIENTATION=""
        if ( xrandr --prop 2>$1 | grep -e "1080x1920 " > /dev/null ) ; then
           ORIENTATION=right
        fi
      fi

      # Steam Deck (Common)
      if [[ ":Jupiter:Galileo:" =~ ":$SYS_ID:" ]]; then
        DRM_MODE=fixed
      fi

      # Steam Deck (LCD)
      if [[ ":Jupiter:" =~ ":$SYS_ID:" ]]; then
        export STEAM_DISPLAY_REFRESH_LIMITS=40,60
      fi

      # Steam Deck (OLED)
      if [[ ":Galileo:" =~ ":$SYS_ID:" ]]; then
        export STEAM_DISPLAY_REFRESH_LIMITS=45,90

        export STEAM_GAMESCOPE_FORCE_HDR_DEFAULT=1
        export STEAM_GAMESCOPE_FORCE_OUTPUT_TO_HDR10PQ_DEFAULT=1
        export STEAM_ENABLE_STATUS_LED_BRIGHTNESS=1

      fi

      # ROG Ally & ROG Ally X
      ALLY_LIST="ROG Ally RC71L_RC71L:ROG Ally RC71L:ROG Ally X RC72LA"
      if [[ ":$ALLY_LIST:" =~ ":$SYS_ID:"  ]]; then
        PANEL_TYPE=external
        ADAPTIVE_SYNC=1

        # Set refresh rate range and enable refresh rate switching
        export STEAM_DISPLAY_REFRESH_LIMITS=40,120
      fi

      # Lenovo Legion Go
      if [[ ":83E1:" =~ ":$SYS_ID:"  ]]; then
        ORIENTATION=left
        CUSTOM_REFRESH_RATES=60,144

        # Set refresh rate range and enable refresh rate switching
        export STEAM_DISPLAY_REFRESH_LIMITS=60,144
      fi

      # Minisforum V3
      if [[ ":V3:" =~ ":$SYS_ID:"  ]]; then
        PANEL_TYPE=external
        ADAPTIVE_SYNC=1

        # Set refresh rate range and enable refresh rate switching
        export STEAM_DISPLAY_REFRESH_LIMITS=36,165
      fi

      # XG mobile for ASUS laptops that supports the proprietary connector
      xg_mobile_file_path="/sys/devices/virtual/firmware-attributes/asus-armoury/attributes/egpu_enable/current_value"
      if [ -f "$xg_mobile_file_path" ]; then
        egpu_status=$(<"$xg_mobile_file_path")
        if [[ "$egpu_status" -ne 0 ]]; then
          unset STEAM_DISPLAY_REFRESH_LIMITS

          # XG Mobile 2023: NVIDIA 4090
          if lspci -nn | grep -Fq "10de:2717"; then
            export VULKAN_ADAPTER="10de:2717"
          fi

          # XG Mobile 2022: AMD RX 6850xt
          if lspci -nn | grep -Fq "1002:73df"; then
            export VULKAN_ADAPTER="1002:73df"
          fi

          # XG Mobile 2021: NVIDIA 3080
          if lspci -nn | grep -q "10de:249c"; then
            export VULKAN_ADAPTER="1002:249c"
          fi
        fi
      fi

      # Plop GAMESCOPE_MODE_SAVE_FILE into $XDG_CONFIG_HOME (defaults to ~/.config).
      export GAMESCOPE_MODE_SAVE_FILE="''${XDG_CONFIG_HOME:-$HOME/.config}/gamescope/modes.cfg"
      export GAMESCOPE_PATCHED_EDID_FILE="''${XDG_CONFIG_HOME:-$HOME/.config}/gamescope/edid.bin"

      # Make path to gamescope mode save file.
      mkdir -p "$(dirname "$GAMESCOPE_MODE_SAVE_FILE")"
      touch "$GAMESCOPE_MODE_SAVE_FILE"

      # Make path to Gamescope edid patched file.
      mkdir -p "$(dirname "$GAMESCOPE_PATCHED_EDID_FILE")"
      touch "$GAMESCOPE_PATCHED_EDID_FILE"

      # Prepare our initial VRS config file
      # for dynamic VRS in Mesa.
      export RADV_FORCE_VRS_CONFIG_FILE=$(mktemp /tmp/radv_vrs.XXXXXXXX)
      mkdir -p "$(dirname "$RADV_FORCE_VRS_CONFIG_FILE")"
      echo "1x1" >"$RADV_FORCE_VRS_CONFIG_FILE"

      # To play nice with the short term callback-based limiter for now
      export GAMESCOPE_LIMITER_FILE=$(mktemp /tmp/gamescope-limiter.XXXXXXXX)

      ulimit -n 524288

      # Setup socket for gamescope
      # Create run directory file for startup and stats sockets
      tmpdir="$([[ -n ''${XDG_RUNTIME_DIR+x} ]] && mktemp -p "$XDG_RUNTIME_DIR" -d -t gamescope.XXXXXXX)"
      socket="''${tmpdir:+$tmpdir/startup.socket}"
      stats="''${tmpdir:+$tmpdir/stats.pipe}"

      # Fail early if we don't have a proper runtime directory setup
      if [[ -z $tmpdir || -z ''${XDG_RUNTIME_DIR+x} ]]; then
        echo >&2 "!! Failed to find run directory in which to create stats session sockets (is \$XDG_RUNTIME_DIR set?)"
        exit 0
      fi

      export GAMESCOPE_STATS="$stats"
      mkfifo -- "$stats"
      mkfifo -- "$socket"

      # Build the gamescope command
      ORIENTATION_OPTION=""
      if [ -n "$ORIENTATION" ] ; then
      	ORIENTATION_OPTION="--force-orientation $ORIENTATION"
      fi

      DRM_MODE_OPTION=""
      if [ -n "$DRM_MODE" ]; then
      	DRM_MODE_OPTION="--generate-drm-mode $DRM_MODE"
      fi

      ADAPTIVE_SYNC_OPTION=""
      if [ -n "$ADAPTIVE_SYNC" ]; then
      	ADAPTIVE_SYNC_OPTION="--adaptive-sync"
      fi

      PANEL_TYPE_OPTION=""
      if [ -n "$PANEL_TYPE" ] && gamescope_has_option "--force-panel-type"; then
      	PANEL_TYPE_OPTION="--force-panel-type $PANEL_TYPE"
      fi

      CUSTOM_REFRESH_RATES_OPTION=""
      if [ -n "$CUSTOM_REFRESH_RATES" ] && gamescope_has_option "--custom-refresh-rates"; then
      	CUSTOM_REFRESH_RATES_OPTION="--custom-refresh-rates $CUSTOM_REFRESH_RATES"
      fi

      GAMESCOPECMD="gamescope \
        ${lib.escapeShellArgs cfg.gamescopeSession.args} \
      	$ORIENTATION_OPTION \
      	$DRM_MODE_OPTION \
      	$ADAPTIVE_SYNC_OPTION \
      	$PANEL_TYPE_OPTION \
      	$CUSTOM_REFRESH_RATES_OPTION \
      	$BACKEND_OPTION \
      	$HDR_OPTIONS"

      # Add socket and stats read
      GAMESCOPECMD+=" -R $socket -T $stats"

      # Add custom vulkan adapter if specified
      if [ -n "$VULKAN_ADAPTER" ]; then
      	GAMESCOPECMD+=" --prefer-vk-device $VULKAN_ADAPTER"
      fi

      # Start gamescope compositor, log it's output and background it
      echo "$GAMESCOPECMD" >"$HOME"/.gamescope-cmd.log
      $GAMESCOPECMD >"$HOME"/.gamescope-stdout.log 2>&1 &
      gamescope_pid="$!"

      if read -r -t 3 response_x_display response_wl_display <>"$socket"; then
        export DISPLAY="$response_x_display"
        export GAMESCOPE_WAYLAND_DISPLAY="$response_wl_display"
        # We're done!
      else
        echo "gamescope failed"
        kill -9 "$gamescope_pid"
        wait -n "$gamescope_pid"
        exit 1
        # Systemd or Session manager will have to restart session
      fi

      # Start the installer
      gamepad-os-installer ${lib.escapeShellArgs cfg.args}

      # When the client exits, kill gamescope nicely
      kill $gamescope_pid
    '';

  gamescopeSessionFile =
    (pkgs.writeTextDir "share/wayland-sessions/gamepad-os-installer.desktop" ''
      [Desktop Entry]
      Name=gamepad-os-installer
      Comment=gamepad-os-installer Session
      Exec=${gamepad-os-installer-gamescope}/bin/gamepad-os-installer-gamescope
      Type=Application
    '').overrideAttrs
      (_: {
        passthru.providedSessions = [ "gamepad-os-installer" ];
      });
in
{
  options.programs.gamepad-os-installer = {
    enable = lib.mkEnableOption "gamepad-os-installer";

    args = lib.mkOption {
      type = lib.types.listOf lib.types.str;
      default = [ ];
      description = ''
        Arguments to be passed to installer
      '';
    };

    package = lib.mkPackageOption pkgs "gamepad-os-installer" {
      default = [ "gamepad-os-installer" ];
    };

    extraPackages = lib.mkOption {
      type = lib.types.listOf lib.types.package;
      default = [ ];
      example = lib.literalExpression ''
        with pkgs; [
          gamescope
        ]
      '';
      description = ''
        Additional packages to add to the installer environment.
      '';
    };

    fontPackages = lib.mkOption {
      type = lib.types.listOf lib.types.package;
      default = config.fonts.packages;
      defaultText = lib.literalExpression "builtins.filter lib.types.package.check config.fonts.packages";
      example = lib.literalExpression "with pkgs; [ source-han-sans ]";
      description = ''
        Font packages to use in the installer.

        Defaults to system fonts, but could be overridden to use other fonts — useful for users who would like to customize CJK fonts used in the installer.
      '';
    };

    gamescopeSession = lib.mkOption {
      description = "Run a GameScope driven installer session from your display-manager";
      default = { };
      type = lib.types.submodule {
        options = {
          enable = lib.mkEnableOption "GameScope Session";
          args = lib.mkOption {
            type = lib.types.listOf lib.types.str;
            default = [
              "--prefer-output"
              "*,eDP-1"
              "--default-touch-mode"
              "4"
              "--hide-cursor-delay"
              "3000"
              "--fade-out-duration"
              "200"
            ];
            description = ''
              Arguments to be passed to GameScope for the session.
            '';
          };

          env = lib.mkOption {
            type = lib.types.attrsOf lib.types.str;
            default = { };
            description = ''
              Environmental variables to be passed to GameScope for the session.
            '';
          };
        };
      };
    };
  };

  config = lib.mkIf cfg.enable {
    hardware.graphics = {
      # this fixes the "glXChooseVisual failed" bug, context: https://github.com/NixOS/nixpkgs/issues/47932
      enable = true;
      enable32Bit = pkgs.stdenv.hostPlatform.isx86_64;
    };

    security.wrappers = lib.mkIf (cfg.gamescopeSession.enable && gamescopeCfg.capSysNice) {
      # needed or steam plugin fails
      bwrap = {
        owner = "root";
        group = "root";
        source = lib.getExe pkgs.bubblewrap;
        setuid = true;
      };
    };

    programs.gamepad-os-installer.extraPackages = cfg.fontPackages;

    programs.gamescope.enable = true;
    services.displayManager.sessionPackages = lib.mkIf cfg.gamescopeSession.enable [
      gamescopeSessionFile
    ];

    programs.gamepad-os-installer.gamescopeSession.env = {
      # Fix intel color corruption
      # might come with some performance degradation but is better than a corrupted
      # color image
      INTEL_DEBUG = "norbc";
      mesa_glthread = "true";
      # This should be used by default by gamescope. Cannot hurt to force it anyway.
      # Reported better framelimiting with this enabled
      ENABLE_GAMESCOPE_WSI = "1";
      # Force Qt applications to run under xwayland
      QT_QPA_PLATFORM = "xcb";
      # Some environment variables by default (taken from Deck session)
      SDL_VIDEO_MINIMIZE_ON_FOCUS_LOSS = "0";
      # There is no way to set a color space for an NV12
      # buffer in Wayland. And the color management protocol that is
      # meant to let this happen is missing the color range...
      # So just workaround this with an ENV var that Remote Play Together
      # and Gamescope will use for now.
      GAMESCOPE_NV12_COLORSPACE = "k_EStreamColorspace_BT601";
      # Workaround older versions of vkd3d-proton setting this
      # too low (desc.BufferCount), resulting in symptoms that are potentially like
      # swapchain starvation.
      VKD3D_SWAPCHAIN_LATENCY_FRAMES = "3";
      # To expose vram info from radv
      WINEDLLOVERRIDES = "dxgi=n";
      # Don't wait for buffers to idle on the client side before sending them to gamescope
      vk_xwayland_wait_ready = "false";
      # Temporary crutch until dummy plane interactions / etc are figured out
      GAMESCOPE_DISABLE_ASYNC_FLIPS = "1";
    };

    # optionally enable 32bit pulseaudio support if pulseaudio is enabled
    services.pulseaudio.support32Bit = config.services.pulseaudio.enable;
    services.pipewire.alsa.support32Bit = config.services.pipewire.alsa.enable;

    hardware.steam-hardware.enable = true;

    environment.pathsToLink = [ "/share" ];

    environment.systemPackages = [
      cfg.package
    ] ++ lib.optional cfg.gamescopeSession.enable gamepad-os-installer-gamescope;
  };

  meta.maintainers = with lib.maintainers; [ shadowapex ];
}
