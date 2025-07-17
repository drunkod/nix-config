# vlenovo/modules/nixos/sxmo-utils/default.nix
{ lib, pkgs, config, ... }:

with lib;

let
  cfg = config.services.xserver.desktopManager.sxmo;
in

{
  options.services.xserver.desktopManager.sxmo = {
    enable = mkEnableOption "Sxmo (Simple X Mobile) session started via systemd";

    user = mkOption {
      description = lib.mdDoc "The user to run the Sxmo session for.";
      type = types.str;
    };

    group = mkOption {
      description = lib.mdDoc "The primary group for the Sxmo user.";
      type = types.str;
      default = "users";
    };
  };

  config = mkIf cfg.enable (
    let
      userConfig = config.users.users.${cfg.user};
      
      # Create a wrapped sway with all necessary configuration
      sway-wrapped = pkgs.sway.override { 
        withBaseWrapper = true; 
        withGtkWrapper = true; 
      };


      
      # Create the sxmo environment file with all necessary variables
      sxmo-environment-file = pkgs.writeText "sxmo-environment" ''
        # Let systemd handle USER, HOME, and XDG_RUNTIME_DIR.
        # We only need to provide the PATH and Sxmo-specific variables.
        
        PATH=${pkgs.sxmo-utils}/share/sxmo/default_hooks:${lib.makeBinPath [
          pkgs.sxmo-utils      # Provides all the sxmo_* scripts
          sway-wrapped         # Sway window manager
          pkgs.foot            # Default terminal for Wayland
          pkgs.bemenu          # Menu system
          pkgs.wvkbd           # Virtual keyboard for Wayland
          pkgs.grim            # Screenshot utility
          pkgs.slurp           # Screen area selection
          pkgs.wl-clipboard    # Wayland clipboard utilities
          
          # Core utilities required by sxmo scripts
          pkgs.coreutils 
          pkgs.gnugrep 
          pkgs.gnused
          pkgs.gawk
          pkgs.findutils
          pkgs.procps 
          pkgs.psmisc          # For killall
          pkgs.util-linux      # For various utilities
          pkgs.busybox         # For additional utilities
          pkgs.xdg-user-dirs
          
          # System services
          pkgs.dbus 
          pkgs.superd          # Service manager
          pkgs.networkmanager
          pkgs.modemmanager    # For modem functionality
          
          # Audio/video utilities
          pkgs.pamixer 
          pkgs.pipewire
          pkgs.pulseaudio
          
          # Power management
          pkgs.upower 
          pkgs.brightnessctl
          
          # Notification and UI utilities
          pkgs.libnotify 
          pkgs.dunst           # Notification daemon
          pkgs.inotify-tools
          pkgs.conky           # Desktop widget
          
          # Additional tools
          pkgs.jq              # JSON processor
          pkgs.curl            # HTTP client
          pkgs.vis             # Default editor
        ]}
        
        # We still need to set these XDG variables relative to the user's home.
        XDG_CONFIG_HOME=${userConfig.home}/.config
        XDG_DATA_HOME=${userConfig.home}/.local/share
        XDG_CACHE_HOME=${userConfig.home}/.cache
        XDG_STATE_HOME=${userConfig.home}/.local/state
        
        # Sxmo specific variables
        SXMO_WM=sway
        SXMO_TERMINAL=foot
        KEYBOARD=wvkbd-mobintl
        SXMO_DEVICE_NAME=desktop
        SXMO_OS=nixos
        
        # Wayland specific
        MOZ_ENABLE_WAYLAND=1
        SDL_VIDEODRIVER=wayland
        XDG_CURRENT_DESKTOP=sway
        XDG_SESSION_TYPE=wayland
        XDG_SESSION_DESKTOP=sway
        
        WLR_BACKENDS=drm
        WLR_RENDERER=gles2 
        WLR_RENDERER_ALLOW_SOFTWARE=1       
        
        SXMO_MENU=bemenu
        BEMENU_OPTS="--fn 'monospace 14'"
      '';
    in
    {
      # System configuration for sxmo
      services.logind.extraConfig = ''
        HandlePowerKey=ignore
        HandlePowerKeyLongPress=poweroff
      '';

      environment.etc."sway/config.d/00-nixos-output.conf".text = ''
        # Configure all outputs with a standard mode.
        output * bg #000000 solid_color
      '';
      
      systemd.defaultUnit = "graphical.target";
      
      # Install udev rules
      services.udev.packages = [ pkgs.sxmo-utils ];
      
      # Configure user groups
      users.users.${cfg.user}.extraGroups = [ 
        "input" 
        "video" 
        "audio" 
        "network" 
        "networkmanager"
        "power" 
        "wheel"
      ];
      
      # Enable doas with sxmo configuration
     security.doas.enable = lib.mkDefault true;
      security.doas.extraConfig = ''
        # Allow wheel group to run commands as root
        permit persist :wheel
        
        # Sxmo-specific doas rules will be included if the package provides them
        # The actual file check happens at runtime, not build time
      '';
      
      # Disable getty on tty7 to avoid conflicts
      systemd.services."getty@tty7".enable = false;

      # Create necessary directories
       systemd.tmpfiles.rules = [

         # User home directories
        "d ${userConfig.home}/.cache 0755 ${cfg.user} ${cfg.group} -"
        "d ${userConfig.home}/.cache/sxmo 0755 ${cfg.user} ${cfg.group} -"
        "d ${userConfig.home}/.config 0755 ${cfg.user} ${cfg.group} -"
         "d ${userConfig.home}/.config/sxmo 0755 ${cfg.user} ${cfg.group} -"
         "d ${userConfig.home}/.config/sxmo/hooks 0755 ${cfg.user} ${cfg.group} -"
        "d ${userConfig.home}/.local 0755 ${cfg.user} ${cfg.group} -"
        "d ${userConfig.home}/.local/share 0755 ${cfg.user} ${cfg.group} -"
        "d ${userConfig.home}/.local/share/sxmo 0755 ${cfg.user} ${cfg.group} -"
        "d ${userConfig.home}/.local/share/modem 0755 ${cfg.user} ${cfg.group} -"
        "d ${userConfig.home}/.local/state 0755 ${cfg.user} ${cfg.group} -"
       ];

      hardware.graphics.enable = lib.mkDefault true;

      # The main sxmo service
      systemd.services.sxmo = {
        description = "Sxmo graphical session";
        wantedBy = [ "graphical.target" ];
        conflicts = [ "getty@tty7.service" ];
        after = [ 
          "systemd-user-sessions.service" 
          "systemd-logind.service" 
          "network.target"
          "systemd-tmpfiles-setup.service"  # Ensure directories are created first
        ];
        
        # Create a pre-start script to ensure directories exist
        preStart = ''
          # Ensure user directories exist with correct permissions
          mkdir -p ${userConfig.home}/.cache/sxmo
          mkdir -p ${userConfig.home}/.config/sxmo/hooks
          mkdir -p ${userConfig.home}/.local/share/sxmo
          mkdir -p ${userConfig.home}/.local/share/modem
          mkdir -p ${userConfig.home}/.local/state
          
          # Fix ownership
          chown -R ${cfg.user}:${cfg.group} ${userConfig.home}/.cache
          chown -R ${cfg.user}:${cfg.group} ${userConfig.home}/.config
          chown -R ${cfg.user}:${cfg.group} ${userConfig.home}/.local
        '';
        
        serviceConfig = {
          Type = "simple";
 
          EnvironmentFile = sxmo-environment-file;
 
          ExecStart = ''
            ${pkgs.dbus}/bin/dbus-run-session ${pkgs.sxmo-utils}/bin/sxmo_winit.sh
          '';
          User = cfg.user;
          Group = cfg.group;
          PAMName = "login";
          WorkingDirectory = userConfig.home;
          Restart = "always";
          RestartSec = "2s";
          
          # TTY configuration
          TTYPath = "/dev/tty7";
          TTYReset = "yes";
          TTYVHangup = "yes";
          TTYVTDisallocate = "yes";
          StandardInput = "tty-fail";
          StandardOutput = "journal";
          StandardError = "journal";
          UtmpIdentifier = "tty7";
          UtmpMode = "user";
          
          # Capabilities
          AmbientCapabilities = "CAP_SYS_TTY_CONFIG";
          
          # Run the preStart script as root
          PermissionsStartOnly = true;
        };
      };

      # Install required packages system-wide
      environment.systemPackages = with pkgs; [
        sxmo-utils
        sway-wrapped
        foot
        bemenu
        wvkbd
        #dunst
        conky
        superd
        lisgd
        mnc
        vis           # Default editor
        jq            # Add explicitly
        inotify-tools # Add explicitly
        xdg-user-dirs        
      ];

      # Enable required services
      services.pipewire = {
        enable = true;
        alsa.enable = true;
        pulse.enable = true;
      };

      # ModemManager for cellular functionality
      # services.modemmanager.enable = true;

      # Enable geoclue for location services
      services.geoclue2.enable = true;
    }
  );
}