    
{
  inputs,
  outputs,
  lib,
  config,
  pkgs,
  ...
}: {    
    # Use sway desktop environment with Wayland display server
    wayland.windowManager.sway = {
      enable = true;
      # wrapperFeatures.gtk = true;
      # Sway-specific Configuration
      config = {
        terminal = "alacritty";
        menu = "wofi --show run";
        # Status bar(s)
        bars = [{
          fonts.size = 15.0;
          # command = "waybar"; You can change it if you want
          position = "bottom";
        }];
        modifier = "Mod4"; # Super key
        # Display device configuration
        output = {
          LVDS-1 = {
            # Set HIDP scale (pixel integer scaling)
            scale = "1";
            # mode = "1366x768@60.014Hz";
	      };
	    };
      };
      # End of Sway-specificc Configuration
    };

}