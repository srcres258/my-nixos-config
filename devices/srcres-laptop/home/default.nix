{ config
, pkgs
, lib
, inputs
, ...
}: {
  # home.packages = with pkgs; [
  #     swaybg
  # ];
  #
  # systemd.user.services."swaybg" = let
  #     backgroundImg = ./wallpapers/bg.png;
  # in {
  #     Unit = {
  #         Description = "Sway static wallpaper background service";
  #     };
  #
  #     Service = {
  #         Type = "simple";
  #         ExecStart = "${pkgs.swaybg}/bin/swaybg --mode full --image ${backgroundImg}";
  #         Restart = "on-failure";
  #         RestartSec = 2;
  #     };
  #
  #     Install = {
  #         WantedBy = [ "graphical-session.target" ];
  #         PartOf = [ "graphical-session.target" ];
  #     };
  # };

  # !IMPORTANT!
  # This option should NOT be changed, except for installation
  # for a completely new machine or a new user.
  home.stateVersion = "25.05";
}

