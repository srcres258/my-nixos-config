{
  description = "A simple NixOS flake";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-25.11";
    nixpkgs-unstable.url = "github:NixOS/nixpkgs/nixos-unstable";

    home-manager = {
      url = "github:nix-community/home-manager/release-25.11";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    minegrub-theme.url = "github:Lxtharia/minegrub-theme";
  };

  outputs = {
    self,
    nixpkgs,
    nixpkgs-unstable,
    home-manager,
    minegrub-theme,
    ...
  }@inputs: let
    system = "x86_64-linux";
    username = "srcres";
    hostname = "srcres-computer";

    pkgs = nixpkgs.legacyPackages.${system};
  in {
    nixosConfigurations = {
      srcres-computer = nixpkgs.lib.nixosSystem {
        inherit system;
        specialArgs = {
          inherit inputs;
          srcres-password = builtins.getEnv "SRCRES_PASSWORD";
        };
        modules = [
          ./configuration.nix
          inputs.minegrub-theme.nixosModules.default
        ];
      };
    };

    homeConfigurations = {
      "${username}@${hostname}" = home-manager.lib.homeManagerConfiguration {
        inherit pkgs;
        extraSpecialArgs = { inherit inputs; };
        modules = [
          ./home
        ];
      };
    };

    packages.${system} = {
      ${username} = pkgs.buildEnv {
        name = "${username}-env";
        paths = [
          (home-manager.lib.homeManagerConfiguration {
            inherit pkgs;
            extraSpecialArgs = { inherit inputs; };
            modules = [
              ./home/develop.nix
            ];
          }).activationPackage
        ];
      };
    };

    devShells.${system} = let
      baseDevShell = pkgs.mkShell {
        buildInputs = [ self.packages.${system}.${username} ];
      };
    in {
      "${username}-full" = baseDevShell;
      default = baseDevShell;
    };
  };
}

