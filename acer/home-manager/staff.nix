{
  inputs,
  outputs,
  lib,
  config,
  pkgs,
  ...
}: { 
    home.packages = with pkgs; [ 
      # ...
      # All of the below is for sway
    #   swaylock
    #   swayidle
      wl-clipboard
      mako
      alacritty
      wofi
      waybar
    ];
}