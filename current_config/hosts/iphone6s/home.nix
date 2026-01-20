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
    # Use wlr portal for screencasting on wlroots-based compositors (Niri)
    org.freedesktop.impl.portal.Screenshot=wlr
    org.freedesktop.impl.portal.ScreenCast=wlr
  '';

  home.packages = with pkgs; [
    inputs.antigravity-nix.packages.x86_64-linux.default
    inputs.evil-helix.packages.x86_64-linux.default
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
    zed-editor

    # fonts
    noto-fonts-cjk-sans
    ipafont
    kochi-substitute
    noto-fonts
    noto-fonts-color-emoji
    wofi
    kdePackages.dolphin
    kdePackages.okular
    
    # R Markdown
    (rWrapper.override { packages = with rPackages; [ rmarkdown knitr tidyverse tinytex ]; })
    rstudio
    
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
    EDITOR = "${inputs.evil-helix.packages.x86_64-linux.default}/bin/evil-helix";
    VISUAL = "${inputs.evil-helix.packages.x86_64-linux.default}/bin/evil-helix";
    BROWSER = "chromium";
    LIBINPUT_ACCEL_SPEED = "-0.5";
    LIBINPUT_ACCEL_PROFILE = "flat";
    LIBINPUT_DISABLE_WHILE_TYPING = "1";
    GDK_BACKEND = "wayland,x11";
    ELECTRON_OZONE_PLATFORM_HINT = "auto";
    ELECTRON_OZONE_PLATFORM = "wayland";
    SDL_VIDEODRIVER = "wayland";
    _JAVA_AWT_WM_NONREPARENTING = "1";
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

  # Set default applications
  xdg.mimeApps = {
    enable = true;
    defaultApplications = {
      "text/html" = [ "chromium.desktop" ];
      "x-scheme-handler/http" = [ "chromium.desktop" ];
      "x-scheme-handler/https" = [ "chromium.desktop" ];
      "x-scheme-handler/about" = [ "chromium.desktop" ];
      "x-scheme-handler/unknown" = [ "chromium.desktop" ];
      
      "inode/directory" = [ "org.kde.dolphin.desktop" ];
      
      "application/pdf" = [ "org.kde.okular.desktop" ];
      "application/x-pdf" = [ "org.kde.okular.desktop" ];
      "application/postscript" = [ "org.kde.okular.desktop" ];
      
      "audio/mpeg" = [ "mpv.desktop" ];
      "audio/*" = [ "mpv.desktop" ];
      "video/*" = [ "mpv.desktop" ];
      
      "image/*" = [ "org.kde.gwenview.desktop" ];
    };
  };

  home.stateVersion = "25.05";
}
