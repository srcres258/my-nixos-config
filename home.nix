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

  nixpkgs.config.allowUnfree = true;

  home.packages = with pkgs; [
    pavucontrol
    kdePackages.dolphin
    kdePackages.kate

    cascadia-code

    bilibili
    mission-center
    wpsoffice-cn

    qemu
    vlc

    fastfetch

    telegram-desktop
    discord
    wechat

    # Minecraft launchers
    hmcl
    prismlauncher

    nil
    lua-language-server
    rust-analyzer
    pyright
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
  ];
  home.sessionVariables = {
    EDITOR = "nvim";
    VISUAL = "nvim";
  };

  xdg.configFile."niri/config.kdl".source = ./config.kdl;

  programs.waybar = {
    enable = true;
    settings = {
      mainBar = {
        layer = "top";
        position = "top";
        autohide = true;
        autohide-blocked = false;
        exclusive = true;
        passthrough = false;
        gtk-layer-shell = true;

        # === Modules Order ===
        modules-left = [
          "custom/archicon"
          "clock"
          "cpu"
          "memory"
          "disk"
          "temperature"
        ];
        modules-center = [
          "hyprland/workspaces"
        ];
        modules-right = [
          "wlr/taskbar"
          "tray"
          "idle_inhibitor"
          "pulseaudio/slider"
          "pulseaudio"
          "network"
          "hyprland/language"
        ];

        # === Modules Left ===
        "custom/archicon" = {
          format = "Start";
          on-click = "wofi --show drun";
          tooltip = false;
        };
        clock = {
          timezone = "Asia/Shanghai";
          format = "{:%Y,%m,%d  %H:%M}";
          tooltip-format = "{calendar}";
          calendar = {
            mode = "month";
          };
        };
        cpu = {
          format = "{usage}% CPU";
          tooltip = true;
          tooltip-format = "Usage: {usage}%\nCores: {cores}";
        };
        memory = {
          format = "{}% Mem";
          tooltip = true;
          tooltip-format = "RAM used: {used} / {total} ({percentage}%)";
        };
        disk = {
          format = "{}% Disk";
          tooltip = true;
          tooltip-format = "Disk available: {free} / {total} ({percentage_free}%)";
        };
        temperature = {
          format = "{temperatureC}°C {icon}";
          tooltip = true;
          tooltip-format = "Temperature: {temperatureC}°C";
          format-icons = [
            "Temp"
          ];
        };

        # === Modules Center ===
        "hyprland/workspaces" = {
          format = "{icon}";
          format-icons = {
            default = "D";
            active = "A";
          };
          persistent-workspaces = {
            "*" = 2;
          };
          disable-scroll = true;
          all-outputs = true;
          show-special = true;
        };

        # === Modules Right ===
        "wlr/taskbar" = {
          format = "{icon}";
          all-outputs = true;
          active-first = true;
          tooltip-format = "{name}";
          on-click = "activate";
          on-click-middle = "close";
          ignore-list = [
            "rofi"
          ];
        };
        tray = {
          icon-size = 21;
          spacing = 10;
        };
        idle_inhibitor = {
          format = "{icon}";
          format-icons = {
            activated = "A";
            deactivated = "D";
          };
        };
        "pulseaudio/slider" = {
          format = "{volume}%";
          format-muted = "M";
          step = 5;
          tooltip = false;
        };
        pulseaudio = {
          on-click = "pavucontrol";
          format = "{volume}% {icon}";
          format-muted = "M {format_source}";
          format-icons = {
            default = [
              "Unmuted"
              "Muted"
            ];
          };
        };
        network = {
          format = "{ifname}";
          format-ethernet = "{ifname} Eth";
          format-disconnected = "Disc";
          tooltip-format = "Net {ifname} via {gwaddr}";
          tooltip-format-ethernet = "Net Eth {ifname} {ipaddr}/{cidr}";
          tooltip-format-disconnected = "Net Disconnected";
          max-length = 50;
        };
        "hyprland/language" = {
          format = "{} Lang";
          on-click = ""; # TODO
          format-es = "ESP";
          format-en = "ENG";
          format-zh = "CHI";
        };
      };
    };
  };

  programs.kitty = {
    enable = true;
    settings = {
      font_family = "Cascadia Mono PL";
      font_size = 15;

      background_opacity = 0.8;
      dynamic_background_opacity = "yes";

      allow_remote_control = "yes";

      strip_trailing_spaces = "smart";

      # Cursor animations
      cursor_blink_interval = "-1 ease-in-out";
      cursor_stop_blinking_after = 0;
      cursor_trail = 1;
      cursor_trail_decay = "0.1 0.4";
      cursor_trail_start_threshold = 5;
      cursor_trail_color = "none";
    };
  };

  programs.firefox = {
    enable = true;
    languagePacks = [ "zh-CN" ];
  };

  programs.wofi = {
    enable = true;
    settings = {
      term = "kitty";
    };
  };

  programs.vscode = {
    enable = true;
    # TODO
  };

  programs.yazi = {
    enable = true;
    # TODO
  };

  programs.neovim = let
    treesitter-parsers = pkgs.symlinkJoin {
      name = "treesitter-parsers";
      paths = with pkgs.vimPlugins.nvim-treesitter.builtGrammars; [
        bash c cpp css dockerfile go html java javascript json
        lua nix python regex rust toml typescript vim yaml markdown
      ];
    };
    nvim-treesitter-parsers-plugins = with pkgs.vimPlugins.nvim-treesitter-parsers; [
      bash c cpp css dockerfile go html java javascript json
      lua nix python regex rust toml typescript vim yaml markdown
      comment
    ];
  in {
    enable = true;
    plugins = (with pkgs.vimPlugins; [
      nvim-treesitter
      nvim-treesitter-textobjects
      nvim-treesitter-context
      playground

      nvim-lspconfig
      lsp-zero-nvim

      friendly-snippets

      blink-cmp

      catppuccin-nvim
      lualine-nvim
      barbar-nvim
      nvim-tree-lua
      rainbow-delimiters-nvim
      noice-nvim
      nvim-web-devicons

      codecompanion-nvim
      nvim-cmp

      lazydev-nvim
      which-key-nvim
      snacks-nvim
      nvim-autopairs
      trim-nvim
      undotree
      comment-nvim
      smartyank-nvim
      flash-nvim
      plenary-nvim
      todo-comments-nvim
      mini-ai
      # multicursor-nvim
      vim-wakatime

      nvim-lint
      trouble-nvim

      gitsigns-nvim
      mini-diff
      nvim-scrollbar
      nvim-hlslens
      nvim-colorizer-lua
      # showkeys
      nvim-lightbulb
      nvim-ufo

      lazy-nvim
    ]) ++ (with pkgs.vimUtils; [
      (buildVimPlugin {
        pname = "fittencode.nvim";
        version = "master";
        src = pkgs.fetchFromGitHub {
          owner = "luozhiya";
          repo = "fittencode.nvim";
          rev = "be2e6e8345bb76922fae37012af10c3cc51585b5";
          hash = "sha256-5uwphoIaDyf4R4ZjZz4IWnaG7E3iPHyztYDbD3twbFA=";
        };
      })
    ]) ++ nvim-treesitter-parsers-plugins;
    extraLuaConfig = (builtins.readFile ./init.lua) + ''
      require('nvim-treesitter.configs').setup {
        ensure_installed = {},
        parser_install_dir = "${treesitter-parsers}",
        highlight = { enable = true },
        indent = { enable = true },
        incremental_selection = { enable = true },

        textobjects = {
          select = {
            enable = true,
            lookahead = true,
            keymaps = {
              ["af"] = "@function.outer",
              ["if"] = "@function.inner",
              ["ac"] = "@class.outer",
              ["ic"] = "@class.inner"
            }
          },
          move = {
            enable = true,
            set_jumps = true, -- enable function-jumping features by ']m' or '[m'
            goto_next_start = { ["]m"] = "@function.outer" },
            goto_previous_start = { ["[m"] = "@function.outer" }
          }
        },

        -- commonly used features in addition
        context_commentstring = { enable = true }, -- integration with nvim-ts-context-commentstring
        autotag = { enable = true }, -- integration with nvim-ts-autotag to close up HTML/JSX tags automatically
        rainbow = { enable = true, extended_mode = true } -- rainbow blankets (requires nvim-ts-rainbow2)
      }

      vim.opt.rtp:prepend("${treesitter-parsers}")
    '';
  };

  programs.lazygit.enable = true;

  programs.fzf.enable = true;

  programs.mpvpaper = {
    enable = true;
  };

  programs.texlive = {
    enable = true;
    extraPackages = tpkgs: {
      inherit (tpkgs)
        collection-basic
        collection-latex
        collection-latexextra
        collection-fontsrecommended
        collection-langchinese
        collection-bibtexextra
        # collection-science
        collection-pictures
        collection-publishers;
    };
  };

  fonts.fontconfig = {
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

  i18n.inputMethod = {
    enable = true;
    type = "fcitx5";
    fcitx5 = {
      addons = with pkgs; [
        qt6Packages.fcitx5-chinese-addons
        fcitx5-mozc
        fcitx5-gtk
        fcitx5-material-color
        fcitx5-pinyin-moegirl
        fcitx5-pinyin-zhwiki
      ];
    };
  };

  systemd.user.services."mpvpaper" = let
    wallpaperSrc = ./wallpapers/bg.mp4;
    mpvOptions = [
      "loop=inf no-audio hwdec=vaapi vaapi-device=/dev/dri/renderD128"
    ];
  in {
    Unit = {
      Description = "mpvpaper dynamic wallpaper";
    };

    Service = {
      Type = "simple";
      ExecStart = "${pkgs.mpvpaper}/bin/mpvpaper -o '${builtins.concatStringsSep " " mpvOptions}' '*' ${wallpaperSrc}";
      Restart = "on-failure";
      RestartSec = 2;
    };

    Install = {
      WantedBy = [ "graphical-session.target" ];
    };
  };

  # !IMPORTANT!
  # This option should NOT be changed, except for installation
  # for a completely new machine or a new user.
  home.stateVersion = "25.05";
}

