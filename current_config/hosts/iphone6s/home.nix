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
  defaultWallpaper = if numWallpapers > 0 then builtins.elemAt sortedWallpapers 0 else "Akai.jpeg";

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
    opencode
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
    teams-for-linux

    # R and RStudio Setup
    (pkgs.rWrapper.override {
      packages = with pkgs.rPackages; [
        rmarkdown
        knitr
        tidyverse
        ggplot2
        lubridate
        tinytex
        languageserver
        htmlwidgets
        jsonlite
        evaluate
      ];
    })
    (pkgs.rstudioWrapper.override {
      packages = with pkgs.rPackages; [
        rmarkdown
        knitr
        tidyverse
        ggplot2
        lubridate
        tinytex
        languageserver
        htmlwidgets
        jsonlite
        evaluate
      ];
    })

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
    WINIT_UNIX_BACKEND = "wayland";
    GTK_IM_MODULE = "fcitx";
    QT_IM_MODULE = "fcitx";
    XMODIFIERS = "@im=fcitx";
    GLFW_IM_MODULE = "ibus";
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
      "video/mp4" = [ "mpv.desktop" ];
      "video/x-matroska" = [ "mpv.desktop" ];
      "video/webm" = [ "mpv.desktop" ];
      "video/quicktime" = [ "mpv.desktop" ];
      "video/x-msvideo" = [ "mpv.desktop" ];
      "video/x-flv" = [ "mpv.desktop" ];
      "video/mpeg" = [ "mpv.desktop" ];
      "video/*" = [ "mpv.desktop" ];

      "image/*" = [ "org.kde.gwenview.desktop" ];

      "application/zip" = [ "org.kde.ark.desktop" ];
      "application/x-7z-compressed" = [ "org.kde.ark.desktop" ];
      "application/x-rar" = [ "org.kde.ark.desktop" ];
      "application/x-tar" = [ "org.kde.ark.desktop" ];
    };
  };

  # Fcitx5 Configuration
  xdg.configFile."fcitx5/config" = {
    force = true;
    text = ''
      [Hotkey]
      # Trigger Key
      TriggerKeys=Shift+space
      # Enumerate Input Method Forward
      EnumerateForwardKeys=
      # Enumerate Input Method Backward
      EnumerateBackwardKeys=
      # Enumerate Next Input Method
      EnumerateNextIMKeys=
      # Enumerate Previous Input Method
      EnumeratePrevIMKeys=
      # Activate Input Method
      ActivateKeys=
      # Deactivate Input Method
      DeactivateKeys=
      # Toggle Input Method
      ToggleKeys=Shift+space
    '';
  };

  xdg.configFile."fcitx5/profile" = {
    force = true;
    text = ''
      [Groups/0]
      # Group Name
      Name=Default
      # Layout
      Default Layout=us
      # Default Input Method
      DefaultIM=keyboard-us

      [Groups/0/Items/0]
      # Name
      Name=keyboard-us
      # Layout
      Layout=

      [Groups/0/Items/1]
      # Name
      Name=mozc
      # Layout
      Layout=

      [GroupOrder]
      0=Default
    '';
  };

  home.stateVersion = "25.05";
}
