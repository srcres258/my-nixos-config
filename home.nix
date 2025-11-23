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
    kdePackages.dolphin
    kdePackages.kate

    cascadia-code
  ];

  home.sessionVariables = {
    XMODIFIERS = lib.mkForce "@im=fcitx";
    QT_IM_MODULE = lib.mkForce "fcitx";
  };

  xdg.configFile."niri/config.kdl".source = ./config.kdl;

  programs.waybar = {
    enable = true;
    settings = {
      mainBar = {
        # layer = "top";
        # modules-left = [ "sway/workspaces" "sway/mode" ];
        # modules-center = [ "sway/window" ];
        # modules-right = [ "battery" "clock" ];
        # "sway/window" = {
        #   max-length = 50;
        # };
        # battery = {
        #   format = "{capacity}% {icon}";
        #   format-icons = [ "1" "2" "3" "4" "5" ];
        # };
        # clock = {
        #   format-alt = "{:%a, %d. %b  %h:%m}";
        # };

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
          format = "Arch";
          on-click = "wofi --show drun";
          tooltip = false;
        };
        clock = {
          timezone = "Asia/Shanghai";
          format = "{:%Y,%m,%d  %H:%M:%S}";
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
    };
  };

  programs.firefox = {
    enable = true;
    languagePacks = [ "zh-CN" ];
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

