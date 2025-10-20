#/root/nixos-config/flake.nix

{
	description="My NixOS System Flake (cuz I'm a baller)"
}

inputs = {
	nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";
	disko.url = "github:nix-community/disko";
};
