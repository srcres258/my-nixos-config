{ pkgs
, lib
, config
, ...
}: let
  javaPkg = pkgs.javaPackages.compiler.temurin-bin.jdk-21;
in {
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
  
  home.sessionVariables = {
    JAVA_HOME = "${javaPkg}";
    COURSIER_CACHE = "${config.xdg.cacheHome}/coursier";
    SBT_OPTS = "-Dsbt.ivy.home=${config.xdg.cacheHome}/ivy2 -Dsbt.global.base=${config.xdg.configHome}/sbt -Dsbt.coursier.home=${config.xdg.cacheHome}/coursier";
  };
}
