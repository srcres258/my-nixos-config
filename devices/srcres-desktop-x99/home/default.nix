{
    pkgs,
    ...
}: {
    my.python.packageGenerator = (ps: with ps; [
        # torchWithRocm
        # (torchvision.override { torch = ps.torchWithRocm; })

        torch
        torchvision
    ]);

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

