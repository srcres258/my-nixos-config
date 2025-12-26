{
    config,
    pkgs,
    lib,
    inputs,
    ...
}: {
    # systemd.user.services."mpvpaper" = let
    #     wallpaperSrc = ./wallpapers/bg.mp4;
    #     mpvOptions = [
    #         "loop=inf no-audio hwdec=vaapi"
    #     ];
    # in {
    #     Unit = {
    #         Description = "mpvpaper dynamic wallpaper";
    #     };
    #
    #     Service = {
    #         Type = "simple";
    #         ExecStart = "${pkgs.mpvpaper}/bin/mpvpaper -o '${builtins.concatStringsSep " " mpvOptions}' '*' ${wallpaperSrc}";
    #         Restart = "on-failure";
    #         RestartSec = 2;
    #     };
    #
    #     Install = {
    #         WantedBy = [ "graphical-session.target" ];
    #     };
    # };
}

