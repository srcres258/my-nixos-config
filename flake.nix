{
    description = "A simple NixOS flake";

    inputs = {
        nixpkgs.url = "github:NixOS/nixpkgs/nixos-25.11";
        nixpkgs-unstable.url = "github:NixOS/nixpkgs/nixos-unstable";

        mill-legacy-nixpkgs.url = "github:NixOS/nixpkgs/de1864217bfa9b5845f465e771e0ecb48b30e02d";
        go-ethereum-legacy-nixpkgs.url = "github:NixOS/nixpkgs/0ffaecb6f04404db2c739beb167a5942993cfd87";

        nur = {
            url = "github:nix-community/NUR";
            inputs.nixpkgs.follows = "nixpkgs";
        };

        home-manager = {
            url = "github:nix-community/home-manager/release-25.11";
            inputs.nixpkgs.follows = "nixpkgs";
        };

        nixos-wsl = {
            url = "github:nix-community/NixOS-WSL";
            inputs.nixpkgs.follows = "nixpkgs";
        };

        minegrub-theme.url = "github:Lxtharia/minegrub-theme";

        vscode-extensions = {
            url = "github:nix-community/nix-vscode-extensions";
            inputs.nixpkgs.follows = "nixpkgs";
        };

        foundry.url = "github:shazow/foundry.nix/stable";

        # my-nur = {
        #     url = "github:srcres258/nur-packages";
        #     inputs.nixpkgs.follows = "nixpkgs";
        # };
    };

    outputs = {
        self,
        nixpkgs,
        nixpkgs-unstable,
        mill-legacy-nixpkgs,
        go-ethereum-legacy-nixpkgs,
        nur,
        home-manager,
        nixos-wsl,
        minegrub-theme,
        vscode-extensions,
        foundry,
        # my-nur,
        ...
    }@inputs: let
        system = "x86_64-linux";
        username = "srcres";

        pkgs = import nixpkgs {
            inherit system;
            config = {
                allowUnfree = true;
            };
            overlays = [
                nur.overlays.default
                foundry.overlay
            ];
        };
    in {
        nixosConfigurations = let
            mkNixOSConfig = extraModules: nixpkgs.lib.nixosSystem {
                inherit system pkgs;
                specialArgs = {
                    inherit inputs system;
                    srcres-password = builtins.getEnv "SRCRES_PASSWORD";
                };
                modules = [
                    ./configuration.nix
                ] ++ extraModules;
            };
        in {
            srcres-desktop = mkNixOSConfig [
                ./platforms/native/configuration.nix
                ./devices/srcres-desktop/configuration.nix
            ];
            srcres-laptop = mkNixOSConfig [
                ./platforms/native/configuration.nix
                ./devices/srcres-laptop/configuration.nix
            ];
            srcres-wsl = mkNixOSConfig [
                nixos-wsl.nixosModules.default

                ./devices/srcres-wsl/configuration.nix
            ];
            srcres-desktop-x99 = mkNixOSConfig [
                ./platforms/native/configuration.nix
                ./devices/srcres-desktop-x99/configuration.nix
            ];
        };

        homeConfigurations = let
            mkHomeConfig = extraModules: home-manager.lib.homeManagerConfiguration {
                inherit pkgs;
                extraSpecialArgs = { inherit inputs system; };
                modules = [
                    ./home
                ] ++ extraModules;
            };
            defaultHomeConfig = mkHomeConfig [];

            mkPureHomeConfig = extraModules: home-manager.lib.homeManagerConfiguration {
                inherit pkgs;
                extraSpecialArgs = { inherit inputs system; };
                modules = extraModules;
            };
        in {
            "${username}@srcres-desktop" = mkHomeConfig [
                ./devices/srcres-desktop/home
            ];
            "${username}@srcres-laptop" = mkHomeConfig [
                ./devices/srcres-laptop/home
            ];
            "${username}@srcres-wsl" = mkPureHomeConfig [
                ./home/pure.nix
            ];
            "${username}@srcres-desktop-x99" = mkHomeConfig [
                ./devices/srcres-desktop-x99/home
            ];
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

