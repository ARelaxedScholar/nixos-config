{
  inputs,
  config,
  lib,
  pkgs,
  ...
}:
{
  imports = [
    ./hardware-configuration.nix
  ];

  # Enabling the experimental features
  nix.settings.experimental-features = [
    "nix-command"
    "flakes"
  ];

  # Use the systemd-boot EFI boot loader.
  boot.loader.systemd-boot.enable = false;
  boot.loader.grub.enable = true;
  boot.loader.grub.efiSupport = true;
  boot.loader.grub.efiInstallAsRemovable = lib.mkForce false;
  boot.loader.efi.canTouchEfiVariables = lib.mkForce true;

  # bluetooth
  hardware.bluetooth.enable = true;

  # Use latest kernel.
  boot.kernelPackages = pkgs.linuxPackages;

  networking.hostName = "iphone6s";
  networking.networkmanager.enable = true;
  networking.hostId = "deadbeef";

  # Set your time zone.
  time.timeZone = "America/New_York";

  # Select internationalisation properties.
  i18n.defaultLocale = "en_US.UTF-8";

  # Enable CUPS to print documents.
  services.printing.enable = true;

  # Enable sound.
  services.pipewire = {
    enable = true;
    pulse.enable = true;
  };

  # Enable Hyprland
  programs.hyprland = {
    enable = true;
    xwayland.enable = true;
  };

  # XDG Portal configuration - CRITICAL for file dialogs
  xdg.portal = {
    enable = true;
    wlr.enable = false;
    extraPortals = with pkgs; [
      xdg-desktop-portal-hyprland
      xdg-desktop-portal-gtk
    ];
  };

  # Ensure proper environment variables for Wayland
  environment.sessionVariables = {
    NIXOS_OZONE_WL = "1";
    XDG_CURRENT_DESKTOP = "Hyprland";
    XDG_SESSION_TYPE = "wayland";
    XDG_SESSION_DESKTOP = "Hyprland";
  };

  # Enable touchpad support (enabled default in most desktopManager).
  services.libinput.enable = true;

  nixpkgs.config.allowUnfree = true;

  # Define a user account. Don't forget to set a password with 'passwd'.
  users.users.user = {
    isNormalUser = true;
    hashedPassword = "$6$E/iKuuVKtIZtoU30$l/3BBHa.MAxX5P9Nr/j8r9DjzbWX2F6H8KfwigrTvnQMFz7yG99iO9NSSNiR2hQ.S9gupox8LjfGiEA6cWuL5/";
    extraGroups = [ "wheel" ]; # Enable 'sudo' for the user.
  };

  programs.firefox.enable = true;

  # List packages installed in system profile.
  environment.systemPackages = with pkgs; [
    eza
    htop
    zoxide
    fastfetch
    vim
    wget
    git
    kitty
    nixfmt-tree
    nixfmt
    btop
    gammastep

    nh
    nom
    nvd

    # Portal debugging tools
    xdg-utils
    dbus
  ];

  # Enable the OpenSSH daemon.
  services.openssh.enable = true;

  # Ensure D-Bus is running properly
  services.dbus.enable = true;

  # Copy the NixOS configuration file and link it from the resulting system
  system.copySystemConfiguration = false;

  # Should never change this
  system.stateVersion = "25.05";
}
