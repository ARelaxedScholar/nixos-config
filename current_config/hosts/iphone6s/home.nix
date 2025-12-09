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
  
  # Default to first wallpaper for stylix
  defaultWallpaper = if numWallpapers > 0 
    then builtins.elemAt sortedWallpapers 0
    else "Akai.jpeg";
  
  wallpaperPath = ../../wallpapers + "/${defaultWallpaper}";
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
    
    # Daily wallpaper rotation script
    (writeShellScriptBin "set-daily-wallpaper" ''
      WALLPAPER_DIR="${../../wallpapers}"
      WALLPAPERS=($(ls "$WALLPAPER_DIR"/*.{jpg,jpeg,png,gif,bmp,webp} 2>/dev/null | sort))
      NUM_WALLPAPERS=''${#WALLPAPERS[@]}
      
      if [ $NUM_WALLPAPERS -eq 0 ]; then
        echo "No wallpapers found in $WALLPAPER_DIR"
        exit 1
      fi
      
      # Calculate index based on day of year
      DAY_OF_YEAR=$(date +%j)
      INDEX=$((DAY_OF_YEAR % NUM_WALLPAPERS))
      SELECTED_WALLPAPER="''${WALLPAPERS[$INDEX]}"
      
      echo "Setting wallpaper: $SELECTED_WALLPAPER"
      
      # Kill existing swaybg instances
      ${pkgs.procps}/bin/pkill swaybg 2>/dev/null || true
      
      # Set new wallpaper
      ${pkgs.swaybg}/bin/swaybg -i "$SELECTED_WALLPAPER" &
    '')
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
    # Let stylix automatically generate colors from the wallpaper
    autoEnable = true;
    polarity = "dark";
    enableReleaseChecks = false;
    # Stylix will extract colors from this image
    image = builtins.path { path = wallpaperPath; };
    
    # Customize opacity for terminals and popups
    opacity = {
      terminal = 0.95;
      popups = 0.95;
    };
  };

  home.stateVersion = "25.05";
}
