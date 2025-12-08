{
  config,
  pkgs,
  inputs,
  ...
}:

let
  wallpaperList = ["Akai.jpeg" "Ao.png" "Kiiro.jpg" "Kurimuzon.png" "Midori.jpg"];
  sortedWallpapers = builtins.sort (a: b: a < b) wallpaperList;
  numWallpapers = builtins.length sortedWallpapers;
  daysSinceEpoch = builtins.div builtins.currentTime 86400;
  dayIndex = daysSinceEpoch - (numWallpapers * (builtins.div daysSinceEpoch numWallpapers));
  selectedWallpaper = builtins.elemAt sortedWallpapers dayIndex;
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
    image = /home/user/Pictures/Wallpapers/${selectedWallpaper};
    polarity = "dark";
  };

  home.stateVersion = "25.05";
}
