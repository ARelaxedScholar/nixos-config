{
  config,
  lib,
  pkgs,
  ...
}:

with lib;

let
  cfg = config.services.kokoro-fastapi;
in
{
  options.services.kokoro-fastapi = {
    enable = mkEnableOption "Kokoro-FastAPI TTS service (Podman/OCI)";

    port = mkOption {
      type = types.port;
      default = 8880;
      description = "Port on which Kokoro-FastAPI will listen.";
    };

    openFirewall = mkOption {
      type = types.bool;
      default = false;
      description = "Open the firewall port for local network access.";
    };
  };

  config = mkIf cfg.enable {
    # Use Podman as the backend for secure, rootless containers
    virtualisation.podman.enable = true;
    virtualisation.oci-containers.backend = "podman";

    virtualisation.oci-containers.containers.kokoro-fastapi = {
      image = "ghcr.io/remsky/kokoro-fastapi-cpu:latest";
      ports = [ "${toString cfg.port}:8880" ];
      environment = {
        # Recommended ONNX thread optimizations for CPU inference
        ONNX_NUM_THREADS = "8";
        ONNX_INTER_OP_THREADS = "4";
        ONNX_EXECUTION_MODE = "parallel";
      };
      extraOptions = [
        # Prevents the container from gaining additional privileges
        "--security-opt=no-new-privileges=true"
      ];
    };

    networking.firewall.allowedTCPPorts = mkIf cfg.openFirewall [ cfg.port ];
  };
}
