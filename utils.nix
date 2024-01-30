{ stdenv
, bash
, bc
, bemenu
, bonsai
, brightnessctl
, buildPackages
, busybox
, codemadness-frontends_0_6 ? null  # 2023-11-28: alpine is stuck at 0.6, and i think it exposes a different API
, conky
, coreutils
, curl
, dbus
, dmenu
, fetchFromSourcehut
, fetchpatch
, gnugrep
, gojq
, grim
, inotify-tools
, j4-dmenu-desktop
, jq
, lib
, libnotify
, libxml2
, lisgd
, makeBinaryWrapper
, mako
, modemmanager
, nettools
, networkmanager
, playerctl
, procps
, pulseaudio
, rsync
, scdoc
, scrot
, sfeed
, slurp
, superd
, sway
, swayidle
, systemd
, unstableGitUpdater
, upower
, wob
, wl-clipboard
, wtype
, wvkbd
, xdg-user-dirs
, xdg-utils
, xdotool
, xrdb
, supportSway ? true
, supportDwm ? false
, preferSystemd ? true
, preferXdgOpen ? true
}:

let
  # anything which any sxmo script or default hook in this package might invoke
  runtimeDeps = [
    bc  # also in busybox
    bonsai
    brightnessctl
    codemadness-frontends_0_6  # for sxmo_youtube.sh
    conky
    curl
    dbus
    gnugrep  # also in busybox
    gojq  # TODO: scripts/core/sxmo_wm.sh should use `jq` instead of `gojq`
    inotify-tools
    j4-dmenu-desktop
    jq
    libnotify
    libxml2.bin  # for xmllint; sxmo_weather.sh, sxmo_surf_linkset.sh
    lisgd
    mako
    modemmanager  # mmcli
    nettools  # netstat
    networkmanager  # nmcli
    playerctl
    procps  # pgrep
    pulseaudio  # pactl
    sfeed
    upower  # used by sxmo_battery_monitor.sh, sxmo_hook_battery.sh
    wob
    xdg-user-dirs  # used by sxmo_hook_start.sh
    xrdb  # for sxmo_xinit AND sxmo_winit
  ] ++ (
    if preferSystemd then [ systemd ] else [ superd ]
  ) ++ lib.optionals supportSway [
    bemenu
    grim
    slurp  # for sxmo_screenshot.sh
    sway
    swayidle
    wl-clipboard  # for wl-copy; sxmo_screenshot.sh
    wtype  # for sxmo_type
    wvkbd  # sxmo_winit.sh
  ] ++ lib.optionals supportDwm [
    dmenu
    scrot  # sxmo_screenshot.sh
    xdotool
  ] ++ lib.optionals preferXdgOpen [ xdg-utils ];
in
stdenv.mkDerivation rec {
  pname = "sxmo-utils";
  version = "unstable-2024-01-01";

  src = fetchFromSourcehut {
    owner = "~mil";
    repo = "sxmo-utils";
    rev = "9b6aa786a0f9d5a31b10f9faad65c7f3d5a28249";
    hash = "sha256-bQ8hBU2GeMU5PDI5KcMg5NFFG86X15O94CL5Oq55loQ=";
  };

  patches = [

    (fetchpatch {
      # experimental patch to launch apps via `swaymsg exec -- `
      # this allows them to detach from sxmo_appmenu.sh (so, `pstree` looks cleaner)
      # and more importantly they don't inherit the environment of sxmo internals (i.e. PATH).
      # suggested by Aren in #sxmo.
      #
      # old pstree look:
      # - sxmo_hook_inputhandler.sh volup_one
      #   - sxmo_appmenu.sh
      #     - sxmo_appmenu.sh applications
      #       - <application, e.g. chatty>
      name = "sxmo_hook_apps: launch apps via the window manager";
      url = "https://git.uninsane.org/colin/sxmo-utils/commit/0087acfecedf9d1663c8b526ed32e1e2c3fc97f9.patch";
      hash = "sha256-YwlGM/vx3ZrBShXJJYuUa7FTPQ4CFP/tYffJzUxC7tI=";
    })
    # (fetchpatch {
    #   name = "sxmo_log: print to console";
    #   url = "https://git.uninsane.org/colin/sxmo-utils/commit/030280cb83298ea44656e69db4f2693d0ea35eb9.patch";
    #   hash = "sha256-dc71eztkXaZyy+hm5teCw9lI9hKS68pPoP53KiBm5Fg=";
    # })
  ] ++ lib.optionals preferXdgOpen [
    (fetchpatch {
      name = "sxmo_open: use xdg-open";
      url = "https://git.uninsane.org/colin/sxmo-utils/commit/8897aa5ef869be879e2419f70a16afd710f053fe.patch";
      hash = "sha256-jvMSDJdOGeN2VGnuQ6UT/1gmFJtzTXTxt0WJ9gPInpU=";
    })
  ];

  postPatch = ''
    substituteInPlace Makefile --replace '"$(PREFIX)/bin/{}"' '"$(out)/bin/{}"'
    substituteInPlace Makefile --replace '$(DESTDIR)/usr' '$(out)'
    substituteInPlace setup_config_version.sh --replace "busybox" ""

    # A better way than wrapping hundreds of shell scripts (some of which are even meant to be sourced)
    sed -i '2i export PATH="'"$out"'/bin:${lib.makeBinPath ([
      gojq
      util-linux # setsid, rfkill
      busybox
      lisgd
      pn
      # mnc
      # bonsai
      inotify-tools
      libnotify
      light
      superd
      file
      mmsd-tng
    ] ++ lib.optionals (!isX) [
      sxmo-sway
      bemenu
      foot
      wvkbd
      proycon-wayout
      wtype
      mako
      wob
      swayidle
    ] ++ lib.optionals isX [
      dwm
      dmenu
      st
      svkbd
      conky
      xdotool
      dunst
      xprintidle
    ])}''${PATH:+:}$PATH"' scripts/core/sxmo_common.sh
    sed -i '3i export XDG_DATA_DIRS="'"$out"'/share''${XDG_DATA_DIRS:+:}$XDG_DATA_DIRS"' scripts/core/sxmo_common.sh

    substituteInPlace $(${gnugrep}/bin/grep -rl '\. sxmo_common.sh') \
      --replace ". sxmo_common.sh" ". $out/bin/sxmo_common.sh"
    substituteInPlace \
      scripts/core/sxmo_winit.sh \
      scripts/core/sxmo_xinit.sh \
      scripts/core/sxmo_rtcwake.sh \
      scripts/core/sxmo_migrate.sh \
      --replace "/etc/profile.d/sxmo_init.sh" "$out/etc/profile.d/sxmo_init.sh"
    substituteInPlace scripts/core/sxmo_version.sh --replace "/usr/bin/" ""
    substituteInPlace configs/superd/services/* --replace "/usr/bin/" ""
    substituteInPlace configs/appcfg/sway_template --replace "/usr" "$out"
    substituteInPlace configs/udev/90-sxmo.rules --replace "/bin" "${busybox}/bin"
    substituteInPlace scripts/core/sxmo_uniq_exec.sh --replace '$1' '$(command -v $1)'

    substituteInPlace scripts/core/sxmo_common.sh --replace 'alias rfkill="busybox rfkill"' '#'
    substituteInPlace configs/default_hooks/sxmo_hook_desktop_widget.sh --replace "wayout" "proycon-wayout"
  '';

  nativeBuildInputs = [
    makeBinaryWrapper
    scdoc
  ];

  buildInputs = [ bash ];  # needed here so stdenv's `patchShebangsAuto` hook sets the right interpreter

  makeFlags = [
    "PREFIX=${placeholder "out"}"
    "SYSCONFDIR=${placeholder "out"}/etc"
    "DESTDIR="
    "OPENRC=0"
    # TODO: use SERVICEDIR and EXTERNAL_SERVICES=0 to integrate superd/systemd better
  ];

  meta = {
    homepage = "https://git.sr.ht/~mil/sxmo-utils";
    description = "Contains the scripts and small C programs that glues the sxmo enviroment together";
    license = lib.licenses.mit;
    maintainers = with lib.maintainers; [ colinsane ];
    platforms = lib.platforms.linux; 
  };
}