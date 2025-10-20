{
  description = "ARelaxedScholar's NixOS System Flake";
  
   inputs = {
    # The main package set and NixOS modules. We use unstable for newer packages.
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
        # The Disko module itself, which knows how to read disko configs.
        disko.nixosModules.disko
        # Your custom disk layout.
        ./disko/disko-config.nix

        # The Impermanence module itself.
        impermanence.nixosModules.impermanence

        # Main system configuration blueprint.
        ./configuration.nix

        # The Home Manager module itself.
        home-manager.nixosModules.home-manager
        {
          # This section configures Home Manager for our user
          home-manager.useGlobalPkgs = true;
          home-manager.useUserPackages = true;
          home-manager.users.user = import ./home.nix;
        }
      ];
    };
  };
}
