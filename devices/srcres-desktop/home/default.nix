{ inputs
, system
, ...
}:
let
  zpaper = inputs.zpaper.packages.${system}.default;
in
{
  my.python.packageGenerator = (ps: with ps; [
    # torchWithRocm
    # (torchvision.override { torch = ps.torchWithRocm; })

    torch
    torchvision
  ]);

  systemd.user.services."zpaper" =
    let
      zpaperConfig = ./zpaper.toml;
    in
    {
      Unit = {
        Description = "zpaper dynamic wallpaper";
        After = [ "graphical-session.target" ];
        PartOf = [ "graphical-session.target" ];
      };

      Service = {
        Type = "simple";
        ExecStart = "${zpaper}/bin/zpaper --config ${zpaperConfig}";
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
