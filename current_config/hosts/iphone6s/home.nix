{
  config,
  pkgs,
  inputs,
  ...
}:

{
  imports = [
    ../../modules/niri.nix
    ../../modules/waybar.nix
    ../../modules/zsh.nix
  ];

  # Ensure portal config files are created
  xdg.configFile."xdg-desktop-portal/portals.conf".text = ''
    [preferred]
    default=gtk
    org.freedesktop.impl.portal.FileChooser=gtk
    # Niri uses the GNOME portal for screencasting/screenshots
    org.freedesktop.impl.portal.Screenshot=gnome
    org.freedesktop.impl.portal.ScreenCast=gnome
  '';

  home.packages = with pkgs; [
    inputs.antigravity-nix.packages.x86_64-linux.default
    evil-helix
    tree
    obs-studio
    mpv
    anki
    obsidian
    reaper
    zotero

    # fonts
    noto-fonts-cjk-sans
    ipafont
    kochi-substitute
    noto-fonts
    noto-fonts-color-emoji
    wofi
    kdePackages.dolphin
  ];

  services = {
    # blue light filter
    gammastep = {
      enable = true;
      provider = "manual";
      latitude = 45.32;
      longitude = -77.88;
    };
  };

  home.stateVersion = "25.05";
}
