{ config
, pkgs
, lib
, inputs
, ...
}: {
  imports = [
    ./vscode.nix
  ];

  xdg.configFile."niri/config.kdl".source = ./config.kdl;
}
