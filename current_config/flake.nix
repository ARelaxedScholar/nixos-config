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
    elephant.url = "github:abenz1267/elephant";
    walker = {
      url = "github:abenz1267/walker";
      inputs.elephant.follows = "elephant";
    };
  };

  outputs =
    {
      self,
      disko,
      hyprland,
      nixpkgs,
      home-manager,
      walker,
      ...
    }@inputs:
    {
      nixosConfigurations.iphone6s = nixpkgs.lib.nixosSystem {
        specialArgs = { inherit inputs; };

        modules = [
          # My main (and for the time being only configs)
          ./hosts/iphone6s/configuration.nix
          disko.nixosModules.disko
          ./hosts/iphone6s/disko-configuration.nix
          home-manager.nixosModules.home-manager
          {
            home-manager.useGlobalPkgs = true;
            home-manager.useUserPackages = true;
            home-manager.extraSpecialArgs = { inherit inputs; };

            home-manager.users.user = {
              imports = [
                walker.homeManagerModules.default
                ./hosts/iphone6s/home.nix
              ];
            };
          }
        ];
      };
    };
}
