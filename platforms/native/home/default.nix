{ pkgs
, lib
, ...
}: {
  imports = [
    ./vscode.nix
  ];

  home.packages = with pkgs; [
    wpsoffice-cn

    discord
    wechat

    drawio

    # JetBrains IDEs
    jetbrains.idea

    feishu

    tor-browser

    rkdeveloptool

    bloop
  ];

  xdg.configFile."niri/config.kdl".source = ./config.kdl;

  programs.mpvpaper = {
    enable = true;
  };
}
