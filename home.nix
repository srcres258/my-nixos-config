{
  config,
  pkgs,
  lib,
  inputs,
  ...
}: {
  home = rec {
    username = "srcres";
    homeDirectory = "/home/${username}";
  };

  home.packages = with pkgs; [
    btop
  ];

  home.stateVersion = "25.05";
}

