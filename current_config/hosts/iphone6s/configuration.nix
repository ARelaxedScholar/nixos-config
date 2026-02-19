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
  nix.settings = {
    substituters = [ "https://niri.cachix.org" ];
    trusted-public-keys = [ "niri.cachix.org-1:Wv00m07PsuJ90V2jMZW5ajB8PxyYcnyk8TmgV0/2060=" ];
    experimental-features = [
      "nix-command"
      "flakes"
    ];
  };

  # Use the systemd-boot EFI boot loader.
  boot.loader.systemd-boot.enable = false;
  boot.loader.grub.enable = true;
  boot.loader.grub.efiSupport = true;
  boot.loader.grub.efiInstallAsRemovable = lib.mkForce false;
  boot.loader.efi.canTouchEfiVariables = lib.mkForce true;

  # bluetooth
  hardware.bluetooth.enable = true;
  # seatd for session management (required for niri)
  services.seatd.enable = true;
  services.seatd.logLevel = "info";
  # polkit for authentication
  security.polkit.enable = true;

  # Use latest kernel.
  boot.kernelPackages = pkgs.linuxPackages;

  networking.hostName = "iphone6s";
  networking.networkmanager.enable = true;
  networking.hostId = "deadbeef";

  # Set your time zone.
  time.timeZone = "America/New_York";

  # Select internationalisation properties.
  i18n.defaultLocale = "en_US.UTF-8";

  i18n.inputMethod = {
    enable = true;
    type = "fcitx5";
    fcitx5.addons = with pkgs; [
      fcitx5-mozc
      fcitx5-gtk
    ];
  };

  # Enable CUPS to print documents.
  services.printing.enable = true;

  # Enable sound and screen sharing.
  services.pipewire = {
    enable = true;
    pulse.enable = true;
    wireplumber.enable = true;
  };

  services.gvfs.enable = true;
  services.avahi = {
    enable = true;
    nssmdns4 = true;
    openFirewall = true;
  };

  # Enable Niri
  programs.niri = {
    enable = true;
    package =
      pkgs.runCommand "niri-wrapped"
        {
          nativeBuildInputs = [ pkgs.makeWrapper ];
          buildInputs = [
            pkgs.xorg.libXcursor
            pkgs.xorg.libX11
            pkgs.xorg.libXrender
            pkgs.xorg.libXi
            pkgs.xorg.libXfixes
            pkgs.xorg.libXext
          ];
        }
        ''
          mkdir -p $out/bin
          makeWrapper ${inputs.niri.packages.${pkgs.system}.niri-unstable}/bin/niri $out/bin/niri \
            --set LD_LIBRARY_PATH "${pkgs.xorg.libXcursor}/lib:${pkgs.xorg.libX11}/lib:${pkgs.xorg.libXrender}/lib:${pkgs.xorg.libXi}/lib:${pkgs.xorg.libXfixes}/lib:${pkgs.xorg.libXext}/lib" \
            --set WINIT_UNIX_BACKEND wayland \
            --set WINIT_BACKEND wayland \
            --set WINIT_PLATFORM wayland \
            --unset DISPLAY \
            --unset XAUTHORITY \
            --prefix PATH : ${pkgs.xorg.libXcursor}/bin
        '';
  };

  # XDG Portal configuration - CRITICAL for file dialogs and screen sharing
  xdg.portal = {
    enable = true;
    wlr.enable = true;
    extraPortals = with pkgs; [
      xdg-desktop-portal-wlr
      xdg-desktop-portal-gnome
      xdg-desktop-portal-gtk
    ];
    # Required for xdg-desktop-portal >= 1.17
    config.common.default = "*";
  };

  # Ensure proper environment variables for Wayland
  environment.variables = {
    EDITOR = "evil-helix";
  };
  environment.sessionVariables = {
    NIXOS_OZONE_WL = "1";
    XDG_CURRENT_DESKTOP = "Niri";
    XDG_SESSION_TYPE = "wayland";
    XDG_SESSION_DESKTOP = "Niri";
    LIBINPUT_ACCEL_SPEED = "-0.5";
    LIBINPUT_ACCEL_PROFILE = "flat";
    LIBINPUT_DISABLE_WHILE_TYPING = "1";
    # OBS screen sharing on Wayland
    OBS_USE_EGL = "1";
    OBS_USE_WAYLAND = "1";
    QT_QPA_PLATFORM = "wayland";
    GDK_BACKEND = "wayland,x11";
    WINIT_UNIX_BACKEND = "wayland";
  };

  # Enable touchpad support (enabled default in most desktopManager).
  services.libinput = {
    enable = true;
    touchpad = {
      accelSpeed = "-0.5"; # 50% slower than default
      accelProfile = "flat"; # Predictable linear movement
      disableWhileTyping = true; # Prevent cursor jumps while typing
      tapping = true; # Enable tap-to-click (required for Niri)
      naturalScrolling = false; # Let Niri handle scroll direction
    };
  };

  nixpkgs.config.allowUnfree = true;

  environment.shells = with pkgs; [ zsh ];
  programs.zsh.enable = true;

  # Define my user
  users.users.user = {
    isNormalUser = true;
    hashedPassword = "$6$E/iKuuVKtIZtoU30$l/3BBHa.MAxX5P9Nr/j8r9DjzbWX2F6H8KfwigrTvnQMFz7yG99iO9NSSNiR2hQ.S9gupox8LjfGiEA6cWuL5/";
    extraGroups = [
      "wheel"
      "docker"
      "seat"
      "video"
      "input"
    ]; # Enable 'sudo' for the user.
    shell = pkgs.zsh;
  };
  virtualisation.docker.enable = true;

  # Auto-login
  services.getty.autologinUser = "user";

  programs.firefox.enable = true;

  # List packages installed in system profile.
  environment.systemPackages = with pkgs; [
    bun
    cachix
    chromium
    libinput
    xwayland
    xwayland-satellite
    xauth
    docker-compose
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
    zoom-us

    # Development tools
    nodejs_22
    nodePackages.npm
    uv
    R
    pandoc
    quarto
    texlive.combined.scheme-full

    # Default applications
    mpv
    kdePackages.gwenview
    libreoffice
    tauon
    jellyfin-media-player

    # Utilities
    which
    p7zip
    kdePackages.ark
    ffmpegthumbnailer
    kdePackages.kio-extras
    kdePackages.kio-admin
    blueman
    networkmanagerapplet
    swaynotificationcenter
    tailscale
    nomachine-client
    kdePackages.fcitx5-configtool

    # Graphics/OpenGL

    mesa
    xorg.libXcursor
    xorg.libX11
    xorg.libXrandr
    xorg.libXrender
    xorg.libXi
    xorg.libXfixes
    xorg.libXext
    libxcb
  ];

  # Enable the OpenSSH daemon.
  services.openssh.enable = true;

  services.tailscale.enable = true;

  # Ensure D-Bus is running properly
  services.dbus.enable = true;

  # Copy the NixOS configuration file and link it from the resulting system (I am using flakes)
  system.copySystemConfiguration = false;

  # Hardware database entries for libinput touchpad settings (Wayland)
  services.udev.extraHwdb = ''
    # Dell touchpad sensitivity adjustments
    evdev:input:b0018v0488p121Fe0100*
     LIBINPUT_ATTR_ACCEL_SPEED=-0.5
     LIBINPUT_ATTR_ACCEL_PROFILE=flat
     LIBINPUT_ATTR_DISABLE_WHILE_TYPING=1
     LIBINPUT_ATTR_PALM_PRESSURE_THRESHOLD=250
     LIBINPUT_ATTR_TAP_ENABLED=1
  '';

  # Udev rules as alternative (may be needed for some systems)
  services.udev.extraRules = ''
    # Touchpad sensitivity adjustments for libinput (Wayland)
    ACTION=="add|change", KERNEL=="event[0-9]*", ENV{ID_VENDOR_ID}=="0488", ENV{ID_MODEL_ID}=="121f", ENV{LIBINPUT_ATTR_ACCEL_SPEED}="-0.5", ENV{LIBINPUT_ATTR_ACCEL_PROFILE}="flat", ENV{LIBINPUT_ATTR_DISABLE_WHILE_TYPING}="1", ENV{LIBINPUT_ATTR_PALM_PRESSURE_THRESHOLD}="250", ENV{LIBINPUT_ATTR_TAP_ENABLED}="1"
  '';

  # Should never change this
  system.stateVersion = "25.05";
}
