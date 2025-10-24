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
  };

  outputs =
    {
      self,
      disko,
      hyprland,
      nixpkgs,
      home-manager,
      ...
    }@inputs:
    {
      nixosConfigurations.iphone6s = nixpkgs.lib.nixosSystem {
        specialArgs = { inherit inputs; };

        modules = [
          ./configuration.nix
          ./disko-configuration.nix
          ./home.nix
          home-manager.nixosMOdules.home-manager
          {
            home-manager.useUserGlobalPkgs = true;
            home-manager.useUserPackages = true;

            home-manager.users.user = {
              imports = [ ./home.nix ];
            };
          }
        ];
      };
    };
}
