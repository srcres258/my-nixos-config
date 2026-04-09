{ pkgs, ... }: {
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
  ];

  programs.mpvpaper = {
    enable = true;
  };
}
