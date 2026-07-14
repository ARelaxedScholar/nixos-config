{
  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs?ref=nixos-unstable";
    disko.url = "github:nix-community/disko/latest";
    disko.inputs.nixpkgs.follows = "nixpkgs";
    hyprland.url = "github:hyprwm/Hyprland";
    home-manager = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    evil-helix.url = "github:usagi-flow/evil-helix";
    antigravity-nix = {
      url = "github:jacopone/antigravity-nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    hermes-agent = {
      url = "github:NousResearch/hermes-agent";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    niri.url = "github:sodiboo/niri-flake";
    stylix.url = "github:danth/stylix";
    zed-editor-flake.url = "github:HPsaucii/zed-editor-flake";
    llm-agents.url = "github:numtide/llm-agents.nix";
    # Uriel life-OS source (git+file → only git-tracked files enter the store,
    # so gitignored personal data and contracts are never copied).
    uriel = {
      url = "git+file:///home/user/Documents/Uriel";
      flake = false;
    };
  };

  outputs =
    {
      self,
      disko,
      hyprland,
      nixpkgs,
      home-manager,
      evil-helix,
      antigravity-nix,
      stylix,
      niri,
      llm-agents,
      hermes-agent,
      ...
    }@inputs:
    {
      nixosConfigurations.iphone6s = nixpkgs.lib.nixosSystem {
        specialArgs = { inherit inputs; };
        modules = [
          ./hosts/iphone6s/configuration.nix
          disko.nixosModules.disko
          ./hosts/iphone6s/disko-configuration.nix
          stylix.nixosModules.stylix
          home-manager.nixosModules.home-manager
          {
            home-manager.useGlobalPkgs = false;
            home-manager.extraSpecialArgs = { inherit inputs; };
            home-manager.users.user = {
              imports = [ ./hosts/iphone6s/home.nix ];
              nixpkgs.overlays = [
                (final: prev: {
                  hermes-agent-latest =
                    let
                      haPkgs = inputs.hermes-agent.packages.${prev.system} or { };
                      hermesBase = haPkgs.default or haPkgs.hermes-agent or haPkgs.hermes
                        or (throw "hermes-agent flake missing package for ${prev.system}");
                      overrideHermesNpm = workspace: drv: drv.overrideAttrs (old: {
                        NODE_OPTIONS = "--max-old-space-size=4096";
                        npmFlags = (old.npmFlags or [ ]) ++ [
                          "--legacy-peer-deps"
                          "--workspace"
                          workspace
                        ];
                      });
                      hermesTui = overrideHermesNpm "ui-tui" hermesBase.hermesTui;
                      hermesWeb = overrideHermesNpm "web" hermesBase.hermesWeb;
                      originalHermesNpmPaths = [
                        (builtins.unsafeDiscardStringContext "${hermesBase.hermesTui}")
                        (builtins.unsafeDiscardStringContext "${hermesBase.hermesWeb}")
                      ];
                      originalHermesNpmDrvPaths = [
                        (builtins.unsafeDiscardStringContext "${hermesBase.hermesTui.drvPath}")
                        (builtins.unsafeDiscardStringContext "${hermesBase.hermesWeb.drvPath}")
                      ];
                    in
                    hermesBase.overrideAttrs (old: {
                      installPhase =
                        let
                          replacedInstallPhase = builtins.replaceStrings
                            originalHermesNpmPaths
                            [
                              "${hermesTui}"
                              "${hermesWeb}"
                            ]
                            old.installPhase;
                        in
                        builtins.appendContext
                          (builtins.unsafeDiscardStringContext replacedInstallPhase)
                          (builtins.removeAttrs (builtins.getContext replacedInstallPhase) originalHermesNpmDrvPaths);
                      passthru = old.passthru // {
                        inherit hermesTui hermesWeb;
                      };
                    });
                })
              ];
              nixpkgs.config.allowUnfree = true;
              nixpkgs.config.permittedInsecurePackages = [ "electron-38.8.4" ];
              stylix.targets.zed.enable = false;
            };
          }
        ];
      };
    };
}
