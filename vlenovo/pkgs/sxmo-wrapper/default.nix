# vlenovo/pkgs/sxmo-wrapper/default.nix
{ lib
, pkgs
, sxmo-utils-unwrapped
, codemadness-frontends
, yt-dlp
}:

let
  sway-wrapped = pkgs.sway.override { 
    withBaseWrapper = true; 
    withGtkWrapper = true; 
  };
in

sxmo-utils-unwrapped.overrideAttrs (oldAttrs: {
  postPatch = with pkgs; ''
    # Get the absolute paths to where the scripts will be installed
    SXMO_HOOK_DIR="${placeholder "out"}/share/sxmo/default_hooks"
    SXMO_BIN_DIR="${placeholder "out"}/bin"
    SXMO_SHARE_DIR="${placeholder "out"}/share/sxmo"

    # Patch all scripts that source sxmo_hook_icons.sh
    grep -rlZ --null '\. sxmo_hook_icons.sh' . | xargs -0 ${gnused}/bin/sed -i \
      "s|\. sxmo_hook_icons.sh|. $SXMO_HOOK_DIR/sxmo_hook_icons.sh|g"

    # Patch all scripts that source sxmo_common.sh
    grep -rlZ --null '\. sxmo_common.sh' . | xargs -0 ${gnused}/bin/sed -i \
      "s|\. sxmo_common.sh|. $SXMO_BIN_DIR/sxmo_common.sh|g"

    # Patch the main init scripts to find sxmo_init.sh
    grep -rlZ --null '\. sxmo_init.sh' . | xargs -0 ${gnused}/bin/sed -i \
      "s|\. sxmo_init.sh|. $SXMO_BIN_DIR/sxmo_init.sh|g"
      
    # Fix the profile.d sourcing
    substituteInPlace scripts/core/sxmo_init.sh \
      --replace-fail '. /etc/profile.d/sxmo_init.sh' '. ${placeholder "out"}/etc/profile.d/sxmo_init.sh'
    
    # Patch scripts to find sxmo_migrate.sh with absolute path
    find . -type f -name "*.sh" -exec ${gnused}/bin/sed -i \
      "s|sxmo_migrate\.sh|$SXMO_BIN_DIR/sxmo_migrate.sh|g" {} \;
    
    # Patch scripts to find sxmo_status_led with absolute path
    find . -type f -name "*.sh" -exec ${gnused}/bin/sed -i \
      "s|sxmo_status_led|$SXMO_BIN_DIR/sxmo_status_led|g" {} \;

    # Fix XDG_DATA_DIRS for migration script
    sed -i '2i export XDG_DATA_DIRS="${placeholder "out"}/share''${XDG_DATA_DIRS:+:}$XDG_DATA_DIRS"' \
      scripts/core/sxmo_migrate.sh

    # Patch sxmo_hook_start.sh to use absolute path for sway
    if [ -f scripts/default_hooks/sxmo_hook_start.sh ]; then
      substituteInPlace scripts/default_hooks/sxmo_hook_start.sh \
        --replace-fail 'exec sway' 'exec ${sway-wrapped}/bin/sway' \
        --replace-fail 'sway' '${sway-wrapped}/bin/sway'
    fi
    
    # Also patch any other scripts that might launch sway
    find . -type f -name "*.sh" -exec ${gnused}/bin/sed -i \
      "s|exec sway|exec ${sway-wrapped}/bin/sway|g" {} \;

    # Force the Makefile to use the full path to GNU sed
    substituteInPlace Makefile \
      --replace-fail "sed" "${gnused}/bin/sed"
      
    substituteInPlace setup_config_version.sh \
      --replace-fail "busybox" "${busybox}/bin/busybox"
  '';

  # Add a postInstall phase to create the symlink after installation
  postInstall = (oldAttrs.postInstall or "") + ''
    # Make all hook scripts executable
    find $out/share/sxmo/default_hooks -name "*.sh" -type f -exec chmod +x {} \;
    
    # Create symlink for sxmo_hook_start.sh in bin directory if it exists
    if [ -f "$out/share/sxmo/default_hooks/sxmo_hook_start.sh" ]; then
      ln -sf $out/share/sxmo/default_hooks/sxmo_hook_start.sh $out/bin/sxmo_hook_start.sh
    fi
  '';

  meta = sxmo-utils-unwrapped.meta // {
    description = "Scripts and programs for the Sxmo mobile environment (Nix wrapped)";
  };
})