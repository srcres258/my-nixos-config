{
    config,
    pkgs,
    lib,
    inputs,
    ...
}: {
    home.packages = with pkgs; [
        swaybg
    ];

    systemd.user.services."swaybg" = let
        backgroundImg = ./wallpapers/bg.png;
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

        Instapp = {
            wantedBy = [ "graphical-session.target" ];
            partOf = [ "graphical-session.target" ];
        };
    };
}

