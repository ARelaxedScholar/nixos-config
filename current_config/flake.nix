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
    
    # Official Zed Industries flake
    zed-industries.url = "github:zed-industries/zed";
    # Keep the binary flake as well if you want a fallback, 
    # but zed-industries is what your modules/zed.nix is now using
    zed-editor-flake.url = "github:HPsaucii/zed-editor-flake";
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
#      zed-industries,
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
            home-manager.useUserPackages = true;
            home-manager.extraSpecialArgs = { inherit inputs; };

            home-manager.users.user = {
              imports = [
                ./hosts/iphone6s/home.nix
              ];
              nixpkgs.config.allowUnfree = true;

              # Tell Stylix to NOT manage Zed's theme, allowing your Dracula setting to work without conflict
              stylix.targets.zed.enable = false;
            };
          }
        ];
      };
    };
}
