{
  config,
  pkgs,
  inputs,
  ...
}:

let
  zebralette = pkgs.stdenv.mkDerivation rec {
    pname = "zebralette";
    version = "3.0.0-20399";

    src = pkgs.fetchurl {
      url = "https://u-he.com/downloads/betas/public/zebralette3/Zebralette3_300_20399_Linux.tar.xz";
      sha256 = "10655vh5xsw65k4brlrq4qa6ax5bqgqyzg9w9n4h49viwv6d2d6z";
    };

    nativeBuildInputs = [ pkgs.autoPatchelfHook ];

    buildInputs = with pkgs; [
      stdenv.cc.cc.lib
      libx11
      libxext
      libxcb
      libxcb-keysyms
      libxcb-util
      cairo
      freetype
      zlib
      glib
    ];

    sourceRoot = "Zebralette3-20399/Zebralette3";

    installPhase = ''
      runHook preInstall
      mkdir -p $out/lib/vst
      # Keep the full plugin directory so Zebralette finds its Data/Presets
      cp -r . $out/lib/vst/Zebralette3
      # Remove installer dialogs — not needed for VST operation and they pull in gtk3
      rm -f $out/lib/vst/Zebralette3/dialog $out/lib/vst/Zebralette3/dialog.64
      # Symlink the .so to the top-level VST dir for host discovery
      ln -s Zebralette3/Zebralette3.64.so $out/lib/vst/Zebralette3.64.so
      runHook postInstall
    '';

    meta = {
      description = "u-he Zebralette 3 — free spectral synthesizer (VST2)";
      homepage = "https://u-he.com/products/zebralette/";
      license = pkgs.lib.licenses.unfree;
      platforms = [ "x86_64-linux" ];
    };
  };

  convertwithmoss = pkgs.stdenv.mkDerivation rec {
    pname = "convertwithmoss";
    version = "17.1.0";

    src = pkgs.fetchurl {
      url = "https://www.mossgrabers.de/Software/ConvertWithMoss/ConvertWithMoss-Installers-ubuntu-latest/convertwithmoss_${version}_amd64.deb";
      sha256 = "17f6znn1iy76q3nnn9xw0hl7ll5wj3q9z252zy3hwwzpd0zvz5m3";
    };

    nativeBuildInputs = [
      pkgs.makeWrapper
      pkgs.zstd
    ];

    unpackPhase = ''
      ar x $src
      tar --zstd -xf data.tar.zst
    '';

    installPhase = ''
      runHook preInstall
      mkdir -p $out/opt $out/bin
      cp -r opt/convertwithmoss $out/opt/
      makeWrapper $out/opt/convertwithmoss/bin/ConvertWithMoss $out/bin/ConvertWithMoss
      runHook postInstall
    '';

    meta = {
      description = "ConvertWithMoss — converts multisamples (Kontakt, SFZ, WAV, etc.) to Decent Sampler and other formats";
      homepage = "https://www.mossgrabers.de/Software/ConvertWithMoss/ConvertWithMoss.html";
      license = pkgs.lib.licenses.lgpl3;
      platforms = [ "x86_64-linux" ];
    };
  };

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
    inputs.llm-agents.packages.${pkgs.system}.codex
    pkgs.hermes-agent-latest
    inputs.llm-agents.packages.${pkgs.system}.kilocode-cli
    inputs.llm-agents.packages.${pkgs.system}.gemini-cli
    inputs.llm-agents.packages.${pkgs.system}.copilot-cli
    inputs.llm-agents.packages.${pkgs.system}.jules
    inputs.llm-agents.packages.${pkgs.system}.claude-code
    inputs.llm-agents.packages.${pkgs.system}.omp
    inputs.llm-agents.packages.${pkgs.system}.antigravity-cli
    inputs.llm-agents.packages.${pkgs.system}.reasonix
    inputs.antigravity-nix.packages.${pkgs.system}.default
    inputs.evil-helix.packages.${pkgs.system}.default
    tree
    obs-studio
    mpv
    anki
    upscayl

    # Audio plugins — FOSS, high quality
    lsp-plugins # Huge suite: EQ, dynamics, reverb, multiband, etc.
    guitarix # Virtual guitar amp + effects (standalone & LV2)
    gxplugins-lv2 # Extra Guitarix LV2 pedals
    neural-amp-modeler-lv2 # Neural network amp sim (load free captures from tonehunt.org)
    airwindows-lv2 # Chris Johnson's plugins — saturation, EQ, compression
    zam-plugins # ZamAudio: compressors, EQ, limiter
    dragonfly-reverb # Hall-style reverb
    x42-plugins # Meters, tuners, utilities by Robin Gareus
    calf # Calf Studio Gear plugins

    # Focusrite Scarlett Solo 3rd Gen tools
    alsa-scarlett-gui # GUI for hardware mixer / Air / Pad / monitoring
    scarlett2 # Firmware management utility

    # JACK / PipeWire routing GUIs
    qpwgraph # PipeWire-native patchbay for audio/MIDI routing
    qjackctl # Classic JACK control + patchbay with transport

    # Libraries REAPER needs for LV2 plugin scanning
    lilv # LV2 plugin discovery library
    suil # LV2 UI host library
    lv2 # LV2 specification / utils

    # Windows VST bridge — run Windows plugins in REAPER via Wine
    wineWow64Packages.staging # Wine with 32/64-bit support and staging patches
    yabridge # VST2/VST3 bridge host
    yabridgectl # Manage yabridge installations (sync, add, status)
    carla # Alternative plugin host / rack (can also bridge via Wine)

    # Synths
    zebralette # u-he Zebralette 3 — free spectral synth (native Linux VST2)
    surge-xt # Surge XT — open-source hybrid synth (VST3/LV2/CLAP/standalone)

    # Drum machines
    hydrogen # Pattern-based drum machine / sequencer

    # Samplers
    decent-sampler # Decent Sampler — high-quality sample player (VST2/VST3, free)
    sfizz # sfizz — high-quality SFZ sampler engine (LV2/standalone)

    # Sample conversion
    convertwithmoss # Converts Kontakt/SFZ/WAV/etc. to Decent Sampler format

    # Music visualizer
    projectm-sdl-cpp # Milkdrop-compatible audio visualizer (standalone SDL app)
    libprojectm # ProjectM visualization library

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
    # yabridge lib is needed so REAPER can host Windows VST2/VST3 plugins
    LD_LIBRARY_PATH = "${pkgs.lilv}/lib:${pkgs.suil}/lib:${pkgs.lv2}/lib:${pkgs.pipewire.jack}/lib:${pkgs.yabridge}/lib";
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

  # Create a .desktop entry for ProjectM (the nixpkg doesn't ship one)
  xdg.desktopEntries.projectm = {
    name = "ProjectM";
    comment = "Milkdrop-compatible audio visualizer";
    exec = "projectMSDL";
    categories = [
      "AudioVideo"
      "Audio"
    ];
    type = "Application";
    terminal = false;
  };

  # Create standard XDG user directories (Pictures, Documents, Downloads, etc.)
  xdg.userDirs = {
    enable = true;
    createDirectories = true;
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

    # Sync yabridge — regenerates .so wrappers for any Windows VSTs added with
    #   yabridgectl add ~/path/to/windows/plugins
    # This keeps the bridge up-to-date after nix profile changes.
    if command -v yabridgectl &>/dev/null; then
      export PATH="${pkgs.yabridge}/bin:$PATH"
      # Run this out-of-band so a stalled plugin scan cannot block activation.
      ${pkgs.coreutils}/bin/nohup yabridgectl sync >/dev/null 2>&1 </dev/null &
    fi

    # Clear REAPER's plugin caches so it rescans fresh on next launch
    rm -f "$HOME/.config/REAPER/reaper-vstplugins64.ini"
  '';

  # Patch kimi-coding provider: kimi-k2.6 rejects reasoning_effort/thinking
  # on api.moonshot.ai/v1, causing HTTP 400. Override bundled profile.
  home.file.".hermes/plugins/model-providers/kimi-coding/__init__.py".text = ''
    from typing import Any
    from providers import register_provider
    from providers.base import OMIT_TEMPERATURE, ProviderProfile

    class KimiProfile(ProviderProfile):
        """Kimi/Moonshot — temperature omitted, NO reasoning extras."""

        def build_api_kwargs_extras(
            self, *, reasoning_config: dict | None = None, **context
        ) -> tuple[dict[str, Any], dict[str, Any]]:
            # kimi-k2.6 (and possibly other new models) reject reasoning_effort
            # and extra_body.thinking on the /v1 endpoint with HTTP 400.
            return {}, {}


    kimi = KimiProfile(
        name="kimi-coding",
        aliases=("kimi", "moonshot", "kimi-for-coding"),
        env_vars=("KIMI_API_KEY", "KIMI_CODING_API_KEY"),
        base_url="https://api.moonshot.ai/v1",
        fixed_temperature=OMIT_TEMPERATURE,
        default_max_tokens=32000,
        default_headers={"User-Agent": "hermes-agent/1.0"},
        default_aux_model="kimi-k2-turbo-preview",
    )

    kimi_cn = KimiProfile(
        name="kimi-coding-cn",
        aliases=("kimi-cn", "moonshot-cn"),
        env_vars=("KIMI_CN_API_KEY",),
        base_url="https://api.moonshot.cn/v1",
        fixed_temperature=OMIT_TEMPERATURE,
        default_max_tokens=32000,
        default_headers={"User-Agent": "hermes-agent/1.0"},
        default_aux_model="kimi-k2-turbo-preview",
    )

    register_provider(kimi)
    register_provider(kimi_cn)
  '';

  home.stateVersion = "25.05";
}
