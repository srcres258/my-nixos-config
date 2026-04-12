{ config
, pkgs
, lib
, inputs
, ...
}: {
  imports = [
    ../../../home/options.nix

    ../../../home/pure/git.nix
    ../../../home/pure/fish.nix
    ../../../home/pure/aichat.nix
    ../../../home/pure/opencode.nix
    ../../../home/pure/neovim.nix
    ../../../home/pure/gh.nix
    ../../../home/pure/texlive

    ../../../home/system/default.nix

    ./vscode.nix
  ];

  home.packages = with pkgs; [
    # Keep desktop parity with srcres-desktop base while tailoring to ARM.
    cascadia-code

    nil
    lua-language-server
    taplo
    marksman

    imagemagick
    tectonic
    ripgrep
    git-extras

    codespell

    mpv

    write-good
    ncdu
    hyperfine
    fd
    eza

    # C / Rust development focus
    cargo
    rustc
    rustfmt
    clippy
    rust-analyzer
    gcc
    gdb

    # Academic writing / research
    typst
    zathura

    # Nix language
    nixd
    nixpkgs-fmt

    # Optional local Python tooling hook support
    (python313.withPackages (ps: config.my.python.packageGenerator ps))
    yapf

    graphviz
    ffmpeg
    yt-dlp

    # Fonts
    lxgw-wenkai
  ] ++ (with pkgs.nur.repos; [
    srcres258.ag
    srcres258.jyyslide-util
  ]);

  home.sessionPath = [
    "~/.ghcup/bin"
  ];

  home.sessionVariables = {
    EDITOR = "nvim";
    VISUAL = "nvim";

    RUST_SRC_PATH = "${pkgs.rustPlatform.rustLibSrc}";
  };
  
  # Override the shared niri config for Orange Pi 5 (RK3588S).
  #
  # The RK3588 SoC exposes two DRM devices:
  #   card0 / renderD128 = panthor (Mali G610, 3D rendering, no display output)
  #   card1              = rockchip-drm (display output, no 3D)
  #
  # Without an explicit render-drm-device, niri/smithay's automatic device
  # enumeration may attempt EGL initialisation on the rockchip-drm node that
  # has no 3D capability, causing an immediate SIGSEGV.
  #
  # See: https://github.com/niri-wm/niri/wiki/Getting-Started#asahi-arm-and-other-kmsro-devices
  xdg.configFile."niri/config.kdl".text = ''
    debug {
        render-drm-device "/dev/dri/renderD128"
    }

    input {
        keyboard {
            xkb {
                layout "us"
            }
        }

        touchpad {
            tap
            natural-scroll
        }
    }

    hotkey-overlay {
        skip-at-startup
    }

    binds {
        Mod+Return { spawn "kitty"; }
        Mod+Q { close-window; }
        Mod+Shift+Q { quit; }

        Mod+Left  { focus-column-left; }
        Mod+Right { focus-column-right; }
        Mod+Down  { focus-window-down; }
        Mod+Up    { focus-window-up; }

        Mod+Shift+Left  { move-column-left; }
        Mod+Shift+Right { move-column-right; }
    }

    layout {
        gaps 8
        default-column-width { proportion 0.5; }
    }
  '';

  xdg.enable = true;
  xdg.cacheHome = builtins.toPath "/home/${config.home.username}/.cache";

  programs.fzf.enable = true;

  programs.direnv = {
    enable = true;
    nix-direnv.enable = true;
  };

  programs.pandoc.enable = true;

  programs.password-store.enable = true;
  programs.gpg.enable = true;
  services.gpg-agent = {
    enable = true;
    enableSshSupport = true;
    pinentry.package = pkgs.pinentry-tty;
  };

  programs.fastfetch = {
    enable = true;
    settings =
      let
        logoFile = ../../../home/pure/furry.lgo;
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
          type = "auto";
          source = "${logoFile}";
          width = 35;
          height = 35;
          padding = {
            top = 0;
            left = 0;
            right = 2;
          };
          color = {
            "1" = "blue";
            "2" = "green";
          };
        };
      };
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
