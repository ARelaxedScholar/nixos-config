{
  config,
  pkgs,
  inputs,
  currentTime,
  ...
}:

let
  wallpapers = builtins.readDir ../../wallpapers;
  isImage = name: builtins.match ".*\\.(jpg|jpeg|png|gif|bmp|webp)" name != null;
  wallpaperList = builtins.filter isImage (builtins.attrNames wallpapers);
  sortedWallpapers = builtins.sort (a: b: a < b) wallpaperList;
  numWallpapers = builtins.length sortedWallpapers;
  
  # Calculate day-based index for rotation
  secondsPerDay = 86400;
  daysSinceEpoch = currentTime / secondsPerDay;
  dayIndex = if numWallpapers > 0 then builtins.floor (daysSinceEpoch) else 0;
  wallpaperIndex = if numWallpapers > 0 then (dayIndex - (dayIndex / numWallpapers) * numWallpapers) else 0;
  
  selectedWallpaper = if numWallpapers > 0 
    then builtins.elemAt sortedWallpapers wallpaperIndex 
    else "Akai.jpeg";
  
  wallpaperPath = ../../wallpapers + "/${selectedWallpaper}";
in
{
  imports = [
    inputs.stylix.homeModules.stylix
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
    # Make wallpaper path available to niri config
    WALLPAPER_PATH = "${wallpaperPath}";
  };

  stylix = {
    enable = true;
    base16Scheme = "${pkgs.base16-schemes}/share/themes/gruvbox-dark-hard.yaml";
    polarity = "dark";
    enableReleaseChecks = false;
    # Use the rotating wallpaper
    image = builtins.path { path = wallpaperPath; };
  };

  home.stateVersion = "25.05";
}
