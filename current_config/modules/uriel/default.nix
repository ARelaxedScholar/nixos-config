{
  config,
  lib,
  inputs,
  ...
}:

with lib;

let
  cfg = config.services.uriel;
in
{
  # Each Uriel submodule lives in its own file and is imported here.
  imports = [
    ./clause.nix
  ];

  options.services.uriel = {
    enable = mkEnableOption "Uriel — personal life-OS umbrella. Submodules (clause, …) attach to it.";

    user = mkOption {
      type = types.str;
      default = "user";
      description = "User that Uriel submodule services run as.";
    };

    group = mkOption {
      type = types.str;
      default = "users";
      description = "Group that Uriel submodule services run as.";
    };

    src = mkOption {
      type = types.path;
      default = inputs.uriel;
      defaultText = literalExpression "inputs.uriel";
      description = ''
        The Uriel source tree, supplied as a `git+file` flake input so that ONLY
        git-tracked files enter the Nix store. Personal data (organized/, *.pkl,
        *.zip) and the SwagWatch contracts are gitignored and never copied.
        Submodules build their crate from this workspace.
      '';
    };

    dataDir = mkOption {
      type = types.str;
      default = "/home/user/Documents/Uriel/organized";
      description = "Read-only corpus root (X archive + Claude/Gemini exports) for submodules that need it.";
    };

    stateDir = mkOption {
      type = types.str;
      default = "/var/lib/uriel";
      description = "Writable state base; each submodule gets its own subdirectory.";
    };
  };

  # The umbrella adds nothing on its own. Each submodule gates its config on
  # `services.uriel.enable && services.uriel.<name>.enable`, so enabling Uriel
  # without a submodule is a no-op, and submodules compose cleanly.
}
