{ config
, pkgs
, lib
, inputs
, ...
}: {
  imports = [ ./pure ./system ];

  nixpkgs.overlays = [
    (final: prev: {
      nur = import inputs.nur {
        pkgs = prev;
        repoOverrides = let
          username = "srcres258";
          remoteUrl = "https://github.com/${username}/nur-packages/archive/main.tar.gz";
        in {
          srcres258 = import (builtins.fetchTarball remoteUrl) {
            pkgs = prev;
          };
        };
      };
    })
  ];
}

