{ system
, config
, pkgs
, inputs
, ...
}:
let
  username = "srcres";

  javaPkg = pkgs.javaPackages.compiler.temurin-bin.jdk-21;
  scalaPkg = pkgs.scala_3;
in
{
  imports = [
    ../options.nix

    ./himalaya.nix
    ./newsboat.nix
    ./git.nix
    ./fish.nix
    ./aichat.nix
    ./opencode.nix
    ./neovim.nix
    ./gh.nix

    ./texlive
    ./yazi
  ];

  home = {
    inherit username;
    homeDirectory = "/home/${username}";
  };
  home.sessionPath = [
    "~/.ghcup/bin"
  ];

  nixpkgs.config.allowUnfree = true;
  # nixpkgs.overlays = [
  #     (final: prev: {
  #         nur = {
  #             repos = {
  #                 srcres258 = import inputs.my-nur {
  #                     pkgs = final;
  #                 };
  #             };
  #         };
  #      })
  # ];

  home.packages = with pkgs; [
    cascadia-code

    nil
    lua-language-server
    pyright
    taplo
    marksman

    imagemagick
    tectonic
    ripgrep
    git-extras
    git-credential-outlook

    codespell

    mpv

    write-good
    ncdu
    hyperfine
    fd

    eza

    nodejs_24
    electron
    pnpm

    scons

    wireshark

    hexo-cli

    optnix
    nix-tree

    ffmpeg

    yt-dlp

    kubo

    hlint
    universal-ctags

    android-file-transfer

    unar

    jadx

    thunderbird

    espeak

    haskellPackages.pandoc-crossref

    mediainfo

    # Fonts
    lxgw-wenkai

    shell-gpt

    dmidecode

    img2pdf

    mkdocs

    typst

    graphviz

    minicom

    viu

    poppler-utils

    jmtpfs

    # Nix language
    nixd
    nixpkgs-fmt

    # Rust language
    cargo
    rustc
    rustfmt
    clippy
    rust-analyzer

    (
      let
        base = pkgs.appimageTools.defaultFhsEnvArgs;
      in
      pkgs.buildFHSEnv (base // {
        name = "fhs";
        targetPkgs = pkgs:
          (base.targetPkgs pkgs) ++ (with pkgs; [
            pkg-config
            ncurses
            SDL2
            file
            glibc.static

            # ... add more dependencies here ...
          ]);
        profile = "export FHS=1";
        runScript = "bash";
        extraOutputsToInstall = [ "dev" ];
      })
    )

    gdb

    # Go language
    gopls

    # Python language
    (python313.withPackages (ps: ((with ps; [
      numpy
      pandas
      matplotlib
      requests
      jupyter
      openai
      termcolor
      prompt-toolkit
      aprslib
      web3
      sphinx
      z3-solver
      distlib
    ]) ++ (config.my.python.packageGenerator ps))))
    yapf
    hatch

    # Haskell language
    (haskellPackages.ghcWithPackages (ps: with ps; [
      data-memocombinators
      mtl
    ]))
    cabal-install
    haskell-language-server
    stack

    # Lean language
    elan
  ] ++ (with nur.repos; [
    srcres258.ag
    srcres258.jyyslide-util
    srcres258.adif-manage
    srcres258.bibox
    srcres258.sootty
  ]) ++ [ javaPkg scalaPkg ];
  home.sessionVariables = {
    EDITOR = "nvim";
    VISUAL = "nvim";

    RUST_SRC_PATH = "${pkgs.rustPlatform.rustLibSrc}";
  };
  xdg.enable = true;
  xdg.cacheHome = builtins.toPath "/home/${config.home.username}/.cache";

  programs.fzf.enable = true;

  programs.pgcli.enable = true;

  programs.direnv = {
    enable = true;
    nix-direnv.enable = true;
  };

  programs.go.enable = true;

  programs.pandoc.enable = true;

  programs.fastfetch = {
    enable = true;
    settings =
      let
        logoFile = ./furry.lgo;
      in
      {
        modules = [
          "title"
          "separator"
          "os"
          "host"
          "kernel"
          "uptime"
          "packages"
          "shell"
          "display"
          "de"
          "wm"
          "wmtheme"
          "theme"
          "icons"
          "font"
          "cursor"
          "terminal"
          "terminalfont"
          "cpu"
          "gpu"
          "memory"
          "swap"
          "disk"
          "localip"
          "battery"
          "poweradapter"
          "locale"
          "break"
          "colors"
        ];
        logo = {
          type = "auto"; # Logo type: auto, builtin, small, file, etc.
          source = "${logoFile}"; # Built-in logo name or file path
          width = 35; # Width in characters (for image logos)
          height = 35; # Height in characters (for image logos)
          padding = {
            top = 0; # Top padding
            left = 0; # Left padding
            right = 2; # Right padding
          };
          color = {
            # Override logo colors
            "1" = "blue";
            "2" = "green";
          };
        };
      };
  };

  programs.poetry.enable = true;

  programs.password-store.enable = true;

  programs.gpg.enable = true;

  services.gpg-agent = {
    enable = true;
    enableSshSupport = true;
    pinentry.package = pkgs.pinentry-tty;
  };

  fonts.fontconfig = {
    enable = true;
    defaultFonts = {
      emoji = [ "Noto Color Emoji" ];
      monospace = [
        "Noto Sans Mono CJK SC"
        "Sarasa Mono SC"
        "DejaVu Sans Mono"
      ];
      sansSerif = [
        "Noto Sans CJK SC"
        "Source Han Sans SC"
        "DejaVu Sans"
      ];
      serif = [
        "Noto Serif CJK SC"
        "Source Han Serif SC"
        "DejaVu Serif"
      ];
    };
  };
}

