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
  ];

  programs.mpvpaper = {
    enable = true;
  };
}
