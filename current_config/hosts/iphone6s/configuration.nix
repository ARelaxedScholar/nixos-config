{
  inputs,
  config,
  lib,
  pkgs,
  ...
}:
let
  ocrmypdf-paddleocr-plugin = pkgs.python3Packages.buildPythonPackage rec {
    pname = "ocrmypdf-paddleocr";
    version = "0.1.1";
    src = pkgs.fetchFromGitHub {
      owner = "clefru";
      repo = "ocrmypdf-paddleocr";
      rev = "master";
      sha256 = "sha256-Cai/IqKdrL8L2ymT1z/DanE4j9xA3U2g0yVIo9viitE=";
    };
    pyproject = true;
    nativeBuildInputs = with pkgs.python3Packages; [
      setuptools
      setuptools-scm
    ];
    propagatedBuildInputs = with pkgs.python3Packages; [
      ocrmypdf
      (paddleocr.override { paddlepaddle = paddlepaddle; })
      paddlepaddle
      pillow
    ];
    doCheck = false;
    pythonImportsCheck = [ "ocrmypdf_paddleocr" ];
  };

  python3WithPaddle = pkgs.python3.withPackages (
    ps: with ps; [
      ocrmypdf
      ocrmypdf-paddleocr-plugin
    ]
  );

  ocrmypdf-paddleocr = pkgs.writeShellScriptBin "ocrmypdf-paddleocr" ''
    exec ${python3WithPaddle}/bin/ocrmypdf "$@"
  '';

  studio-aggregate = pkgs.writeShellScriptBin "studio-aggregate" ''
    PL="${pkgs.pipewire}/bin/pw-link"
    PACTL="${pkgs.pulseaudio}/bin/pactl"

    SINK="full_studio_input"

    log() { echo "[studio-aggregate] $*"; }

    # Wait for PipeWire + PulseAudio bridge to be ready
    for i in $(seq 1 60); do
      if $PACTL info &>/dev/null; then
        break
      fi
      log "Waiting for PipeWire/PulseAudio... ($i/60)"
      sleep 1
    done

    # Create the aggregate sink if it doesn't exist
    if $PACTL list sinks short | grep -q "$SINK"; then
      log "Sink $SINK already exists"
    else
      log "Creating null sink..."
      $PACTL load-module module-null-sink \
        sink_name="$SINK" \
        sink_properties='device.description="3-Channel Recording (Focusrite + USB Mic)" node.name="full_studio_input" node.description="3-Channel Recording (Focusrite + USB Mic)"' \
        channels=4 \
        channel_map=front-left,front-right,side-left,side-right \
        || { log "pactl load-module failed"; exit 1; }
      sleep 2
    fi

    log "All sinks:"
    $PACTL list sinks short

    # Get sink playback (input) ports
    IN_PORTS="$($PL -i 2>/dev/null || true)"
    SINK_PORTS=$(echo "$IN_PORTS" | grep -i "$SINK" || true)
    P1=$(echo "$SINK_PORTS" | grep -E '(playback|in)_(FL|1)' | head -1)
    P2=$(echo "$SINK_PORTS" | grep -E '(playback|in)_(FR|2)' | head -1)
    P3=$(echo "$SINK_PORTS" | grep -E '(playback|in)_(SL|RL|3)' | head -1)
    log "Sink ports: P1='$P1' P2='$P2' P3='$P3'"

    # --- Strategy 1: use pw-link -o (works when devices are active) ---
    OUT_PORTS="$($PL -o 2>/dev/null || true)"
    log "pw-link -o ports:"
    echo "$OUT_PORTS"

    FOCUSRITE_PORTS=$(echo "$OUT_PORTS" | grep -iE "Focusrite|Scarlett" || true)
    MIC_PORTS=$(echo "$OUT_PORTS" | grep -iE "Condenser|Microphone|Generic.*USB" || true)

    # --- Strategy 2: fallback to pactl source names + common port suffixes ---
    try_link_source() {
      local src="$1" dst="$2" label="$3"
      [ -n "$src" ] || return 1
      [ -n "$dst" ] || return 1
      for suffix in capture_AUX0 capture_AUX1 capture_1 capture_FL capture_MONO out_1 out_FL out_MONO; do
        local port="$src:$suffix"
        local err
        err="$($PL "$port" "$dst" 2>&1)" && { log "$label linked via $port"; return 0; }
        if echo "$err" | grep -qi "file exists"; then
          log "$label already linked ($port)"
          return 0
        fi
      done
      return 1
    }

    # Helper: link two ports, treating "already linked" as success
    link_port() {
      local src="$1" dst="$2" label="$3"
      [ -n "$src" ] || { log "$label: missing source"; return 1; }
      [ -n "$dst" ] || { log "$label: missing destination"; return 1; }
      local err
      err="$($PL "$src" "$dst" 2>&1)" && { log "$label linked"; return 0; }
      if echo "$err" | grep -qi "file exists"; then
        log "$label already linked"
      else
        log "$label link failed: $err"
      fi
    }

    if [ -z "$FOCUSRITE_PORTS" ] || [ -z "$MIC_PORTS" ]; then
      log "pw-link -o didn't show devices; falling back to pactl source names"
      log "PulseAudio sources:"
      $PACTL list sources short || true

      FOCUS_SRC=$($PACTL list sources short | grep -iE "Focusrite|Scarlett" | awk '{print $2}' | head -1)
      MIC_SRC=$($PACTL list sources short | grep -iE "Condenser|Microphone|Generic.*USB" | awk '{print $2}' | head -1)
      log "Focus source='$FOCUS_SRC' Mic source='$MIC_SRC'"

      if [ -n "$FOCUS_SRC" ] && [ -n "$P1" ] && [ -n "$P2" ]; then
        try_link_source "$FOCUS_SRC" "$P1" "Focusrite L" || \
          try_link_source "$FOCUS_SRC" "$P1" "Focusrite L (2nd try)"
        try_link_source "$FOCUS_SRC" "$P2" "Focusrite R" || \
          try_link_source "$FOCUS_SRC" "$P2" "Focusrite R (2nd try)"
      fi
      if [ -n "$MIC_SRC" ] && [ -n "$P3" ]; then
        try_link_source "$MIC_SRC" "$P3" "Mic" || \
          try_link_source "$MIC_SRC" "$P3" "Mic (2nd try)"
      fi
    else
      # Strategy 1 succeeded: link the discovered ports directly
      F1=$(echo "$FOCUSRITE_PORTS" | grep -E '(capture|out)_(AUX0|1|FL|MONO)' | head -1)
      F2=$(echo "$FOCUSRITE_PORTS" | grep -E '(capture|out)_(AUX1|2|FR)' | head -1)
      M1=$(echo "$MIC_PORTS" | grep -E '(capture|out)_(AUX0|1|FL|MONO)' | head -1)

      link_port "$F1" "$P1" "Focusrite L"
      link_port "$F2" "$P2" "Focusrite R"
      link_port "$M1" "$P3" "Mic"
    fi

    log "Aggregate sink $SINK ready. Holding..."
    while true; do
      sleep 60
    done
  '';
in
{
  imports = [
    ./hardware-configuration.nix
    ../../modules/kokoro-fastapi.nix
  ];

  # Enabling the experimental features
  nix.settings = {
    substituters = [
      "https://niri.cachix.org"
      "https://walker.cachix.org"
      "https://walker-git.cachix.org"
      "https://zed.cachix.org"
      "https://cache.numtide.com"
    ];
    trusted-public-keys = [
      "niri.cachix.org-1:Wv00m07PsuJ90V2jMZW5ajB8PxyYcnyk8TmgV0/2060="
      "walker.cachix.org-1:fG8q+uAaMqhsMxWjwvk0IMb4mFPFLqHjuvfwQxE4oJM="
      "walker-git.cachix.org-1:vmC0ocfPWh0S/vRAQGtChuiZBTAe4wiKDeyyXM0/7pM="
      "zed.cachix.org-1:/pHQ6dpMsAZk2DiP4WCL0p9YDNKWj2Q5FL20bNmw1cU="
      "niks3.numtide.com-1:DTx8wZduET09hRmMtKdQDxNNthLQETkc/yaX7M4qK0g="
    ];
    trusted-users = [
      "root"
      "user"
    ];
    experimental-features = [
      "nix-command"
      "flakes"
    ];
  };
  # Use the systemd-boot EFI boot loader.
  boot.supportedFilesystems = [ "fuse" ];

  boot.loader.systemd-boot.enable = false;
  boot.loader.grub.enable = true;
  boot.loader.grub.efiSupport = true;
  boot.loader.grub.efiInstallAsRemovable = lib.mkForce false;
  boot.loader.efi.canTouchEfiVariables = lib.mkForce true;

  # bluetooth
  hardware.bluetooth.enable = true;
  # seatd for session management (required for niri)
  services.seatd.enable = true;
  services.seatd.logLevel = "info";
  # polkit for authentication
  security.polkit.enable = true;
  # RTKit for PipeWire real-time scheduling (critical for pro audio)
  security.rtkit.enable = true;

  # Use latest kernel.
  boot.kernelPackages = pkgs.linuxPackages;

  networking.hostName = "iphone6s";
  networking.networkmanager.enable = true;
  networking.hostId = "deadbeef";

  # setup for eduroam
  environment.etc."NetworkManager/system-connections/eduroam.nmconnection" = {
    mode = "0600";
    text = ''
      [connection]
      id=eduroam
      type=wifi

      [wifi]
      mode=infrastructure
      ssid=eduroam

      [wifi-security]
      key-mgmt=wpa-eap

      [802-1x]
      eap=peap;
      identity=akoua067@uottawa.ca
      anonymous-identity=akoua067@uottawa.ca
      phase2-auth=mschapv2
      ca-cert=/etc/ssl/certs/uottawa-bundle.crt

      [ipv4]
      method=auto

      [ipv6]
      addr-gen-mode=stable-privacy
      method=auto
    '';
  };

  # Include your cert bundle in the system
  security.pki.certificateFiles = [
    ./uottawa-bundle.crt
  ];

  # Set your time zone.
  time.timeZone = "America/New_York";

  # Select internationalisation properties.
  i18n.defaultLocale = "en_US.UTF-8";

  i18n.inputMethod = {
    enable = true;
    type = "fcitx5";
    fcitx5.addons = with pkgs; [
      fcitx5-mozc
      fcitx5-gtk
    ];
  };

  # Enable CUPS to print documents.
  services.printing.enable = true;

  # TTS Service
  services.kokoro-fastapi = {
    enable = true;
    port = 8880;
    openFirewall = false; # Keep false if only local applications need to access the API
  };

  # Enable sound and screen sharing.
  services.pipewire = {
    enable = true;
    pulse.enable = true;
    alsa.enable = true;
    alsa.support32Bit = true;
    jack.enable = true;
    wireplumber.enable = true;
  };

  services.gvfs.enable = true;
  services.avahi = {
    enable = true;
    nssmdns4 = true;
    openFirewall = true;
  };

  # Enable Niri
  programs.niri = {
    enable = true;
    package =
      pkgs.runCommand "niri-wrapped"
        {
          nativeBuildInputs = [ pkgs.makeWrapper ];
          buildInputs = [
            pkgs.xorg.libXcursor
            pkgs.xorg.libX11
            pkgs.xorg.libXrender
            pkgs.xorg.libXi
            pkgs.xorg.libXfixes
            pkgs.xorg.libXext
          ];
        }
        ''
          mkdir -p $out/bin
          makeWrapper ${inputs.niri.packages.${pkgs.system}.niri-stable}/bin/niri $out/bin/niri \
            --set LD_LIBRARY_PATH "${pkgs.xorg.libXcursor}/lib:${pkgs.xorg.libX11}/lib:${pkgs.xorg.libXrender}/lib:${pkgs.xorg.libXi}/lib:${pkgs.xorg.libXfixes}/lib:${pkgs.xorg.libXext}/lib" \
            --set WINIT_UNIX_BACKEND wayland \
            --set WINIT_BACKEND wayland \
            --set WINIT_PLATFORM wayland \
            --unset DISPLAY \
            --unset XAUTHORITY \
            --prefix PATH : ${pkgs.xorg.libXcursor}/bin
        '';
  };

  # XDG Portal configuration - CRITICAL for file dialogs and screen sharing
  xdg.portal = {
    enable = true;
    wlr.enable = true;
    extraPortals = with pkgs; [
      xdg-desktop-portal-wlr
      xdg-desktop-portal-gnome
      xdg-desktop-portal-gtk
    ];
    # Required for xdg-desktop-portal >= 1.17
    config.common.default = "*";
  };

  # Ensure proper environment variables for Wayland
  environment.variables = {
    EDITOR = "evil-helix";
  };
  environment.sessionVariables = {
    NIXOS_OZONE_WL = "1";
    XDG_CURRENT_DESKTOP = "Niri";
    XDG_SESSION_TYPE = "wayland";
    XDG_SESSION_DESKTOP = "Niri";
    LIBINPUT_ACCEL_SPEED = "-0.5";
    LIBINPUT_ACCEL_PROFILE = "flat";
    LIBINPUT_DISABLE_WHILE_TYPING = "1";
    # OBS screen sharing on Wayland
    OBS_USE_EGL = "1";
    OBS_USE_WAYLAND = "1";
    QT_QPA_PLATFORM = "wayland";
    GDK_BACKEND = "wayland,x11";
    WINIT_UNIX_BACKEND = "wayland";
  };

  # Enable touchpad support (enabled default in most desktopManager).
  services.libinput = {
    enable = true;
    touchpad = {
      accelSpeed = "-0.5"; # 50% slower than default
      accelProfile = "flat"; # Predictable linear movement
      disableWhileTyping = true; # Prevent cursor jumps while typing
      tapping = true; # Enable tap-to-click (required for Niri)
      naturalScrolling = false; # Let Niri handle scroll direction
    };
  };

  nixpkgs.config.allowUnfree = true;
  nixpkgs.config.permittedInsecurePackages = [
    "electron-38.8.4"
  ];

  environment.shells = with pkgs; [ zsh ];
  programs.zsh.enable = true;
  programs.fuse.userAllowOther = true;

  # Define my user
  users.users.user = {
    isNormalUser = true;
    hashedPassword = "$6$E/iKuuVKtIZtoU30$l/3BBHa.MAxX5P9Nr/j8r9DjzbWX2F6H8KfwigrTvnQMFz7yG99iO9NSSNiR2hQ.S9gupox8LjfGiEA6cWuL5/";
    extraGroups = [
      "wheel"
      "docker"
      "seat"
      "video"
      "audio"
      "input"
      "fuse"
    ]; # Enable 'sudo' for the user.
    shell = pkgs.zsh;
  };
  virtualisation.docker.enable = true;

  # Auto-login
  services.getty.autologinUser = "user";

  programs.firefox.enable = true;

  # List packages installed in system profile.
  environment.systemPackages = with pkgs; [
    imagemagick
    tesseract
    tmux
    git-lfs
    sshfs-fuse
    home-manager
    dbeaver-bin
    bun
    cachix
    chromium
    libinput
    xwayland
    xwayland-satellite
    xauth
    docker-compose
    eza
    htop
    zoxide
    fastfetch
    vim
    wget
    git
    kitty
    nixfmt-tree
    nixfmt
    btop
    gammastep

    nh
    nom
    nvd

    # Portal debugging tools
    xdg-utils
    dbus
    zoom-us

    # Development tools
    nodejs_22
    uv
    R
    pandoc
    quarto
    texlive.combined.scheme-full

    # Default applications
    mpv
    kdePackages.gwenview
    libreoffice
    tauon
    jellyfin-media-player

    # Utilities
    which
    p7zip
    kdePackages.ark
    ffmpegthumbnailer
    kdePackages.kio-extras
    kdePackages.kio-admin
    blueman
    networkmanagerapplet
    swaynotificationcenter
    pavucontrol
    pulseaudio
    studio-aggregate
    tailscale
    nomachine-client
    kdePackages.fcitx5-configtool

    # Graphics/OpenGL

    mesa
    xorg.libXcursor
    xorg.libX11
    xorg.libXrandr
    xorg.libXrender
    xorg.libXi
    xorg.libXfixes
    xorg.libXext
    libxcb
    # OCR tools
    ocrmypdf
    ocrmypdf-paddleocr
  ];
  # configuration.nix or home-manager
  programs.direnv = {
    enable = true;
    nix-direnv.enable = true; # faster nix integration, highly recommended
  };
  # Enable the OpenSSH daemon.
  services.openssh.enable = true;

  services.tailscale.enable = true;

  fileSystems."/home/user/Documents/SwagWatch_App/remote-engine" = {
    device = "user@nixos:/mnt/data/swagwatch-engine";
    fsType = "sshfs";
    options = [
      "allow_other"
      "IdentityFile=/home/user/.ssh/id_rsa"
      "x-systemd.automount" # Mounts on first access
      "noauto" # Don't mount immediately at boot
      "_netdev" # Tells systemd to wait for network
      "reconnect" # Handle network drops gracefully
      "ServerAliveInterval=15"
    ];
  };

  # Ensure D-Bus is running properly
  services.dbus.enable = true;

  # Copy the NixOS configuration file and link it from the resulting system (I am using flakes)
  system.copySystemConfiguration = false;

  # Hardware database entries for libinput touchpad settings (Wayland)
  services.udev.extraHwdb = ''
    # Dell touchpad sensitivity adjustments
    evdev:input:b0018v0488p121Fe0100*
     LIBINPUT_ATTR_ACCEL_SPEED=-0.5
     LIBINPUT_ATTR_ACCEL_PROFILE=flat
     LIBINPUT_ATTR_DISABLE_WHILE_TYPING=1
     LIBINPUT_ATTR_PALM_PRESSURE_THRESHOLD=250
     LIBINPUT_ATTR_TAP_ENABLED=1
  '';

  # Udev rules as alternative (may be needed for some systems)
  services.udev.extraRules = ''
    # Touchpad sensitivity adjustments for libinput (Wayland)
    ACTION=="add|change", KERNEL=="event[0-9]*", ENV{ID_VENDOR_ID}=="0488", ENV{ID_MODEL_ID}=="121f", ENV{LIBINPUT_ATTR_ACCEL_SPEED}="-0.5", ENV{LIBINPUT_ATTR_ACCEL_PROFILE}="flat", ENV{LIBINPUT_ATTR_DISABLE_WHILE_TYPING}="1", ENV{LIBINPUT_ATTR_PALM_PRESSURE_THRESHOLD}="250", ENV{LIBINPUT_ATTR_TAP_ENABLED}="1"
  '';

  # ZRAM compression and swap file configuration
  zramSwap = {
    enable = true;
    algorithm = "zstd";
    memoryPercent = 50;
  };

  # 32GB swap file on disk
  swapDevices = [
    {
      device = "/dev/zvol/zroot/swap";
      size = 1024 * 32; # 32GB in MB
    }
  ];
  systemd.user.services.studio-aggregate = {
    description = "Studio aggregate audio sink (Focusrite + USB mic)";
    bindsTo = [ "pipewire.service" "wireplumber.service" ];
    after = [ "pipewire.service" "wireplumber.service" "pipewire-pulse.service" ];
    wantedBy = [ "default.target" ];
    environment.XDG_RUNTIME_DIR = "%t";
    serviceConfig = {
      Type = "simple";
      ExecStart = "${studio-aggregate}/bin/studio-aggregate";
      Restart = "on-failure";
      RestartSec = 10;
    };
  };

  # Should never change this
  system.stateVersion = "25.05";
}
