{ pkgs
, lib
, config
, inputs
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

    gtkwave
    circt
    verilator
    iverilog

    pkgsCross.riscv64.stdenv.cc # Linux GNU
    pkgsCross.riscv64-embedded.stdenv.cc # bare-metal ELF
    pkgsCross.riscv32-embedded.stdenv.cc

    qemu

    whisper-cpp
    spek
    fcrackzip

    # Ethereum
    inputs.go-ethereum-legacy-nixpkgs.legacyPackages.${system}.go-ethereum
    foundry-bin
    solc
    python312Packages.pyevmasm

    # Scala language
    scala-cli
    sbt
    inputs.mill-legacy-nixpkgs.legacyPackages.${system}.mill
    ammonite
    scalafmt
    scalafix
    metals
    bloop

    # Verilog / SystemVerilog language
    verible
  ];

  xdg.configFile."niri/config.kdl".source = ./config.kdl;

  programs.mpvpaper = {
    enable = true;
  };

  services.remmina.enable = true;
  
  home.sessionVariables = {
    JAVA_HOME = "${javaPkg}";
    COURSIER_CACHE = "${config.xdg.cacheHome}/coursier";
    SBT_OPTS = "-Dsbt.ivy.home=${config.xdg.cacheHome}/ivy2 -Dsbt.global.base=${config.xdg.configHome}/sbt -Dsbt.coursier.home=${config.xdg.cacheHome}/coursier";
  };
}
