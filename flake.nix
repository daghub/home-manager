{
  description = "Dag's Home Manager configuration";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";

    home-manager = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    # Doom remains a writable checkout, but this input selects its exact core
    # revision.  `doom-core-sync` checks the checkout out at this lockfile pin.
    doom-core = {
      url = "github:doomemacs/core";
      flake = false;
    };
  };

  outputs = inputs@{ nixpkgs, home-manager, ... }:
    {
      homeConfigurations.dekengren =
        home-manager.lib.homeManagerConfiguration {
          pkgs = nixpkgs.legacyPackages.x86_64-linux;
          extraSpecialArgs = { inherit inputs; };
          modules = [ ./home.nix ];
        };
    };
}
