{
  description = "ARelaxedScholar's NixOS System Flake";
  
   inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";

    # The Disko module for declarative disk partitioning.
    disko.url = "github:nix-community/disko";

    # The Home Manager module for declarative user environments.
    home-manager = {
      url = "github:nix-community/home-manager";
      # Make sure home-manager uses the same package set as our system.
      inputs.nixpkgs.follows = "nixpkgs";
    };

    # The Impermanence module for boot-time rollbacks and persistence.
    impermanence.url = "github:nix-community/impermanence";
  };

  outputs = { self, nixpkgs, disko, home-manager, impermanence, ... }@inputs: {
    # This defines a single NixOS system configuration.
    nixosConfigurations.iphone6s = nixpkgs.lib.nixosSystem {
      system = "x86_64-linux";

      # specialArgs allows us to pass our inputs to our other config files.
      specialArgs = { inherit inputs; };

      # This is the list of blueprints that will be assembled into the final system.
      modules = [
        disko.nixosModules.disko
        ./disko/disko-config.nix
        impermanence.nixosModules.impermanence
        ./configuration.nix
        home-manager.nixosModules.home-manager
        {
          home-manager.useGlobalPkgs = true;
          home-manager.useUserPackages = true;
          home-manager.users.user = import ./home.nix;
        }
      ];
    };
  };
}
