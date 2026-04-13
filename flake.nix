{
  description = "A simple NixOS flake";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-25.11";
    nixpkgs-unstable.url = "github:NixOS/nixpkgs/nixos-unstable";

    mill-legacy-nixpkgs.url = "github:NixOS/nixpkgs/de1864217bfa9b5845f465e771e0ecb48b30e02d";
    go-ethereum-legacy-nixpkgs.url = "github:NixOS/nixpkgs/0ffaecb6f04404db2c739beb167a5942993cfd87";
    vscode-legacy-nixpkgs.url = "github:NixOS/nixpkgs/ae67888ff7ef9dff69b3cf0cc0fbfbcd3a722abe";

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

  outputs =
    { self
    , nixpkgs
    , nixpkgs-unstable
    , mill-legacy-nixpkgs
    , go-ethereum-legacy-nixpkgs
    , vscode-legacy-nixpkgs
    , nur
    , home-manager
    , nixos-wsl
    , minegrub-theme
    , vscode-extensions
    , foundry
    , # my-nur,
      ...
    }@inputs:
    let
      system = "x86_64-linux";
      username = "srcres";

      mkPkgs = system: import nixpkgs {
        inherit system;
        config = {
          allowUnfree = true;
        };
        overlays = [
          nur.overlays.default
          foundry.overlay
        ];
      };

      mkPkgsUnstable = system: import nixpkgs-unstable {
        inherit system;
        config = {
          allowUnfree = true;
        };
      };

      pkgs = mkPkgs system;
    in
    {
      nixosConfigurations =
        let
          mkNixOSConfig =
            { system
            , extraModules
            ,
            }:
            let
              pkgs = mkPkgs system;
              pkgs-unstable = mkPkgsUnstable system;
            in
            nixpkgs.lib.nixosSystem {
              inherit system pkgs;
              specialArgs = {
                inherit inputs system;
                inherit pkgs-unstable;
                srcres-password = builtins.getEnv "SRCRES_PASSWORD";
              };
              modules = [
                ./configuration.nix
              ] ++ extraModules;
            };
        in
        {
          srcres-desktop = mkNixOSConfig {
            inherit system;
            extraModules = [
              ./platforms/native/configuration.nix
              ./devices/srcres-desktop/configuration.nix
            ];
          };
          srcres-laptop = mkNixOSConfig {
            inherit system;
            extraModules = [
              ./platforms/native/configuration.nix
              ./devices/srcres-laptop/configuration.nix
            ];
          };
          srcres-wsl = mkNixOSConfig {
            inherit system;
            extraModules = [
              nixos-wsl.nixosModules.default

              ./devices/srcres-wsl/configuration.nix
            ];
          };
          srcres-desktop-x99 = mkNixOSConfig {
            inherit system;
            extraModules = [
              ./platforms/native/configuration.nix
              ./devices/srcres-desktop-x99/configuration.nix
            ];
          };
          srcres-orange-pi = mkNixOSConfig {
            system = "aarch64-linux";
            extraModules = [
              ./platforms/orangepi/configuration.nix
              ./devices/srcres-orange-pi/configuration.nix
            ];
          };
        };

      homeConfigurations =
        let
          mkHomeConfig =
            { system
            , extraModules
            ,
            }:
            let
              pkgs = mkPkgs system;
              pkgs-unstable = mkPkgsUnstable system;
            in
            home-manager.lib.homeManagerConfiguration {
              inherit pkgs;
              extraSpecialArgs = {
                inherit inputs system;
                inherit pkgs-unstable;
              };
              modules = [
                ./home
              ] ++ extraModules;
            };
          mkPureHomeConfig =
            { system
            , extraModules
            ,
            }:
            let
              pkgs = mkPkgs system;
              pkgs-unstable = mkPkgsUnstable system;
            in
            home-manager.lib.homeManagerConfiguration {
              inherit pkgs;
              extraSpecialArgs = {
                inherit inputs system;
                inherit pkgs-unstable;
              };
              modules = extraModules;
            };
        in
        {
          "${username}@srcres-desktop" = mkHomeConfig {
            inherit system;
            extraModules = [
              ./platforms/native/home
              ./devices/srcres-desktop/home
            ];
          };
          "${username}@srcres-laptop" = mkHomeConfig {
            inherit system;
            extraModules = [
              ./platforms/native/home
              ./devices/srcres-laptop/home
            ];
          };
          "${username}@srcres-wsl" = mkPureHomeConfig {
            inherit system;
            extraModules = [
              ./home/pure
              ./devices/srcres-wsl/home
            ];
          };
          "${username}@srcres-desktop-x99" = mkHomeConfig {
            inherit system;
            extraModules = [
              ./platforms/native/home
              ./devices/srcres-desktop-x99/home
            ];
          };
          "${username}@srcres-orange-pi" = mkHomeConfig {
            system = "aarch64-linux";
            extraModules = [
              ./platforms/orangepi/home
              ./devices/srcres-orange-pi/home
            ];
          };
        };

      packages.${system} = {
        ${username} = pkgs.buildEnv {
          name = "${username}-env";
          paths = [
            (home-manager.lib.homeManagerConfiguration {
              inherit pkgs;
              extraSpecialArgs = {
                inherit inputs system;
                pkgs-unstable = mkPkgsUnstable system;
              };
              modules = [
                ./home/develop.nix

                ({
                  home.stateVersion = "25.11";
                })
              ];
            }).activationPackage
          ];
        };
      };
    };
}

