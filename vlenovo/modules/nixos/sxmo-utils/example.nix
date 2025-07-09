{ config, pkgs, ... }:

let
  defaultUserName = "alex";
  
in

{


  imports = [ ./module.nix ];
  nixpkgs.overlays = [ (import ./overlay.nix) ];

  users.users."${defaultUserName}" = {
    isNormalUser = true;
    initialPassword = "1234";
    extraGroups = [ "networkmanager" "wheel" ];
  };

  services.xserver.desktopManager.sxmo = {
    enable = true;
    user = defaultUserName;
    group = "users";
  };

  networking.useDHCP = false;
  networking.wireless.enable = false;
  networking.networkmanager.enable = true;

  fonts.packages = with pkgs; [
      noto-fonts
      noto-fonts-emoji
      nerd-fonts.fira-code
    ];

  fonts.fontconfig = {
    defaultFonts = {
      serif = [ "Noto Serif" ];
      sansSerif = [ "Noto Sans" ];
      monospace = [ "Fira Code Nerd Font" ];
    };
  };
}
