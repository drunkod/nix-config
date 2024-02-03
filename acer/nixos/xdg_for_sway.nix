{
  pkgs,
  ...
}:
{
xdg = {
    portal = {
      enable = true;
    config = {  
      extraPortals = with pkgs; [
        xdg-desktop-portal-wlr
        xdg-desktop-portal-gtk
      ];
      };
    };
  };

}