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
  ];

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
      font_size = 18;

      background_opacity = 0.75;
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
  in {
    enable = true;
    plugins = with pkgs.vimPlugins; [
      nvim-treesitter
      nvim-treesitter-textobjects
      nvim-treesitter-context
      playground
    ];
    extraLuaConfig = (builtins.readFile ./init.lua) + ''
      require('nvim-treesitter.configs').setup {
        ensure_installed = {},
        parser_install_dir = "${treesitter-parsers}",
        highlight = { enable = true },
        indent = { enable = true },
        incremental_selection = { enable = true }
      }

      vim.opt.rtp:prepend("${treesitter-parsers}")
    '';
    extraConfig = ''
      set expandtab
      set nosmarttab
      set shiftwidth=4
      set tabstop=4
      set softtabstop=4
    '';
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
        fcitx5-chinese-addons
        fcitx5-mozc
        fcitx5-gtk
        fcitx5-material-color
        fcitx5-pinyin-moegirl
        fcitx5-pinyin-zhwiki
      ];
    };
  };

  home.stateVersion = "25.05";
}

