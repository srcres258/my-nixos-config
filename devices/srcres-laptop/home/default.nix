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

    systemd.user.services.swaybg = let
        backgroundImg = ./wallpapers/bg.png;
    in {
        description = "Sway static wallpaper background service";
        wantedBy = [ "graphical-session.target" ];
        partOf = [ "graphical-session.target" ];
        serviceConfig = {
            Type = "simple";
            Restart = "on-failure";
            ExecStart = "${pkgs.swaybg}/bin/swaybg --mode full --image ${backgroundImg}";
        };
    };
}

