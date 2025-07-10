# This file defines overlays
{inputs, ...}: {
  # This one brings our custom packages from the 'pkgs' directory
  additions = final: _prev: import ../pkgs {pkgs = final;};

  # This one contains whatever you want to overlay
  # You can change versions, add patches, set compilation flags, anything really.
  # https://nixos.wiki/wiki/Overlays
  modifications = final: prev: {
  # codemadness-frontends = prev.callPackage ../pkgs/codemadness-frontends {};     
  sxmo-utils = prev.callPackage ../pkgs/sxmo-1.17.1 {
    codemadness-frontends = prev.codemadness-frontends;
  #     # mmsd-tng
  #     # mnc
  #     # superd
  #     # vvmd
  #     # sxmo-dwm
  #     # sxmo-dmenu
  #     # sxmo-st
  #   ; # Ensure this semicolon is also removed if it was part of the original uncommenting logic
  };
    # example = prev.example.overrideAttrs (oldAttrs: rec {
    # ...
    # });
  };

  # When applied, the unstable nixpkgs set (declared in the flake inputs) will
  # be accessible through 'pkgs.unstable'
  unstable-packages = final: _prev: {
    unstable = import inputs.nixpkgs-unstable {
      system = final.system;
      config.allowUnfree = true;
    };
  };
}
