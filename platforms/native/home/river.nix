{ pkgs
, config
, ...
}:

let
  localBinScripts = [
    "audio"
    "bright"
    "wiki"
    "heart"
    "books"
    "blue"
    "speaker"
    "emoji"
    "jdoc"
    "wttr"
    "dcal"
    "lsmus"
    "clip"
    "damblocks"
    "damblocks-mpdd"
    "exiland"
    "hibe"
    "wmenu-run-color"
    "mag"
    "shoot"
    "address"
    "wsk"
    "colors.sh"
    "wmenu-color"
    "scope"
  ];
in
{
  home.packages = with pkgs; [
    # niri-style entrypoints
    kitty
    wofi
    kdePackages.dolphin
    qutebrowser

    # unixchad / kwm script deps
    foot
    wmenu
    fzf
    dmenu
    waylock
    wshowkeys
    firejail
    libnotify
    psmisc
    wireplumber
    pulseaudio
    bluez
    curl
    util-linux
    w3m
    grim
    slurp
    wlr-randr
    swayimg
    maim
    slop
    xrandr
    nsxiv
    cliphist
    xsel
    wob
    xob
    mpd
    mpc
    zathura
    zathuraPkgs.zathura_pdf_mupdf
  ];

  wayland.windowManager.river = {
    enable = true;

    # 很重要：显式使用新版 river，而不是 HM 默认的 river-classic
    package = pkgs.river;

    settings = {
      # 只放 compositor 相关
    };

    extraConfig = ''
      ${config.home.homeDirectory}/.local/bin/damblocks --fifo &
      ${config.home.homeDirectory}/.local/bin/damblocks-mpdd &

      i=0
      while [ "$i" -lt 50 ] && [ ! -p "''${XDG_RUNTIME_DIR}/damblocks.fifo" ]; do
        i=$((i + 1))
        sleep 0.1
      done

      ${pkgs.nur.repos.srcres258.kwm}/bin/kwm &
    '';
  };

  xdg.configFile."kwm/config.zon".source = ./config.zon;

  home.file = builtins.listToAttrs (map
    (name: {
      name = ".local/bin/${name}";
      value = {
        source = ./scripts/${name};
        executable = true;
      };
    })
    localBinScripts);
}
