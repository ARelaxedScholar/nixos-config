{
  inputs,
  config,
  lib,
  pkgs,
  ...
}:
let
  pyPaddle = pkgs.python313;
  pyPaddlePackages = pkgs.python313Packages;

  ocrmypdf-paddleocr-plugin = pyPaddlePackages.buildPythonPackage rec {
    pname = "ocrmypdf-paddleocr";
    version = "0.1.1";
    src = pkgs.fetchFromGitHub {
      owner = "clefru";
      repo = "ocrmypdf-paddleocr";
      rev = "master";
      sha256 = "sha256-Cai/IqKdrL8L2ymT1z/DanE4j9xA3U2g0yVIo9viitE=";
    };
    pyproject = true;
    nativeBuildInputs = with pyPaddlePackages; [
      setuptools
      setuptools-scm
    ];
    propagatedBuildInputs = with pyPaddlePackages; [
      ocrmypdf
      (paddleocr.override { paddlepaddle = paddlepaddle; })
      paddlepaddle
      pillow
    ];
    doCheck = false;
    pythonImportsCheck = [ "ocrmypdf_paddleocr" ];
  };
  python3WithPaddle = pyPaddle.withPackages (
    ps: with ps; [
      ocrmypdf
      ocrmypdf-paddleocr-plugin
    ]
  );

  ocrmypdf-paddleocr = pkgs.writeShellScriptBin "ocrmypdf-paddleocr" ''
    exec ${python3WithPaddle}/bin/ocrmypdf "$@"
  '';

  kimi-code = pkgs.symlinkJoin {
    name = "kimi-code";
    paths = [
      (pkgs.writeShellScriptBin "kimi" ''
        exec ${pkgs.uv}/bin/uv tool run --python ${pkgs.python313}/bin/python3.13 kimi-cli "$@"
      '')
      (pkgs.writeShellScriptBin "kimi-cli" ''
        exec ${pkgs.uv}/bin/uv tool run --python ${pkgs.python313}/bin/python3.13 kimi-cli "$@"
      '')
    ];
  };

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
    ../../modules/uriel
  ];

  # Uriel life-OS umbrella service. Clause (X/social posting) is the first
  # submodule; more attach under services.uriel.* later.
  services.uriel = {
    enable = true;
    # Disabled by default because it builds the local Uriel Rust workspace,
    # which is not available from a binary cache.
    clause.enable = false;
    clause.engineUrl = "https://engine.swagwatch.app";
    clause.environmentFile = "/etc/uriel/clause.env";
    # clause.dryRun defaults to true — Approve never posts to X.
    # To enable the SwagWatch feed and (later) live posting, create
    # /etc/uriel/clause.env with ENGINE_API_KEY / DEEPSEEK_API_KEY / X_* tokens,
    # then set:  clause.environmentFile = "/etc/uriel/clause.env";
    # and, only after smoke-testing, clause.dryRun = false;
  };

  # Enabling the experimental features
  nix.settings = {
    substituters = [
      "https://cache.nixos.org"
      "https://niri.cachix.org"
      "https://walker.cachix.org"
      "https://walker-git.cachix.org"
      "https://zed.cachix.org"
      "https://cache.numtide.com"
    ];
    trusted-public-keys = [
      "cache.nixos.org-1:6NCHdD59X431o0gWypbMrAURkbJ16ZPMQFGspcDShjY="
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
  boot.loader.grub.device = lib.mkForce "nodev";
  boot.loader.grub.efiInstallAsRemovable = lib.mkForce false;
  boot.loader.efi.canTouchEfiVariables = lib.mkForce true;

  # === ZFS + Kernel tuning to prevent system freezes under load ===
  # Root cause: ZFS ARC had no cap and could consume ~14 GiB of 15 GiB RAM.
  # Under agentic loads, kernel reclaims ARC pages -> ARC eviction writes
  # dirty pages -> ZFS+LUKS write amplification -> I/O queue saturates ->
  # PostgreSQL checkpoint stalls (269s seen!) -> system I/O-freeze.
  #
  # Fix: cap ARC at 6 GiB (40% of RAM), reduce dirty data limits, lower
  # swappiness to avoid swapping ARC pages under memory pressure.
  boot.kernelParams = [
    # Cap ZFS ARC at 6 GiB (6,442,450,944 bytes) — was unlimited (14.4 GiB).
    # Prevents ARC from consuming all RAM and starving applications.
    "zfs.zfs_arc_max=6442450944"
    # Reduce max dirty data from 1.54 GiB to 768 MiB (804,782,080 bytes).
    # Prevents huge write bursts that stall the I/O path.
    "zfs.zfs_dirty_data_max=804782080"
    # Start throttling writes at 30% of dirty data max (down from 60%).
    # Smoother write throttling instead of sudden spikes.
    "zfs.zfs_delay_min_dirty_percent=30"
    # Flush dirty data to sync targets at 10% of max (keep default).
    "zfs.zfs_dirty_data_sync_percent=10"
  ];
  # Sysctl tuning for memory pressure handling
  boot.kernel.sysctl = {
    # Swappiness 60 — actively use the 39 GiB of swap (zram + zvol) under
    # memory pressure. Was 10, which made swap decorative: the kernel would
    # rather thrash RAM+I/O than page out cold cache pages. With Rust
    # compilation (LLVM codegen can eat 4-6 GiB per parallel job), swap
    # must actually be used to prevent ZFS eviction I/O death spiral.
    "vm.swappiness" = lib.mkOverride 0 60;
    # Reduce vfs_cache_pressure from 100 to 50 — less aggressive reclaim
    # of dentries/inodes, which reduces read I/O under memory pressure.
    "vm.vfs_cache_pressure" = lib.mkOverride 0 50;
    # Strict overcommit — LLVM codegen loves to mmap huge regions then
    # touch them lazily. With heuristic overcommit (0), the kernel doesn't
    # reserve swap for these promises, and by the time rustc tries to use
    # all of them, ARC eviction + LUKS write amplification have already
    # locked up the I/O path. Strict overcommit forces allocation to fail
    # early instead of letting the system freeze.
    "vm.overcommit_memory" = 2;
    "vm.overcommit_ratio" = 50;
  };

  # bluetooth
  hardware.bluetooth.enable = true;
  # seatd for session management (required for niri)
  services.seatd.enable = true;
  services.seatd.logLevel = "info";
  # The generated notify wrapper is not completing readiness notification on
  # this system, so systemd kills seatd after 90s and takes Niri with it.
  systemd.services.seatd.serviceConfig = {
    Type = lib.mkForce "simple";
    ExecStart = lib.mkForce "${pkgs.seatd}/bin/seatd -n 1 -u root -g seat -l info";
    NotifyAccess = lib.mkForce "none";
    TimeoutStartSec = "0";
  };
  systemd.services.seatd.restartIfChanged = lib.mkForce true;
  # polkit for authentication
  security.polkit.enable = true;
  # RTKit for PipeWire real-time scheduling (critical for pro audio)
  security.rtkit.enable = true;

  # Use latest kernel.
  boot.kernelPackages = pkgs.linuxPackages;

  # Early OOM — kill the worst memory offender (typically rustc/cargo)
  # BEFORE the system enters the ZFS eviction → I/O queue saturation →
  # screen freeze death spiral. systemd-oomd only acts on cgroup-level
  # pressure and doesn't prevent system-wide I/O lockup.
  services.earlyoom = {
    enable = true;
    extraArgs = [
      "--prefer"
      "(.*cargo.*)|(.*rustc.*)"
      "--avoid"
      "^(niri|Xwayland|systemd|kitty|waybar)$"
    ];
  };

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
            pkgs.libxcursor
            pkgs.libx11
            pkgs.libxrender
            pkgs.libxi
            pkgs.libxfixes
            pkgs.libxext
          ];
        }
        ''
          mkdir -p $out/bin
          makeWrapper ${pkgs.niri}/bin/niri $out/bin/niri \
            --set LD_LIBRARY_PATH "${pkgs.libxcursor}/lib:${pkgs.libx11}/lib:${pkgs.libxrender}/lib:${pkgs.libxi}/lib:${pkgs.libxfixes}/lib:${pkgs.libxext}/lib" \
            --set WINIT_UNIX_BACKEND wayland \
            --set WINIT_BACKEND wayland \
            --set WINIT_PLATFORM wayland \
            --unset DISPLAY \
            --unset XAUTHORITY \
            --prefix PATH : ${pkgs.libxcursor}/bin
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
  # nixpkgs.overlays = [
  #   # NoMachine disabled automated downloads for 9.4.14.
  #   # Re-enable if/when nixpkgs fixes the upstream URL or you manually
  #   # obtain the tarball and use requireFile.
  #   (final: prev: { })
  # ];

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
    xclip
    posting
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

    # Development tools
    nodejs_22
    uv
    pandoc

    # Default applications
    mpv
    kdePackages.gwenview
    libreoffice
    tauon
    jellyfin-media-player
    kdePackages.kdenlive

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
    kimi-code
    # nomachine-client  # disabled: upstream download URL broken (returns HTML)
    kdePackages.fcitx5-configtool

    # Graphics/OpenGL

    mesa
    libxcursor
    libx11
    libxrandr
    libxrender
    libxi
    libxfixes
    libxext
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
    bindsTo = [
      "pipewire.service"
      "wireplumber.service"
    ];
    after = [
      "pipewire.service"
      "wireplumber.service"
      "pipewire-pulse.service"
    ];
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
