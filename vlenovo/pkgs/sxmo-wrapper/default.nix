# vlenovo/pkgs/sxmo-wrapper/default.nix
# This wrapper handles the RUNTIME environment.
{ lib
, pkgs
, sxmo-utils-unwrapped
, codemadness-frontends
, yt-dlp
}:

sxmo-utils-unwrapped.overrideAttrs (oldAttrs: {
  # This postPatch hook modifies the scripts to work in the Nix environment.
  postPatch = with pkgs; ''
    # Force the Makefile to use the full path to GNU sed to ensure
    # the correct tool is used during the build.
    substituteInPlace Makefile \
      --replace "sed" "${gnused}/bin/sed"

    substituteInPlace setup_config_version.sh \
      --replace "busybox" "${busybox}/bin/busybox"
      
    # Fix the sourcing chain by using absolute paths
    substituteInPlace scripts/core/sxmo_winit.sh \
      --replace ". sxmo_init.sh" ". ${placeholder "out"}/bin/sxmo_init.sh"
      
    substituteInPlace scripts/core/sxmo_init.sh \
      --replace "/etc/profile.d/sxmo_init.sh" "${placeholder "out"}/etc/profile.d/sxmo_init.sh"
      
    substituteInPlace configs/profile.d/sxmo_init.sh \
      --replace ". sxmo_common.sh" ". ${placeholder "out"}/bin/sxmo_common.sh"

    # *** THE NEW, BETTER FIX IS HERE ***
    # The migration script needs to find all default config files. The original
    # script relies on XDG_DATA_DIRS to find them. We inject the correct path
    # at the top of the script so all subsequent calls to `xdg_data_path` work.
    sed -i '2i export XDG_DATA_DIRS="${placeholder "out"}/share''${XDG_DATA_DIRS:+:}$XDG_DATA_DIRS"' \
      scripts/core/sxmo_migrate.sh

    # Inject the correct runtime PATH into sxmo_common.sh
    # This remains essential for all scripts after the initial setup.
    sed -i '2i export PATH="${placeholder "out"}/bin:${lib.makeBinPath ([
      # Minimal set of dependencies for the UI to function
      (sway.override { withBaseWrapper = true; withGtkWrapper = true; })
      bemenu foot wvkbd swayidle wob mako superd lisgd
      # We still need coreutils etc. at RUNTIME, not just build time.
      coreutils gnugrep util-linux jq
      libnotify inotify-tools xdg-user-dirs light
      # Custom dependencies
      codemadness-frontends yt-dlp
    ])}''${PATH:+:}$PATH"' scripts/core/sxmo_common.sh
  '';

  meta = sxmo-utils-unwrapped.meta // {
    description = "Scripts and programs for the Sxmo mobile environment (Nix wrapped)";
  };
})