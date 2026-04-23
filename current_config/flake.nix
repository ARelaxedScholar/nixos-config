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
    niri.url = "github:sodiboo/niri-flake";
    stylix.url = "github:danth/stylix";
    zed-editor-flake.url = "github:HPsaucii/zed-editor-flake";
    llm-agents.url = "github:numtide/llm-agents.nix";
  };

  outputs = { self, disko, hyprland, nixpkgs, home-manager, evil-helix, antigravity-nix
          , stylix, niri, llm-agents, ... }@inputs: {
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
                rstudio = prev.rstudio.overrideAttrs (oldAttrs: {
                  # Ensure npm is available during npmConfigHook (postPatch phase)
                  nativeBuildInputs = oldAttrs.nativeBuildInputs ++ [ prev.nodejs ];
                  
                  # Fix CMake to find npm
                  postPatch = (oldAttrs.postPatch or "") + ''
                    export PATH="${prev.nodejs}/bin:$PATH"
                    substituteInPlace src/node/CMakeNodeTools.txt --replace-fail "NO_DEFAULT_PATH" ""
                  '';
                  
                  # Fix electron-forge substitution to be conditional
                  preConfigure = builtins.replaceStrings [
                    "substituteInPlace node_modules/@electron-forge/core-utils/dist/electron-version.js"
                    "substituteInPlace node_modules/@electron/packager/dist/packager.js"
                  ] [
                    "[ -f node_modules/@electron-forge/core-utils/dist/electron-version.js ] && substituteInPlace node_modules/@electron-forge/core-utils/dist/electron-version.js"
                    "[ -f node_modules/@electron/packager/dist/packager.js ] && substituteInPlace node_modules/@electron/packager/dist/packager.js"
                  ] oldAttrs.preConfigure;
                  
                  env = (oldAttrs.env or {}) // {
                    PATH = "${prev.nodejs}/bin:" + (oldAttrs.env.PATH or "");
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
