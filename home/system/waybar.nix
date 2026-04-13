{ ... }: {
  programs.waybar = {
    enable = true;
    settings = {
      mainBar = {
        layer = "top";
        position = "top";
        autohide = true;
        autohide-blocked = false;
        exclusive = true;
        passthrough = false;
        gtk-layer-shell = true;

        # === Modules Order ===
        modules-left = [
          "custom/archicon"
          "clock"
          "cpu"
          "memory"
          "disk"
          "temperature"
          "keyboard-state"
        ];
        modules-center = [
          "hyprland/workspaces"
        ];
        modules-right = [
          "wlr/taskbar"
          "tray"
          "idle_inhibitor"
          "pulseaudio/slider"
          "pulseaudio"
          "network"
          "hyprland/language"
        ];

        # === Modules Left ===
        "custom/archicon" = {
          format = "Start";
          on-click = "wofi --show drun";
          tooltip = false;
        };
        clock = {
          timezone = "Asia/Shanghai";
          format = "{:%Y,%m,%d  %H:%M}";
          tooltip-format = "{calendar}";
          calendar = {
            mode = "month";
          };
        };
        cpu = {
          format = "{usage}% CPU";
          tooltip = true;
          tooltip-format = "Usage: {usage}%\nCores: {cores}";
        };
        memory = {
          format = "{}% Mem";
          tooltip = true;
          tooltip-format = "RAM used: {used} / {total} ({percentage}%)";
        };
        disk = {
          format = "{}% Free Disk";
          tooltip = true;
          tooltip-format = "Disk available: {free} / {total} ({percentage_free}%)";
        };
        temperature = {
          format = "{temperatureC}°C {icon}";
          tooltip = true;
          tooltip-format = "Temperature: {temperatureC}°C";
          format-icons = [
            "Temp"
          ];
        };
        keyboard-state = {
          interval = 10;
          capslock = true;
          numlock = false;
          scrolllock = false;

          format-capslock-on = "CapsLock ON";
          format-capslock-off = "CapsLock OFF";

          tooltip = true;
          tooltip-format-capslock-on = "CapsLock is ON";
          tooltip-format-capslock-off = "CapsLock is OFF";
        };

        # === Modules Center ===
        "hyprland/workspaces" = {
          format = "{icon}";
          format-icons = {
            default = "D";
            active = "A";
          };
          persistent-workspaces = {
            "*" = 2;
          };
          disable-scroll = true;
          all-outputs = true;
          show-special = true;
        };

        # === Modules Right ===
        "wlr/taskbar" = {
          format = "{icon}";
          all-outputs = true;
          active-first = true;
          tooltip-format = "{name}";
          on-click = "activate";
          on-click-middle = "close";
          ignore-list = [
            "rofi"
          ];
        };
        tray = {
          icon-size = 21;
          spacing = 10;
        };
        idle_inhibitor = {
          format = "{icon}";
          format-icons = {
            activated = "A";
            deactivated = "D";
          };
        };
        "pulseaudio/slider" = {
          format = "{volume}%";
          format-muted = "M";
          step = 5;
          tooltip = false;
        };
        pulseaudio = {
          on-click = "pavucontrol";
          format = "{volume}% {icon}";
          format-muted = "M {format_source}";
          format-icons = {
            default = [
              "Unmuted"
            ];
          };
        };
        network = {
          format = "{ifname}";
          format-ethernet = "{ifname} Eth";
          format-disconnected = "Disc";
          tooltip-format = "Net {ifname} via {gwaddr}";
          tooltip-format-ethernet = "Net Eth {ifname} {ipaddr}/{cidr}";
          tooltip-format-disconnected = "Net Disconnected";
          max-length = 50;
        };
        "hyprland/language" = {
          format = "{} Lang";
          on-click = ""; # TODO
          format-es = "ESP";
          format-en = "ENG";
          format-zh = "CHI";
        };
      };
    };
  };

}
