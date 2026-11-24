{
  description = "A simple NixOS flake";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-26.05";
    nixpkgs-unstable.url = "github:NixOS/nixpkgs/nixos-unstable";

    mill-legacy-nixpkgs.url = "github:NixOS/nixpkgs/de1864217bfa9b5845f465e771e0ecb48b30e02d";
    vscode-legacy-nixpkgs.url = "github:NixOS/nixpkgs/ae67888ff7ef9dff69b3cf0cc0fbfbcd3a722abe";

    nur = {
      url = "github:nix-community/NUR";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    home-manager = {
      url = "github:nix-community/home-manager/release-26.05";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    nixos-wsl = {
      url = "github:nix-community/NixOS-WSL";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    nixos-hardware = {
      url = "github:nixos/nixos-hardware";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    # Live audio relay used by devices/srcres-rpi. Its module builds the Go
    # package with the host nixpkgs, so following "nixpkgs" avoids a second
    # nixpkgs in the lock file.
    audiorelay = {
      url = "github:srcres258/audiorelay";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    vscode-extensions = {
      url = "github:nix-community/nix-vscode-extensions";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    yazi.url = "github:sxyazi/yazi";

    zpaper.url = "git+https://codeberg.org/srcres258/zpaper.git?ref=refs/tags/v0.1.4";

    pi.url = "github:earendil-works/pi";

    pi-gpt-conv-decode = {
      url = "github:srcres258/pi-gpt-conv-decode";
      inputs.nixpkgs.follows = "nixpkgs";
      inputs.pi.follows = "pi";
    };

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
    , vscode-legacy-nixpkgs
    , nur
    , home-manager
    , nixos-wsl
    , nixos-hardware
    , audiorelay
    , vscode-extensions
    , yazi
    , zpaper
    , pi
    , # my-nur,
      ...
    }@inputs:
    let
      system = "x86_64-linux";
      username = "srcres";

      mkPkgsUnstable = system: import nixpkgs-unstable {
        inherit system;
        config = {
          allowUnfree = true;
        };
      };

      mkPkgs = system:
        let
          unstable = mkPkgsUnstable system;
        in
        import nixpkgs {
          inherit system;
          config = {
            allowUnfree = true;
          };
          overlays = [
            # kwm needs Zig 0.17, which is not available in nixos-26.05 yet.
            (_: _: {
              zig_0_17 = unstable.zig_0_17;
            })

            nur.overlays.default
          ];
        };

      pkgs = mkPkgs system;
    in
    {
      nixosConfigurations =
        let
          # `withBase = false` keeps a host off the shared desktop base
          # (./configuration.nix), for boards that define a minimal system
          # themselves.
          mkNixOSConfig =
            { system
            , extraModules
            , withBase ? true
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
              };
              modules = nixpkgs.lib.optionals withBase [ ./configuration.nix ] ++ extraModules;
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
          srcres-rpi = mkNixOSConfig {
            system = "aarch64-linux";
            withBase = false;
            extraModules = [
              nixos-hardware.nixosModules.raspberry-pi-4
              ./devices/srcres-rpi/configuration.nix
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
          "${username}@srcres-rpi" = mkPureHomeConfig {
            system = "aarch64-linux";
            extraModules = [
              # A trimmed profile, not ./home/pure: the full set is ~27 GiB.
              ./home/pure/minimal.nix
              ./devices/srcres-rpi/home
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
