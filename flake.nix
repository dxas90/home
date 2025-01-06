{
  description = "My Nix flake configurations for NixOS and Home Manager";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-24.11";
    nixpkgs-unstable.url = "github:nixos/nixpkgs/nixos-unstable";

    home-manager = {
      url = "github:nix-community/home-manager/release-24.11";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    
    catppuccin = {
      url = "github:catppuccin/nix";
    };

    # sops-nix - secrets with mozilla sops
    # https://github.com/Mic92/sops-nix
    sops-nix = {
      url = "github:Mic92/sops-nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    hardware.url = "github:nixos/nixos-hardware";
  };

  outputs = { self, nixpkgs, catppuccin, home-manager, sops-nix, ... }@inputs:
  let
    inherit (self) outputs;

    systems = [
      # Linux
      "i686-linux"
      "x86_64-linux"
      "aarch64-linux"
      # Darwin
      "x86_64-darwin"
      "aarch64-darwin"
    ];

    pkgsFor = nixpkgs.legacyPackages;
    forAllSystems = nixpkgs.lib.genAttrs systems;
  in
  {
    packages = forAllSystems (system: import ./pkgs.nix pkgsFor.${system});
    devShells = forAllSystems (system: import ./shell.nix pkgsFor.${system});

    overlays = import ./overlays.nix { inherit inputs; };

    nixosConfigurations = {
      ullr = nixpkgs.lib.nixosSystem {
        specialArgs = { inherit inputs outputs; };
        modules = [
          ./nixos/ullr
        ];
      };
      generic = nixpkgs.lib.nixosSystem {
        specialArgs = { inherit inputs outputs; };
        modules = [
          ./nixos/generic-vm
        ];
      };
    };

    homeConfigurations = {
      daniel = home-manager.lib.homeManagerConfiguration {
        extraSpecialArgs = { inherit inputs outputs; };
        modules = [
          catppuccin.homeManagerModules.catppuccin
          ./home-manager/daniel
        ];
        pkgs = pkgsFor.x86_64-linux;
      };
    };
  };
}
