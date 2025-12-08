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
      ...
    }@inputs:
    {
      nixosConfigurations.iphone6s = nixpkgs.lib.nixosSystem {
        specialArgs = { inherit inputs; currentTime = builtins.currentTime; };

        modules = [
          # My main (and for the time being only configs)
          ./hosts/iphone6s/configuration.nix
          disko.nixosModules.disko
          ./hosts/iphone6s/disko-configuration.nix
          inputs.stylix.nixosModules.stylix
          home-manager.nixosModules.home-manager
          {
            home-manager.useGlobalPkgs = true;
            home-manager.useUserPackages = true;
            home-manager.extraSpecialArgs = { inherit inputs; };

            home-manager.users.user = {
              imports = [
                ./hosts/iphone6s/home.nix
                inputs.stylix.homeModules.stylix
              ];
            };
          }
        ];
      };
    };
}
