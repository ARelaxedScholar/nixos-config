{
  config,
  lib,
  pkgs,
  ...
}:

with lib;

let
  uriel = config.services.uriel;
  cfg = uriel.clause;

  clausePackage = pkgs.rustPlatform.buildRustPackage {
    pname = "clause";
    version = "0.1.0";
    src = uriel.src;
    cargoLock.lockFile = uriel.src + "/Cargo.lock";
    cargoBuildFlags = [
      "-p"
      "clause"
    ];
    nativeBuildInputs = [ pkgs.pkg-config ];
    buildInputs = [ pkgs.openssl ];
    # policy/ingest unit tests are pure (no network); keep them as a build gate.
    doCheck = true;
    meta = {
      description = "Signal-driven X/social posting submodule of Uriel";
      mainProgram = "clause";
    };
  };

  baseEnv = {
    ENGINE_URL = cfg.engineUrl;
    # CA bundle so HTTPS to the engine works under ProtectSystem=strict.
    SSL_CERT_FILE = "${pkgs.cacert}/etc/ssl/certs/ca-bundle.crt";
    CLAUSE_PORT = toString cfg.port;
    CLAUSE_DATA_DIR = uriel.dataDir;
    CLAUSE_CACHE_DIR = "${uriel.stateDir}/clause";
    X_DRY_RUN = if cfg.dryRun then "true" else "false";
  };

  # Shared systemd hardening. ProtectHome is read-only (not true) because the
  # corpus to read lives under /home; all writes go to the StateDirectory.
  hardening = {
    NoNewPrivileges = true;
    ProtectSystem = "strict";
    ProtectHome = "read-only";
    PrivateTmp = true;
    StateDirectory = "uriel/clause";
  };
in
{
  options.services.uriel.clause = {
    enable = mkEnableOption "Clause — turn SwagWatch signals into X posts (local review board)";

    package = mkOption {
      type = types.package;
      default = clausePackage;
      defaultText = literalExpression "pkgs.rustPlatform.buildRustPackage { … } (from services.uriel.src)";
      description = "The clause binary, built from the Uriel workspace.";
    };

    port = mkOption {
      type = types.port;
      default = 8787;
      description = "Port for the local review board (bound to 127.0.0.1).";
    };

    engineUrl = mkOption {
      type = types.str;
      default = "http://localhost:3001";
      description = "SwagWatch engine base URL for the intelligence feed.";
    };

    dryRun = mkOption {
      type = types.bool;
      default = true;
      description = ''
        Sets X_DRY_RUN. When true (the default) Approve validates and logs the
        post but NEVER publishes to X. Set false only after smoke-testing the
        engine feed and the X OAuth path against a throwaway account.
      '';
    };

    environmentFile = mkOption {
      type = types.nullOr types.path;
      default = null;
      example = "/etc/uriel/clause.env";
      description = ''
        File with secrets, kept OUT of the Nix store: ENGINE_API_KEY,
        DEEPSEEK_API_KEY, and (only when going live) X_API_KEY / X_API_SECRET /
        X_ACCESS_TOKEN / X_ACCESS_SECRET. Without it the board still serves, but
        the engine feed and posting are inert.
      '';
    };

    refreshInterval = mkOption {
      type = types.nullOr types.str;
      default = null;
      example = "daily";
      description = ''
        systemd OnCalendar for a periodic `clause refresh` (enqueues drafts only,
        never posts). null disables the timer.
      '';
    };

    openFirewall = mkOption {
      type = types.bool;
      default = false;
      description = "Open the board port to the network. Off by default; the board is local-only.";
    };
  };

  config = mkIf (uriel.enable && cfg.enable) {
    systemd.services.uriel-clause = {
      description = "Clause review board (Uriel submodule)";
      wantedBy = [ "multi-user.target" ];
      after = [ "network.target" ];
      environment = baseEnv;
      serviceConfig = {
        ExecStart = "${getExe cfg.package} serve";
        User = uriel.user;
        Group = uriel.group;
        EnvironmentFile = optional (cfg.environmentFile != null) cfg.environmentFile;
        Restart = "on-failure";
        RestartSec = 5;
      }
      // hardening;
    };

    systemd.timers.uriel-clause-refresh = mkIf (cfg.refreshInterval != null) {
      description = "Periodic Clause draft refresh";
      wantedBy = [ "timers.target" ];
      timerConfig = {
        OnCalendar = cfg.refreshInterval;
        Persistent = true;
      };
    };

    systemd.services.uriel-clause-refresh = mkIf (cfg.refreshInterval != null) {
      description = "Clause: pull SwagWatch signals and enqueue drafts";
      after = [ "network.target" ];
      environment = baseEnv;
      serviceConfig = {
        Type = "oneshot";
        ExecStart = "${getExe cfg.package} refresh";
        User = uriel.user;
        Group = uriel.group;
        EnvironmentFile = optional (cfg.environmentFile != null) cfg.environmentFile;
      }
      // hardening;
    };

    networking.firewall.allowedTCPPorts = mkIf cfg.openFirewall [ cfg.port ];
  };
}
