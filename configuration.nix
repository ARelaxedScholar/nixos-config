{ config, lib, pkgs, ... }:

{
  imports =
    [ 
      ./hardware-configuration.nix
    ];

  # Enabling the experimenal features
  nix.settings.experimental-features = [ "nix-command" "flakes" ];

  # Use the systemd-boot EFI boot loader.
  boot.loader.systemd-boot.enable = false;
  boot.loader.grub.enable = true;
  boot.loader.grub.efiSupport = true;
  boot.loader.grub.efiInstallAsRemovable = lib.mkForce false;
  boot.loader.efi.canTouchEfiVariables= lib.mkForce true;

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

  # Enable touchpad support (enabled default in most desktopManager).
  services.libinput.enable = true;

  # Define a user account. Don't forget to set a password with ‘passwd’.
  users.users.user = {
    isNormalUser = true;
    hashedPassword = "$6$E/iKuuVKtIZtoU30$l/3BBHa.MAxX5P9Nr/j8r9DjzbWX2F6H8KfwigrTvnQMFz7yG99iO9NSSNiR2hQ.S9gupox8LjfGiEA6cWuL5/";
    extraGroups = [ "wheel" ]; # Enable ‘sudo’ for the user.
    packages = with pkgs; [
      tree
      obs-studio
    ];
  };

  programs.firefox.enable = true;

  # List packages installed in system profile.
  environment.systemPackages = with pkgs; [
    eza
    htop
    zoxide
    vim 
    wget
  ];

  # Enable the OpenSSH daemon.
  services.openssh.enable = true;


  # Copy the NixOS configuration file and link it from the resulting system
  system.copySystemConfiguration = false;

  # Should never change this
  system.stateVersion = "25.05"; 

}

