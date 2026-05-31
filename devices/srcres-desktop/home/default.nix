{ config
, pkgs
, lib
, inputs
, ...
}: {
  home.packages = with pkgs; [
    mpv
    mpvpaper
    file
  ];

  my.python.packageGenerator = (ps: with ps; [
    # torchWithRocm
    # (torchvision.override { torch = ps.torchWithRocm; })

    torch
    torchvision
  ]);

  systemd.user.services."mpvpaper" =
    let
      username = "srcres";
      defaultWallpaper = "/home/${username}/wallpaper.mp4";
      mpvOptions = "loop=inf no-audio hwdec=vaapi vaapi-device=/dev/dri/renderD128";
      mpvpaperScript = pkgs.writeShellScript "mpvpaper-start" ''
        BG_CONFIG="$HOME/.mpvpaper-bg"
        DEFAULT="${defaultWallpaper}"
        MPV_OPTIONS="${mpvOptions}"
        MPVPAPER="${pkgs.mpvpaper}/bin/mpvpaper"
        FILE_CMD="${pkgs.file}/bin/file"

        # Try user-defined wallpaper from ~/.mpvpaper-bg
        if [ -f "$BG_CONFIG" ]; then
          WALLPAPER=$(head -n1 "$BG_CONFIG" | sed 's/^[[:space:]]*//;s/[[:space:]]*$//')
          # Expand leading ~ to user's home directory
          WALLPAPER="''${WALLPAPER/#~/$HOME}"
          if [ -n "$WALLPAPER" ] && [ -f "$WALLPAPER" ]; then
            if "$FILE_CMD" -b --mime-type "$WALLPAPER" | grep -q "^video/"; then
              exec "$MPVPAPER" -o "$MPV_OPTIONS" '*' "$WALLPAPER"
            fi
          fi
        fi

        # Fallback to default wallpaper
        if [ -f "$DEFAULT" ]; then
          exec "$MPVPAPER" -o "$MPV_OPTIONS" '*' "$DEFAULT"
        fi

        # Neither source is usable — log error and exit
        echo "mpvpaper: No usable wallpaper found." >&2
        echo "mpvpaper: Checked ~/.mpvpaper-bg (absent, empty, or invalid video path) and ''${DEFAULT} (not found)." >&2
        echo "mpvpaper: Place a valid mp4 video at ''${DEFAULT} or set a path in ~/.mpvpaper-bg." >&2
        exit 1
      '';
    in
    {
      Unit = {
        Description = "mpvpaper dynamic wallpaper";
        After = [ "niri.service" ];
        BindsTo = [ "niri.service" ];
      };

      Service = {
        Type = "simple";
        ExecStart = "${mpvpaperScript}";
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

