# vlenovo/pkgs/sxmo-1.17.1/default.nix
{ pkgs, codemadness-frontends, ... }: # Expect pkgs and our custom dependency

pkgs.stdenv.mkDerivation rec {
  pname = "sxmo-utils";
  version = "1.17.1";

  src = pkgs.fetchFromSourcehut {
    owner = "~mil";
    repo = "sxmo-utils";
    rev = version;
    sha256 = "sha256-RU57qxfIlci0VuN+lAME1hrBt1aRIIxUzWOxkePYxlQ=";
  };

  patches = [
    # ./001-system-manages-pipewire.patch
     ./002-remove-setcap.patch
  ];

  passthru.providedSessions = [ "swmo" ];

  nativeBuildInputs = with pkgs; [ coreutils findutils gnugrep busybox scdoc pkg-config libcap ];

  makeFlags = [
    "DESTDIR=$(out)"
    "PREFIX="
    "OPENRC=0"
  ];

  postPatch = with pkgs; ''
    # Remove hardcoded /usr/bin, allowing PATH to work correctly.
    find . -type f -exec sed -E -i "s|/usr/bin/||g" {} +

    # Fix paths in udev rules
    substituteInPlace configs/udev/90-sxmo.rules \
      --replace-quiet /bin/chgrp ${coreutils}/bin/chgrp \
      --replace-quiet /bin/chmod ${coreutils}/bin/chmod

    # Inject the full PATH into sxmo_common.sh, which is sourced by most other scripts.
    # This is the most robust way to provide dependencies.
    sed -i '2i export PATH="${lib.makeBinPath ([
      libnotify inotify-tools xdg-user-dirs modemmanager mmsd-tng light superd
      util-linux busybox lisgd pn gojq file curl mpv sfeed libxml2 yt-dlp sxiv
      mediainfo gawk proycon-wayout codemadness-frontends
      (sway.override { withBaseWrapper = true; withGtkWrapper = true; })
      bemenu wvkbd swayidle wob mako foot grim slurp
    ])}''${PATH:+:}$PATH"' scripts/core/sxmo_common.sh

    # Also inject XDG paths for robustness when running outside a graphical session (e.g. ssh).
    sed -i '3i export XDG_DATA_DIRS="'"$out"'/share''${XDG_DATA_DIRS:+:}$XDG_DATA_DIRS"' \
      scripts/core/sxmo_common.sh

    # Alias core commands to their GNU versions to prevent issues with other implementations.
    sed -i '4i alias realpath="${coreutils}/bin/realpath"' scripts/core/sxmo_common.sh
    sed -i '5i alias stat="${coreutils}/bin/stat"' scripts/core/sxmo_common.sh
    sed -i '6i alias mktemp="${coreutils}/bin/mktemp"' scripts/core/sxmo_common.sh
    sed -i '7i alias date="${coreutils}/bin/date"' scripts/core/sxmo_common.sh
    sed -i 's|alias rfkill=.*$||' scripts/core/sxmo_common.sh
    sed -i '8i alias rfkill="${util-linux}/bin/rfkill"' scripts/core/sxmo_common.sh

    # Fix sxmo's startup scripts to find sxmo_init.sh correctly within the Nix store.
    substituteInPlace \
      scripts/core/sxmo_winit.sh \
      --replace ". sxmo_init.sh" ". $out/bin/sxmo_init.sh"
      
    substituteInPlace scripts/core/sxmo_init.sh \
      --replace ". sxmo_common.sh" ". $out/bin/sxmo_common.sh"
      
    substituteInPlace configs/profile.d/sxmo_init.sh \
      --replace ". sxmo_common.sh" ". $out/bin/sxmo_common.sh"      
      
    substituteInPlace \
      scripts/core/sxmo_init.sh \
      scripts/core/sxmo_migrate.sh \
      configs/profile.d/sxmo_init.sh \
      --replace "/etc/profile.d/sxmo_init.sh" "$out/etc/profile.d/sxmo_init.sh"

    # Fix paths in superd service files
    substituteInPlace \
      configs/services/sxmo_autosuspend.service \
      configs/services/sxmo_battery_monitor.service \
      configs/services/sxmo_menumode_toggler.service \
      configs/services/sxmo_modemmonitor.service \
      configs/services/sxmo_networkmonitor.service \
      configs/services/sxmo_notificationmonitor.service \
      configs/services/sxmo_soundmonitor.service \
      configs/services/sxmo_wob.service \
      configs/services/sxmo_xob.service \
      --replace "ExecStart=" "ExecStart=$out/bin/"
  '';

  meta = with pkgs.lib; {
    description = "Scripts and small C programs that glue the sxmo environment together";
    homepage = "https://sxmo.org";
    license = licenses.agpl3Only;
    platforms = platforms.linux;
  };
}