{ pkgs, ... }: {
  home.packages = with pkgs; [
    wl-kbptr
  ];

  xdg.configFile."wl-kbptr/config.toml".source = ./config.toml;
}

