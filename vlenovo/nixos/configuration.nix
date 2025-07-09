# This is your system's configuration file.
# Use this to configure your system environment (it replaces /etc/nixos/configuration.nix)
{
  inputs,
  outputs,
  lib,
  config,
  pkgs,
  # defaultUserName ? "alex",
  ...
}: {
  # You can import other NixOS modules here
  imports = [
    # If you want to use modules your own flake exports (from modules/nixos):
    # outputs.nixosModules.example
    # outputs.packages
    outputs.nixosModules.sxmo-utils
    # Or modules from other flakes (such as nixos-hardware):
    # inputs.hardware.nixosModules.common-cpu-amd
    # inputs.hardware.nixosModules.common-ssd

    # You can also split up your configuration and import pieces of it here:
    # ./users.nix

    # Import your generated (nixos-generate-config) hardware configuration
    ./hardware-configuration.nix
  ];

  nixpkgs = {
    # You can add overlays here
    overlays = [
      # Add overlays your own flake exports (from overlays and pkgs dir):
      outputs.overlays.additions
      outputs.overlays.modifications
      outputs.overlays.unstable-packages

      # You can also add overlays exported from other flakes:
      # neovim-nightly-overlay.overlays.default

      # Or define it inline, for example:
      # (final: prev: {
      #   hi = final.hello.overrideAttrs (oldAttrs: {
      #     patches = [ ./change-hello-to-hi.patch ];
      #   });
      # })
    ];
    # Configure your nixpkgs instance
    config = {
      # Disable if you don't want unfree packages
      allowUnfree = true;
    };
  };

  # This will add each flake input as a registry
  # To make nix3 commands consistent with your flake
  nix.registry = (lib.mapAttrs (_: flake: {inherit flake;})) ((lib.filterAttrs (_: lib.isType "flake")) inputs);

  # This will additionally add your inputs to the system's legacy channels
  # Making legacy nix commands consistent as well, awesome!
  nix.nixPath = ["/etc/nix/path"];
  environment.etc =
    lib.mapAttrs'
    (name: value: {
      name = "nix/path/${name}";
      value.source = value.flake;
    })
    config.nix.registry;

  nix.settings = {
    # Enable flakes and new 'nix' command
    experimental-features = "nix-command flakes";
    # Deduplicate and optimize nix store
    auto-optimise-store = true;
  };


  # Bootloader
  boot.loader.grub.enable = true;

  # Bootloader
  boot.loader.efi.canTouchEfiVariables = false;
  boot.loader.grub.efiSupport = true;
  boot.loader.grub.efiInstallAsRemovable = true;
  boot.loader.grub.device = "nodev";
  boot.loader.grub.forcei686 = true;

  #boot.loader.grub.device = "/dev/sda";   # (for BIOS systems only)
  #boot.loader.systemd-boot.enable = true; # (for UEFI systems only)
  networking.hostName = "vlenovo"; # Define your hostname.
  # Pick only one of the below networking options.
  #  networking.wireless.enable = true;  # Enables wireless support via wpa_supplicant.
  #  networking.wireless.extraConfig = ''
	# ctrl_interface=DIR=/var/run/wpa_supplicant GROUP=wheel
	# '';  
  networking.networkmanager.enable = true;  # Easiest to use and most distros use this by default.

  users.users = {
    alex = {
      isNormalUser = true;

      extraGroups = [ "networkmanager" "wheel"];
      password = "test";

    # Optional: Add your SSH public key for key-based auth
      openssh.authorizedKeys.keys = [
        "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIDV45EkSp+b5fraVf5vDDUbuu2O7kVGxDn+8O6y/xcxh alex@gmail.com"
      ];      
    };
  };
  # Allow passwordless sudo for wheel group
  security.sudo.wheelNeedsPassword = false;

  # Add VM port forwarding for SSH access
  virtualisation.vmVariant.virtualisation.forwardPorts = [
    { from = "host"; host.port = 2222; guest.port = 22; }
  ];      

  services.xserver.desktopManager.sxmo = {
    enable = true;
    user = "alex";
    group = "users";
  };

  # 1. Disable the standard text-login prompt on TTY1.
  systemd.services."getty@tty1".enable = false;

  systemd.services.sxmo = {
    # It's good practice to declare that sxmo conflicts with the getty service.
    conflicts = [ "getty@tty1.service" ];

    # Override specific settings within the serviceConfig.
    # lib.mkForce gives our values the highest priority.
    serviceConfig = {
      TTYPath = lib.mkForce "/dev/tty1";
      UtmpIdentifier = lib.mkForce "tty1";
    };
  };

  fonts.packages = with pkgs; [
    noto-fonts
    noto-fonts-emoji
    # This is the new way to specify the FiraCode Nerd Font
    nerd-fonts.fira-code
  ];

  fonts.fontconfig = {
    defaultFonts = {
      serif = [ "Noto Serif" ];
      sansSerif = [ "Noto Sans" ];
      monospace = [ "Fira Code Nerd Font" ];
    };
  };

  # List packages installed in system profile. To search, run:
  # $ nix search wget
   environment.systemPackages = with pkgs; [
    git  
  #   vim # Do not forget to add an editor to edit configuration.nix! The Nano editor is also installed by default.
  #   wget
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
    # Open SSH port in firewall
  networking.firewall = {
    enable = true;
    allowedTCPPorts = [ 22 ];
  };

  # Copy the NixOS configuration file and link it from the resulting system
  # (/run/current-system/configuration.nix). This is useful in case you
  # accidentally delete configuration.nix.
  # system.copySystemConfiguration = true;

  # This setups a SSH server. Very important if you're setting up a headless system.
  # Feel free to remove if you don't need it.
  services.openssh = {
    enable = true;
    settings = {
      # Forbid root login through SSH.
      PermitRootLogin = "no";
      # Use keys only. Remove if you want to SSH using password (not recommended)
      PasswordAuthentication = true;
    };
  };

  # https://nixos.wiki/wiki/FAQ/When_do_I_update_stateVersion
  system.stateVersion = "25.11";
}
