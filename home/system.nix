{
    config,
    pkgs,
    lib,
    inputs,
    ...
}: let
    javaPkg = pkgs.javaPackages.compiler.temurin-bin.jdk-21;
    scalaPkg = pkgs.scala_3;

    vscode-ext = pkgs.nix-vscode-extensions;
in {
    nixpkgs.config.allowUnfree = true;
    nixpkgs.overlays = [
        inputs.vscode-extensions.overlays.default

        (final: prev: {
            nur = {
                repos = {
                    srcres258 = import inputs.my-nur {
                        pkgs = final;
                    };
                };
            };
         })
    ];

    home.packages = with pkgs; [
        pavucontrol
        kdePackages.dolphin
        kdePackages.kate
        kdePackages.okular

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
        jetbrains.idea-ultimate

        pkgs.nur.repos.srcres258.lceda-pro

        flatpak

        feishu

        gtkwave
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

    programs.firefox = {
        enable = true;
        languagePacks = [ "zh-CN" ];
    };

    programs.mpvpaper = {
        enable = true;
    };

    programs.vscode = {
        enable = true;
        package = pkgs.vscode.fhs;

        mutableExtensionsDir = true;

        profiles = {
            default = {
                extensions = with vscode-ext.vscode-marketplace; [
                    ms-ceintl.vscode-language-pack-zh-hans

                    be5invis.vscode-custom-css

                    # Copilot
                    github.copilot
                    github.copilot-chat

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
                ];

                userSettings = let
                    backgroundPicSrc = ./vscode-background.jpg;
                in {
                    "editor.fontSize" = 15;
                    "nix.enableLanguageServer" = true;

                    "files.autoGuessEncoding" = true;
                    "editor.cursorSmoothCaretAnimation" = true;
                    "editor.smoothScrolling" = true;
                    "editor.cursorBlinking" = "smooth";
                    "editor.mouseWheelZoom" = false;
                    "editor.wordWrap" = "on";
                    "editor.suggest.snippetsPreventQuickSuggestions" = false;
                    "editor.acceptSuggestionOnEnter" = "smart";
                    "editor.suggestSelection" = "recentlyUsed";
                    "window.dialogStyle" = "custom";
                    "debug.showBreakpointsInOverviewRuler" = true;

                    "vscode_custom_css.imports" = let
                        bgImagePath = "${backgroundPicSrc}";
                        originalCss = builtins.readFile ./custom-vscode.css;
                        processedCss = builtins.replaceStrings [ "{{BACKGROUND_IMAGE}}" ] [ bgImagePath ] originalCss;
                        customCssFile = pkgs.writeText "custom-vscode.css" processedCss;
                    in [
                        "${customCssFile}"
                    ];
                    "vscode_custom_css.policy" = true;
                    "vscode_custom_css.verbose" = true;
                };
            };
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
}

