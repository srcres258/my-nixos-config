{ config
, pkgs
, lib
, ...
}: {
  imports = [
    ./waybar.nix
    ./qutebrowser
  ];

  home.packages = (with pkgs; [
    pavucontrol
    kdePackages.dolphin
    kdePackages.kate
    kdePackages.okular
    kdePackages.kwallet
    kdePackages.gwenview
    kwalletcli

    piliplus
    mission-center

    vlc

    telegram-desktop

    gimp

    cmakeWithGui

    # Minecraft launchers
    hmcl
    prismlauncher
    portablemc

    gtkwave

    networkmanagerapplet

    nomacs

    cqrlog
    tqsl

    freecad

    calibre

    xclip
    wl-clipboard-rs
  ]) ++ (with pkgs.nur.repos; [
    # srcres258.lceda-pro
  ]);

  programs.kitty = {
    enable = true;
    environment = config.home.sessionVariables;

    settings = {
      font_family = "Cascadia Mono PL";
      font_features = "-calt -liga -ss01 -ss02 -ss03 -ss04 -ss05 -ss06 -ss07 -ss08 -ss09 -ss10 -ss11 -ss12 -ss13 -ss14 -ss15 -ss16 -ss17 -ss18 -ss19 -ss20 -ss21 -ss22 -ss23 -ss24 -ss25 -ss26 -ss27 -ss28 -ss29 -ss30 -ss31";
      bold_font = "auto";
      italic_font = "auto";
      bold_italic_font = "auto";
      font_size = 15;

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

      # Background
      background = "#000000";
      background_tint = 0.05;
      background_opacity = 0.8;
      transparent_background_colors = "#3a3a3a@0.5";
      dim_preserved = "yes";
    };

    mouseBindings = {
      "left click ungrabbed" = "no-op";
      "ctrl+shift+left release grabbed,ungrabbed" = "mouse_click_url";
    };
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

  # mpvpaper is host/platform-specific and is wired from platform home modules.

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
      waylandFrontend = true;
    };
  };

  home.sessionVariables = {
    # env vars for fcitx5 input method
    GTK_IM_MODULE = "fcitx";
    QT_IM_MODULE = "fcitx";
    XMODIFIERS = "@im=fcitx";
    SDL_IM_MODULE = "fcitx";
  };

  services.cliphist.enable = true;
}

