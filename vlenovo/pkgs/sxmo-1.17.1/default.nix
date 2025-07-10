{ lib
, stdenv
, fetchFromSourcehut
, fetchpatch
, gnugrep
, gojq
, busybox
, util-linux
, lisgd
, pn
, inotify-tools
, libnotify
, light
, superd
, file
, mmsd-tng
, isX ? false
, sway, dwm
, bemenu, dmenu
, foot, st
, wvkbd, svkbd
, proycon-wayout, conky
, wtype, xdotool
, mako, dunst
, wob
, swayidle, xprintidle
, codemadness-frontends
, scdoc # Added scdoc
, pkg-config # Added pkg-config
, libcap # Added libcap
, icu # Added icu
#, youtube-dl
}:

stdenv.mkDerivation rec {
  pname = "sxmo-utils";
  nativeBuildInputs = [ scdoc pkg-config libcap ]; # Added scdoc pkg-config libcap
  buildInputs = [ icu ]; # Added icu
  version = "1.17.1";

  src = fetchFromSourcehut {
    owner = "~mil";
    repo = pname;
    rev = version;
    hash = "sha256-RU57qxfIlci0VuN+lAME1hrBt1aRIIxUzWOxkePYxlQ=";
  };

  # patches = [ ./nerdfonts-3.0.0.patch ]; # Assuming the patch is no longer needed or needs update
  patches = [];

  postPatch = ''
    substituteInPlace Makefile --replace '"$(PREFIX)/bin/{}"' '"$(out)/bin/{}"'
    # Removed: substituteInPlace Makefile --replace '$(DESTDIR)/usr' '$(out)'
    substituteInPlace setup_config_version.sh --replace "busybox" ""

    # Removed: rm scripts/appscripts/sxmo_reddit.sh (file does not exist in 1.17.1)

    sed -i '/_battery() {/a \	[ ! -d /sys/class/power_supply ] || [ -z "$(ls -A /sys/class/power_supply)" ] && return' configs/default_hooks/sxmo_hook_statusbar.sh

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
      codemadness-frontends # reddit-cli and youtube-cli for sxmo_[reddit|youtube].sh
      #youtube-dl
    ] ++ lib.optionals (!isX) [
      (sway.override {
        withBaseWrapper = true;
        withGtkWrapper = true;
      })
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
      scripts/core/sxmo_init.sh \
      scripts/core/sxmo_migrate.sh \
      --replace "/etc/profile.d/sxmo_init.sh" "$out/etc/profile.d/sxmo_init.sh"
    substituteInPlace scripts/core/sxmo_version.sh --replace "/usr/bin/" ""
    substituteInPlace configs/services/* configs/external-services/* --replace "/usr/bin/" ""
    # Removed: substituteInPlace configs/appcfg/sway_template --replace "/usr" "$out" (pattern not found)
    substituteInPlace configs/udev/90-sxmo.rules --replace "/bin" "${busybox}/bin"
    # Removed: substituteInPlace scripts/core/sxmo_uniq_exec.sh --replace '$1' '$(command -v $1)' (file not found)

    substituteInPlace scripts/core/sxmo_common.sh --replace 'alias rfkill="busybox rfkill"' '#'
    substituteInPlace configs/default_hooks/sxmo_hook_desktop_widget.sh --replace "wayout" "proycon-wayout"
    substituteInPlace Makefile --replace "setcap 'cap_wake_alarm=ep'" "# setcap 'cap_wake_alarm=ep'" # Comment out setcap
  '';

  makeFlags = [
    "DESTDIR=$(out)"
    "PREFIX="
    "OPENRC=0"
  ];

  meta = with lib; {
    description = "Scripts and small C programs that make the sxmo environment";
    homepage = "https://sxmo.org";
    license = licenses.agpl3Only;
    platforms = platforms.linux;
    maintainers = with maintainers; [ chuangzhu ];
  };
}
