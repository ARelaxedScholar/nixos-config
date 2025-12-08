{
  config,
  pkgs,
  inputs,
  ...
}:

let
  wallpapers = builtins.readDir ../../wallpapers;
  isImage = name: builtins.match ".*\\.(jpg|jpeg|png|gif|bmp|webp)" name != null;
  wallpaperList = builtins.filter isImage (builtins.attrNames wallpapers);
  sortedWallpapers = builtins.sort (a: b: a < b) wallpaperList;
  numWallpapers = builtins.length sortedWallpapers;
  dayIndex = 0; # Fixed for now, change to desired index (0-4)
  selectedWallpaper = if numWallpapers > 0 then builtins.elemAt sortedWallpapers dayIndex else "";
in
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
    opencode
    ollama
    swaybg

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

  home.sessionVariables = {
    EDITOR = "evil-helix";
    VISUAL = "evil-helix";
  };

  stylix = {
    enable = true;
    base16Scheme = "${pkgs.base16-schemes}/share/themes/gruvbox-dark-hard.yaml";
    polarity = "dark";
    enableReleaseChecks = false;
    image = builtins.path { path = ../../wallpapers/Akai.jpeg; };
  };

  home.stateVersion = "25.05";
}
