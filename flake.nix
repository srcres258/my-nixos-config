{
    description = "A simple NixOS flake";

    inputs = {
        nixpkgs.url = "github:NixOS/nixpkgs/nixos-25.11";
        nixpkgs-unstable.url = "github:NixOS/nixpkgs/nixos-unstable";
        nur = {
            url = "github:nix-community/NUR";
            inputs.nixpkgs.follows = "nixpkgs";
        };

        home-manager = {
            url = "github:nix-community/home-manager/release-25.11";
            inputs.nixpkgs.follows = "nixpkgs";
        };

        minegrub-theme.url = "github:Lxtharia/minegrub-theme";

        vscode-extensions = {
            url = "github:nix-community/nix-vscode-extensions";
            inputs.nixpkgs.follows = "nixpkgs";
        };
    };

    outputs = {
        self,
        nixpkgs,
        nixpkgs-unstable,
        nur,
        home-manager,
        minegrub-theme,
        vscode-extensions,
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

    # nixConfig = {
    #     extra-substituters = [
    #         "https://nix-community.cachix.org/"
    #         "https://cache.nixos.org/"
    #     ];
    #     extra-trusted-public-keys = [
    #         "nix-community.cachix.org-1:mB9FSh9qf2dCimDSUo8Zy7bkq5CX+/rkCWyvRCYg3Fs="
    #         "nur-pkgs.cachix.org-1:0R3PmV8TEQ7nA8wxo4LLs5rY5fI1vB4Y02i9YB8g8eA="
    #         "cache.garnix.io:CTFPyKSLcx5RMJKfLo5EEPUObbA78b0YQ2DTCJXqr9g="
    #     ];
    # };
}

