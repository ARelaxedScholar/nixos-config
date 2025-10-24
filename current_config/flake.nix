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
walker = {
url  = "github:abenz1267/walker";
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
walker,
      ...
    }@inputs:
    {
      nixosConfigurations.iphone6s = nixpkgs.lib.nixosSystem {
        specialArgs = { inherit inputs; };

        modules = [
          ./configuration.nix
          disko.nixosModules.disko
          ./disko-configuration.nix
          home-manager.nixosModules.home-manager
          {
            home-manager.useGlobalPkgs = true;
            home-manager.useUserPackages = true;

            home-manager.users.user = {
              imports = [ ./home.nix ];
            };
          }
        ];
      };
    };
}
