{ config, pkgs, lib, ... }:

{
  wayland.windowManager.river = {
    enable = true;

    # 很重要：显式使用新版 river，而不是 HM 默认的 river-classic
    package = pkgs.river;

    settings = {
      # 只放 compositor 相关
    };

    extraConfig = ''
      ${pkgs.nur.repos.srcres258.kwm}/bin/kwm &
    '';
  };

  xdg.configFile."kwm/config.zon".source = ./config.zon;
}

