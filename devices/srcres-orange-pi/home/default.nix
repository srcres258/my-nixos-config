{ pkgs
, ...
}: let
  username = "srcres";
in {
  home.username = username;
  home.homeDirectory = "/home/${username}";
  home.stateVersion = "25.11";

  # Orange Pi keeps desktop parity without video wallpaper service.
  programs.mpvpaper.enable = false;

  # Ensure lightweight terminal defaults suitable for SBC resources.
  programs.kitty.settings = {
    enable_audio_bell = false;
    remember_window_size = false;
  };

  home.packages = with pkgs; [
      swaybg
  ];
  
  systemd.user.services."swaybg" = let
      backgroundImg = "/home/${username}/background.jpg";
  in {
      Unit = {
          Description = "Sway static wallpaper background service";
      };
  
      Service = {
          Type = "simple";
          ExecStart = "${pkgs.swaybg}/bin/swaybg --mode full --image ${backgroundImg}";
          Restart = "on-failure";
          RestartSec = 2;
      };
  
      Install = {
          WantedBy = [ "graphical-session.target" ];
          PartOf = [ "graphical-session.target" ];
      };
  };
}
