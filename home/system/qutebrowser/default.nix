{ ... }: {
  programs.qutebrowser = {
    enable = true;

    settings = {
      editor.command = [ "kitty" "nvim" "{file}" "-c" "normal {line}G{column0}|" ];

      url = let
        blank = "file:///dev/null";
      in {
        start_pages = blank;
        default_page = blank;
      };

      zoom = {
        default = 133;
        levels = map (x: "${builtins.toString x}%") [ 25 33 50 67 75 90 100 125 133 150 175 200 250 300 ];
      };
      fonts = {
        web.size.default = 20; # webpage
        default_size = "13pt"; # UI
      };

      colors.webpage.darkmode = {
        enabled = true;
        policy.images = "never";
      };

      tabs.show = "never";

      downloads = {
        location.directory = "~/Downloads";
        position = "bottom";
      };

      colors = {
        statusbar = {
          normal.bg = "#427b58";
          command.bg = "#427b58";
          normal.fg = "#eeeeee";
          command.fg = "#eeeeee";
        };
        hints = {
          bg = "#427b58";
          match.fg = "#191919";
        };
      };

      content.fullscreen.window = true; # Limit fullscreen to browser window.

      content.blocking.enabled = true;

      # Privacy settings.
      content.canvas_reading = false;
      content.geolocation = false;
      content.webrtc_ip_handling_policy = "default-public-interface-only";
      completion.open_categories = [ "filesystem" ];
      # Set this if proxy is needed.
      #content.proxy = "";
    };
    extraConfig = builtins.readFile ./config.py;
  };
}
