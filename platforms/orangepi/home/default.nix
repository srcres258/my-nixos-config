{ config
, pkgs
, lib
, inputs
, ...
}: {
  imports = [
    ./vscode.nix
  ];

  home.packages = with pkgs; [
    # Screenshot tools
    grim
    slurp
    satty
  ];

  xdg.configFile."niri/config.kdl".source = ./config.kdl;
}
