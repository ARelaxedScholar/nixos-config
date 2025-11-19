{
  config,
  pkgs,
  inputs,
  ...
}:

{
  imports = [
    ../../modules/hyprland.nix
    ../../modules/waybar.nix
    ../../modules/zsh.nix
  ];

  # Ensure portal config files are created
  xdg.configFile."xdg-desktop-portal/portals.conf".text = ''
    [preferred]
    default=gtk;hyprland
    org.freedesktop.impl.portal.FileChooser=gtk
    org.freedesktop.impl.portal.Screenshot=hyprland
    org.freedesktop.impl.portal.ScreenCast=hyprland
  '';

  xdg.configFile."xdg-desktop-portal/hyprland-portals.conf".text = ''
    [preferred]
    default=gtk;hyprland
    org.freedesktop.impl.portal.FileChooser=gtk
    org.freedesktop.impl.portal.Screenshot=hyprland
    org.freedesktop.impl.portal.ScreenCast=hyprland
  '';

  home.packages = with pkgs; [
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
      longitude = 77.88;
    };
  };

  home.stateVersion = "25.05";
}
