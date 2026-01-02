{
    config,
    pkgs,
    lib,
    inputs,
    ...
}: let
    vscode-ext = pkgs.nix-vscode-extensions;
in {
    nixpkgs.config.allowUnfree = true;
    nixpkgs.overlays = [
        inputs.vscode-extensions.overlays.default
    ];

    home.packages = with pkgs; [
        pavucontrol
        kdePackages.dolphin
        kdePackages.kate
        kdePackages.okular
        kdePackages.kwallet
        kwalletcli

        bilibili
        mission-center
        wpsoffice-cn

        vlc

        telegram-desktop
        discord
        wechat

# Minecraft launchers
        hmcl
        prismlauncher
        portablemc

        gimp

# JetBrains IDEs
        jetbrains.idea
        jetbrains.pycharm

        pkgs.nur.repos.srcres258.lceda-pro

        flatpak

        feishu

        gtkwave

        networkmanagerapplet

        nomacs

        qbittorrent-enhanced
        pkgs.nur.repos.srcres258.peerbanhelper

        cqrlog
        tqsl

        tor-browser

        freecad
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
                        "keyboard-state"
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
                keyboard-state = {
                    interval = 10;
                    capslock = true;
                    numlock = false;
                    scrolllock = false;

                    format-capslock-on = "CapsLock ON";
                    format-capslock-off = "CapsLock OFF";

                    tooltip = true;
                    tooltip-format-capslock-on = "CapsLock is ON";
                    tooltip-format-capslock-off = "CapsLock is OFF";
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
            font_features = "-calt -liga -ss01 -ss02 -ss03 -ss04 -ss05 -ss06 -ss07 -ss08 -ss09 -ss10 -ss11 -ss12 -ss13 -ss14 -ss15 -ss16 -ss17 -ss18 -ss19 -ss20 -ss21 -ss22 -ss23 -ss24 -ss25 -ss26 -ss27 -ss28 -ss29 -ss30 -ss31";
            bold_font = "auto";
            italic_font = "auto";
            bold_italic_font = "auto";
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
        environment = config.home.sessionVariables;
    };

    programs.wofi = {
        enable = true;
        settings = {
            term = "kitty";
        };
    };

    programs.firefox = {
        enable = true;
        languagePacks = [ "zh-CN" ];
    };

    programs.vscode = {
        enable = true;
        package = pkgs.vscode.fhs;

        mutableExtensionsDir = true;

        profiles = {
            default = {
                extensions = with vscode-ext.vscode-marketplace; [
                    ms-ceintl.vscode-language-pack-zh-hans

                    wayou.vscode-todo-highlight
                    wakatime.vscode-wakatime

                    # Theme
                    sdras.night-owl

                    # VSCode Vim
                    vscodevim.vim

                    # Copilot
                    github.copilot

                    # C / C++
                    ms-vscode.cpptools
                    ms-vscode.cmake-tools

                    # Scala
                    scala-lang.scala
                    scala-lang.scala-snippets
                    scalameta.metals

                    # SystemVerilog / Verilog / VHDL
                    mshr-h.veriloghdl

                    # Nix
                    jnoortheen.nix-ide

                    # Haskell
                    haskell.haskell

                    # Python
                    ms-python.python
                    ms-python.debugpy
                    ms-python.vscode-python-envs

                    # Jupyter Notebook
                    ms-toolsai.jupyter
                    ms-toolsai.jupyter-keymap
                    ms-toolsai.vscode-jupyter-slideshow
                    ms-toolsai.vscode-jupyter-cell-tags

                    # Solidity
                    juanblanco.solidity

                    # HTML
                    sidthesloth.html5-boilerplate
                    ecmel.vscode-html-css
                    zignd.html-css-class-completion

                    # JS and TS
                    ms-vscode.vscode-typescript-next
                ];

                userSettings = {
                    "editor.fontFamily" = "'Cascadia Code', 'monospace', monospace, 'Droid Sans Fallback'";
                    "editor.fontSize" = 18;
                    "nix.enableLanguageServer" = true;

                    "files.autoGuessEncoding" = true;
                    "editor.cursorSmoothCaretAnimation" = true;
                    "editor.smoothScrolling" = true;
                    "editor.cursorBlinking" = "smooth";
                    "editor.mouseWheelZoom" = false;
                    "editor.wordWrap" = "off";
                    "editor.suggest.snippetsPreventQuickSuggestions" = false;
                    "editor.acceptSuggestionOnEnter" = "smart";
                    "editor.suggestSelection" = "recentlyUsed";
                    "window.dialogStyle" = "custom";
                    "debug.showBreakpointsInOverviewRuler" = true;

                    "solidity.linter" = "solhint";
                    "solidity.solhintRules" = {
                        avoid-sha3 = "warn";
                    };
                };
            };
        };
    };

    programs.mpvpaper = {
        enable = true;
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
}

