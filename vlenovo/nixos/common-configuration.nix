# This file contains settings shared between the real system and the test VM.
# It does NOT contain overlays, to prevent infinite recursion.
{ config, pkgs, lib, ... }:

{
  # Import your hardware configuration. The test VM will ignore this, which is fine.
  imports = [ ./hardware-configuration.nix ];

  # Remove the nix.registry and nix.nixPath setup from here
  # We'll handle it in the main configuration.nix instead

  nix.settings = {
    experimental-features = "nix-command flakes";
    auto-optimise-store = true;
  };

  # Bootloader (will be used by the real build)
  boot.loader.grub = {
    efiSupport = true;
    efiInstallAsRemovable = true;
    device = "nodev";
    forcei686 = true;
  };
  boot.loader.efi.canTouchEfiVariables = false;

  # Common settings for both real and test builds
  networking.hostName = "vlenovo";
  networking.networkmanager.enable = true;

  # User definition
  users.users.alex = {
    isNormalUser = true;
    extraGroups = [ "networkmanager" "wheel" "input" "video" ];
    password = "test";
    shell = pkgs.bash; # Use a standard shell.
    openssh.authorizedKeys.keys = [
      "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIDV45EkSp+b5fraVf5vDDUbuu2O7kVGxDn+8O6y/xcxh alex@gmail.com"
    ];
  };
  users.users.root.openssh.authorizedKeys.keys = [
    "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIDV45EkSp+b5fraVf5vDDUbuu2O7kVGxDn+8O6y/xcxh alex@gmail.com"
  ];

  security.sudo.wheelNeedsPassword = false;

  # Service configuration
  services.xserver.desktopManager.sxmo = {
    enable = true;
    user = "alex";
    group = "users";
  };

  # Systemd overrides
  systemd.services."getty@tty1".enable = false;
  systemd.services.sxmo = {
    conflicts = [ "getty@tty1.service" ];
    serviceConfig = {
      TTYPath = lib.mkForce "/dev/tty1";
      UtmpIdentifier = lib.mkForce "tty1";
    };
  };

  # Fonts
  fonts.packages = with pkgs; [
    noto-fonts
    noto-fonts-emoji
    nerd-fonts.fira-code
  ];
  fonts.fontconfig.defaultFonts = {
    serif = [ "Noto Serif" ];
    sansSerif = [ "Noto Sans" ];
    monospace = [ "Fira Code Nerd Font" ];
  };

  # Base system packages
  environment.systemPackages = with pkgs; [ git ];

  # SSH service
  services.openssh = {
    enable = true;
    settings = {
      PermitRootLogin = "prohibit-password";
      PasswordAuthentication = false;
    };
  };

  # Firewall
  networking.firewall.enable = true;
  networking.firewall.allowedTCPPorts = [ 22 ];

  # State version
  system.stateVersion = "25.05";
}