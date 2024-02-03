{
  pkgs,
  ...
}:
{

  xdg.portal = {
    enable = true;
    # wlr.enable = true;

    config = {
      common.default = ["wlr" "gtk"];
    #   hyprland.default = ["hyprland"];
    };
    extraPortals = with pkgs;  [
      xdg-desktop-portal-gtk
      xdg-desktop-portal-wlr
    #   xdg-desktop-portal-hyprland
    ];
  };
}