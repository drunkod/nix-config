  {
  pkgs,
  ...
}:

{
  # Hardware Support for Wayland Sway
  hardware = {
    opengl = {
      enable = true;
      driSupport = true;
    };
  };
  }