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

  programs.zoxide = {
    enable = true;
    enableZshIntegration = true;
  };

  home.packages = with pkgs; [
    inputs.llm-agents.packages.${pkgs.system}.qwen-code
    inputs.llm-agents.packages.${pkgs.system}.forge
    inputs.llm-agents.packages.${pkgs.system}.opencode
    inputs.llm-agents.packages.${pkgs.system}.pi
    inputs.llm-agents.packages.${pkgs.system}.kilocode-cli
    inputs.llm-agents.packages.${pkgs.system}.gemini-cli
    inputs.llm-agents.packages.${pkgs.system}.copilot-cli
    inputs.llm-agents.packages.${pkgs.system}.jules
    inputs.llm-agents.packages.${pkgs.system}.omp
    inputs.antigravity-nix.packages.${pkgs.system}.default
    inputs.evil-helix.packages.${pkgs.system}.default
    tree
    obs-studio
    mpv
    anki
    obsidian
    (pkgs.runCommand "reaper-wrapped"
      {
        nativeBuildInputs = [ pkgs.makeWrapper ];
      }
      ''
        mkdir -p $out/bin $out/share/applications
        makeWrapper ${pkgs.reaper}/bin/reaper $out/bin/reaper \
          --prefix LD_LIBRARY_PATH : "${pkgs.pipewire.jack}/lib:${pkgs.lilv}/lib:${pkgs.suil}/lib:${pkgs.lv2}/lib"

        # Copy .desktop file and fix Exec path to wrapped binary
        if [ -f ${pkgs.reaper}/share/applications/reaper.desktop ]; then
          sed 's|^Exec=.*|Exec=reaper|' ${pkgs.reaper}/share/applications/reaper.desktop \
            > $out/share/applications/reaper.desktop
        fi

        # Copy icons if present
        if [ -d ${pkgs.reaper}/share/icons ]; then
          cp -r ${pkgs.reaper}/share/icons $out/share/
        fi
      '')
    reaper-sws-extension
    reaper-reapack-extension

    # Audio plugins — FOSS, high quality
    lsp-plugins          # Huge suite: EQ, dynamics, reverb, multiband, etc.
    guitarix             # Virtual guitar amp + effects (standalone & LV2)
    gxplugins-lv2        # Extra Guitarix LV2 pedals
    neural-amp-modeler-lv2 # Neural network amp sim (load free captures from tonehunt.org)
    airwindows-lv2       # Chris Johnson's plugins — saturation, EQ, compression
    zam-plugins          # ZamAudio: compressors, EQ, limiter
    dragonfly-reverb     # Hall-style reverb
    x42-plugins          # Meters, tuners, utilities by Robin Gareus
    calf                 # Calf Studio Gear plugins

    # Focusrite Scarlett Solo 3rd Gen tools
    alsa-scarlett-gui    # GUI for hardware mixer / Air / Pad / monitoring
    scarlett2            # Firmware management utility

    # JACK / PipeWire routing GUIs
    qpwgraph             # PipeWire-native patchbay for audio/MIDI routing
    qjackctl             # Classic JACK control + patchbay with transport

    # Libraries REAPER needs for LV2 plugin scanning
    lilv                 # LV2 plugin discovery library
    suil                 # LV2 UI host library
    lv2                  # LV2 specification / utils

    zotero
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
    kdePackages.okular
    teams-for-linux

    # R and RStudio Setup
    (pkgs.rWrapper.override {
      packages = with pkgs.rPackages; [
        asbio
        rmarkdown
        knitr
        car
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
 # # rstudio - npmDepsHash fixed in flake.nix overlay (see NixOS/nixpkgs#475882)
 # (pkgs.rstudioWrapper.override {
 #   packages = with pkgs.rPackages; [
 #     asbio
 #     rmarkdown
 #     knitr
 #     car
 #     tidyverse
 #     ggplot2
 #     lubridate
 #     tinytex
 #     languageserver
 #     htmlwidgets
 #     jsonlite
 #     evaluate
 #   ];
 # })

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
    BROWSER = "firefox";
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
    # REAPER needs lilv in LD_LIBRARY_PATH to scan LV2 plugins,
    # and pipewire.jack so REAPER can load the JACK driver (PipeWire's libjack)
    LD_LIBRARY_PATH = "${pkgs.lilv}/lib:${pkgs.suil}/lib:${pkgs.lv2}/lib:${pkgs.pipewire.jack}/lib";
  };

  home.sessionPath = [
    "$HOME/.cargo/bin"
    "$HOME/.pi/agent/bin"
  ];

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

  # Symlink standard plugin dirs to nix profile so REAPER finds them
  # without relying on env vars (REAPER's scanner may not inherit them)
  home.activation.linkAudioPlugins = config.lib.dag.entryAfter [ "writeBoundary" ] ''
    # Remove old dirs/symlinks and recreate pointing to current profile
    for dir in .lv2 .vst .vst3 .clap; do
      target="$HOME/$dir"
      source="$HOME/.nix-profile/lib/$dir"
      if [ -L "$target" ] || [ -e "$target" ]; then
        rm -rf "$target"
      fi
      if [ -d "$source" ]; then
        ln -s "$source" "$target"
      fi
    done

    # Fix any comma-separated paths REAPER may have written in its ini
    if [ -f "$HOME/.config/REAPER/reaper.ini" ]; then
      ${pkgs.gnused}/bin/sed -i 's|,~/.nix-profile/lib/|;~/.nix-profile/lib/|g' "$HOME/.config/REAPER/reaper.ini"
      ${pkgs.gnused}/bin/sed -i 's|,%CLAP_PATH%|;%CLAP_PATH%|g' "$HOME/.config/REAPER/reaper.ini"
    fi

    # Clear REAPER's plugin caches so it rescans fresh on next launch
    rm -f "$HOME/.config/REAPER/reaper-vstplugins64.ini"
  '';

  home.stateVersion = "25.05";
}
