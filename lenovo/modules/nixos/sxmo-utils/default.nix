{ lib, pkgs, config, ... }:

with lib;

let
  cfg = config.services.xserver.desktopManager.sxmo;
  sxmopkgs = import ./default.nix { inherit pkgs; };
  # codemadness-frontends = pkgs.callPackage ./pkgs/codemadness-frontends {};
in

{
  # environment.systemPackages = [
  #   codemadness-frontends
  # ];

  options.services.xserver.desktopManager.sxmo = {
    enable = mkEnableOption "Simple X Mobile";

    user = mkOption {
      description = lib.mdDoc "The user to run the Sxmo service.";
      type = types.str;
      example = "alice";
    };

    group = mkOption {
      description = lib.mdDoc "The group to run the Sxmo service.";
      type = types.str;
      example = "users";
    };
  };

  config = mkIf cfg.enable {
    services.logind.extraConfig = ''
      HandlePowerKey=ignore
      HandlePowerKeyLongPress=poweroff
    '';

    systemd.defaultUnit = "graphical.target";

    services.udev.packages = [ sxmopkgs.sxmo-utils ];
    users.users.${cfg.user}.extraGroups = [ "input" "video" ];
    security.doas.enable = lib.mkDefault true;
    security.doas.extraConfig = builtins.readFile "${sxmopkgs.sxmo-utils}/etc/doas.d/sxmo.conf";

    # Megapixels requires this, and bemenu is much more fluent with this
    hardware.opengl.enable = lib.mkDefault true;

    systemd.services.sxmo = {
      wantedBy = [ "graphical.target" ];
      serviceConfig = {
        ExecStartPre = "+${sxmopkgs.sxmo-utils}/bin/sxmo_setpermissions.sh";
        ExecStart = "${sxmopkgs.sxmo-utils}/bin/sxmo_winit.sh";
        User = cfg.user;
        Group = cfg.group;
        PAMName = "login";
        WorkingDirectory = "~";
        Restart = "always";
        TTYPath = "/dev/tty7";
        TTYReset = "yes";
        TTYVHangup = "yes";
        TTYVTDisallocate = "yes";
        StandardInput = "tty-fail";
        StandardOutput = "journal";
        StandardError = "journal";
        UtmpIdentifier = "tty7";
        UtmpMode = "user";
      };
    };
  };
}
