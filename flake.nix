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

        my-nur = {
            url = "github:srcres258/nur-packages";
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
        my-nur,
        ...
    }@inputs: let
        system = "x86_64-linux";
        username = "srcres";

        pkgs = nixpkgs.legacyPackages.${system};
    in {
        nixosConfigurations = let
            mkNixOSConfig = extraModules: nixpkgs.lib.nixosSystem {
                inherit system;
                specialArgs = {
                    inherit inputs;
                    srcres-password = builtins.getEnv "SRCRES_PASSWORD";
                };
                modules = [
                    ./configuration.nix
                ] ++ extraModules;
            };
        in {
            srcres-desktop = mkNixOSConfig [
                ./devices/srcres-desktop/configuration.nix
            ];
            srcres-laptop = mkNixOSConfig [
                ./devices/srcres-laptop/configuration.nix
            ];
        };

        homeConfigurations = let
            mkHomeConfig = extraModules: home-manager.lib.homeManagerConfiguration {
                inherit pkgs;
                extraSpecialArgs = { inherit inputs; };
                modules = [
                    ./home
                ] ++ extraModules;
            };
            defaultHomeConfig = mkHomeConfig [];
        in {
            "${username}@srcres-desktop" = defaultHomeConfig;
            "${username}@srcres-laptop" = defaultHomeConfig;
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

