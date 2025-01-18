# Edit this configuration file to define what should be installed on
# your system.  Help is available in the configuration.nix(5) man page
# and in the NixOS manual (accessible by running ‘nixos-help’).

{ inputs, config, pkgs, lib, ... }:

{
  imports =
    [ # Include the results of the hardware scan.
      ./hardware-configuration.nix
    ];
  nixpkgs.config.permittedInsecurePackages = ["electron-19.1.9"];
  nix.settings.experimental-features = ["nix-command" "flakes"];
  # Bootloader.
  boot.loader.grub.enable = true;
  boot.loader.grub.device = "/dev/sda";
  boot.loader.grub.useOSProber = true;
  boot.supportedFilesystems = [ "ntfs" ];
  networking.hostName = "acer"; # Define your hostname.
#  networking.wireless.enable = true;  # Enables wireless support via wpa_supplicant.

  # Configure network proxy if necessary
  # networking.proxy.default = "http://user:password@proxy:port/";
  # networking.proxy.noProxy = "127.0.0.1,localhost,internal.domain";

  # Enable networking
  networking.networkmanager.enable = true;

  # Set your time zone.
  time.timeZone = "Asia/Yekaterinburg";

  # Select internationalisation properties.
  i18n.defaultLocale = "ru_RU.UTF-8";

  i18n.extraLocaleSettings = {
    LC_ADDRESS = "ru_RU.UTF-8";
    LC_IDENTIFICATION = "ru_RU.UTF-8";
    LC_MEASUREMENT = "ru_RU.UTF-8";
    LC_MONETARY = "ru_RU.UTF-8";
    LC_NAME = "ru_RU.UTF-8";
    LC_NUMERIC = "ru_RU.UTF-8";
    LC_PAPER = "ru_RU.UTF-8";
    LC_TELEPHONE = "ru_RU.UTF-8";
    LC_TIME = "ru_RU.UTF-8";
  };
  services.udisks2.enable = true;
  # Enable the X11 windowing system.
  services.xserver.enable = true;

  # Enable the Budgie Desktop environment.
  services.xserver.displayManager.lightdm.enable = true;
  services.xserver.desktopManager.budgie.enable = true;

  # Configure keymap in X11
  services.xserver = {
    xkb.layout = "us";
    xkb.variant = "";
  };

  # Enable CUPS to print documents.
  services.printing = {
    enable = true;
    drivers = with pkgs; [ hplip hplipWithPlugin ];
    #extraConf = ''
    #  DefaultAuthType Negotiate
    #'';
  };

  services.system-config-printer.enable = true;
  programs.system-config-printer.enable = true;
  # Enable sound with pipewire.
#  sound.enable = true;
  hardware.pulseaudio.enable = false;
  security.rtkit.enable = true;
  services.pipewire = {
    enable = true;
    alsa.enable = true;
    alsa.support32Bit = true;
    pulse.enable = true;
    # If you want to use JACK applications, uncomment this
    jack.enable = true;

    # use the example session manager (no others are packaged yet so this is enabled by default,
    # no need to redefine it in your config for now)
    #media-session.enable = true;
  };

  # Enable touchpad support (enabled default in most desktopManager).
  # services.xserver.libinput.enable = true;
	  services = {
    #qemuGuest.enable = true;
    spice-vdagentd.enable = true;
  };


	virtualisation.docker.enable = true;
	# https://nixos.wiki/wiki/Virt-manager
	virtualisation.libvirtd.enable = true;
	virtualisation.spiceUSBRedirection.enable = true;
	programs.virt-manager.enable = true;
	users.groups.libvirtd.members = ["alex"];
	programs.noisetorch.enable = true;
 # Define a user account. Don't forget to set a password with ‘passwd’.
  users.users.alex = {
    isNormalUser = true;
    description = "Alex-acer";
    extraGroups = [ "networkmanager" "wheel" "docker" "libvirtd" ];
    packages = with pkgs; [
#      firefox
	google-chrome
	vscode
#	telegram-desktop
	audio-recorder
#	espanso
	xarchiver
#	sonic-pi
#	wavebox
    #  thunderbird
    ];
  };

  # Enable automatic login for the user.
  services.displayManager.autoLogin.enable = true;
  services.displayManager.autoLogin.user = "alex";

  services.trilium-server.enable = false;
services.flatpak.enable = true;
services.transmission = { 
    enable = true; #Enable transmission daemon
    openRPCPort = true; #Open firewall for RPC
    settings = { #Override default settings
      rpc-bind-address = "0.0.0.0"; #Bind to own IP
      rpc-whitelist = "127.0.0.1,10.0.0.1"; #Whitelist your remote machine (10.0.0.1 in this example)
    };
  };

# default data directory: /var/lib/trilium
#services.trilium-server.dataDir = "/var/lib/trilium-sync-server";

# default bind address: 127.0.0.1, port 8080
#services.trilium-server.host = "0.0.0.0";
#services.trilium-server.port = 12783;

  # Allow unfree packages
  nixpkgs.config.allowUnfree = true;

  # List packages installed in system profile. To search, run:
  # $ nix search wget
  environment.systemPackages = with pkgs; [
  #  vim # Do not forget to add an editor to edit configuration.nix! The Nano editor is also installed by default.
  #  wget
	git
	pulseaudio
	# Add zen browser here. Choose one of these:
    #inputs.zen-browser.packages."${pkgs.system}".default  # default (specific)
    # inputs.zen-browser.packages."${pkgs.system}".specific # same as default
      inputs.zen-browser.packages."${pkgs.system}".generic   # generic version for older systems
  ];

  # Some programs need SUID wrappers, can be configured further or are
  # started in user sessions.
  # programs.mtr.enable = true;
  # programs.gnupg.agent = {
  #   enable = true;
  #   enableSSHSupport = true;
  # };

  # List services that you want to enable:

  # Enable the OpenSSH daemon.
  # services.openssh.enable = true;

  # Open ports in the firewall.
  # networking.firewall.allowedTCPPorts = [ ... ];
  # networking.firewall.allowedUDPPorts = [ ... ];
  # Or disable the firewall altogether.
  networking.firewall.enable = false;
  services.v2raya.enable = true;
  #  # services.v2ray.configFile = "/etc/v2ray/config.json";
  # This value determines the NixOS release from which the default
  # settings for stateful data, like file locations and database versions
  # on your system were taken. It‘s perfectly fine and recommended to leave
  # this value at the release version of the first install of this system.
  # Before changing this value read the documentation for this option
  # (e.g. man configuration.nix or on https://nixos.org/nixos/options.html).
  system.stateVersion = "25.05"; # Did you read the comment?

}
