# Edit this configuration file to define what should be installed on
# your system. Help is available in the configuration.nix(5) man page, on
# https://search.nixos.org/options and in the NixOS manual (`nixos-help`).

{
    inputs,
    config,
    lib,
    pkgs,
    srcres-password,
    ...
}: {
    imports =
        [ # Include the results of the hardware scan.
            ./hardware-configuration.nix
        ];

    boot.loader = {
        grub = {
            enable = true;
            device = "nodev";
            efiSupport = true;
            useOSProber = true;
            configurationLimit = 10;

            minegrub-theme = {
                enable = true;
                splash = "100% Flakes!";
                background = "background_options/1.8  - [Classic Minecraft].png";
                boot-options-count = 4;
            };
        };
        efi = {
            canTouchEfiVariables = true;
            efiSysMountPoint = "/boot";
        };
    };
    boot.kernelPackages = pkgs.linuxKernel.packages.linux_zen;
    boot.initrd.kernelModules = [ "amdgpu" ];
# Enable cross-compile toolchains by emulation.
    boot.binfmt.emulatedSystems = [ "riscv64-linux" ];
# Enable NTFS filesystem support.
    boot.supportedFilesystems = [ "ntfs" ];

# Allow normal users to mount NTFS filesystems.
    security.polkit.enable = true;
    services.udisks2.enable = true;

    nix.gc = {
        automatic = true;
        dates = "weekly";
        options = "--delete-older-than 7d";
    };

    networking = {
        hostName = "srcres-computer";
        networkmanager.enable = true;
        defaultGateway = "172.16.0.1";
    };

# Set your time zone.
    time.timeZone = "Asia/Shanghai";
# Use local RTC time inside the hardware.
    time.hardwareClockInLocalTime = true;

# Configure network proxy if necessary
# networking.proxy.default = "http://user:password@proxy:port/";
# networking.proxy.noProxy = "127.0.0.1,localhost,internal.domain";

# Select internationalisation properties.
    i18n.defaultLocale = "en_US.UTF-8";
# console = {
#   font = "Lat2-Terminus16";
#   keyMap = "us";
#   useXkbConfig = true; # use xkb.options in tty.
# };

# Enable the X11 windowing system.
# services.xserver.enable = true;

# Configure keymap in X11
# services.xserver.xkb.layout = "us";
# services.xserver.xkb.options = "eurosign:e,caps:escape";

# Enable CUPS to print documents.
# services.printing.enable = true;

# Enable sound.
    services.pipewire = {
        enable = true;
        pulse.enable = true;
    };

# Enable touchpad support (enabled default in most desktopManager).
# services.libinput.enable = true;

# Enable deepcool display
    services.hardware.deepcool-digital-linux = {
        enable = true;
        extraArgs = [
            "--mode" "cpu_temp"
                "--update" "500"
                "--alarm"
        ];
    };

# Define a user account. Don't forget to set a password with ‘passwd’.
    users.users.srcres = {
        initialPassword = srcres-password;
        isNormalUser = true;
        description = "src_resources";
        extraGroups = [ "wheel" "networkmanager" "audio" ]; # Enable ‘sudo’ for the user.
            shell = pkgs.fish;
    };

# These users are added for testing purposes only.
# users.users = {
#   wangming = {
#     isNormalUser = true;
#     initialPassword = "123456";
#   };
#   ligang = {
#     isNormalUser = true;
#     initialPassword = "123456";
#   };
# };

    nix.settings.experimental-features = [ "nix-command" "flakes" ];

# List packages installed in system profile.
# You can use https://search.nixos.org/ to find more packages (and options).
    environment.systemPackages = with pkgs; [
        home-manager

# Use Niri as the desktop environment.
        niri
        xwayland-satellite

        vim # Do not forget to add an editor to edit configuration.nix! The Nano editor is also installed by default.
        wget
        git
        fish

        tree
        pstree

        zip
        xz
        unzip
        p7zip

        cowsay
        file
        which
        tree
        gnused
        gnutar
        gawk
        zstd
        gnupg

        btop

        strace
        ltrace
        lsof

        sysstat
        lm_sensors
        ethtool
        pciutils
        usbutils

        wireplumber
        brightnessctl

        amdgpu_top
        mesa

        python312

        bluez-experimental

        gcc
        clang
        gnumake
        ccache

# Java
        jetbrains.jdk
        javaPackages.compiler.temurin-bin.jdk-21

        libmtp

        dig

# qBittorrent
        qbittorrent-enhanced

        jq
    ];
    environment.variables.EDITOR = "vim";

    programs.fish.enable = true;

    programs.niri.enable = true;

    programs.java = {
        enable = true;
        package = pkgs.jetbrains.jdk; # Use Jetbrains' JDK by default.
    };

    programs.adb.enable = true;

    programs.tmux.enable = true;

    programs.ccache.enable = true;

# Some programs need SUID wrappers, can be configured further or are
# started in user sessions.
# programs.mtr.enable = true;
# programs.gnupg.agent = {
#   enable = true;
#   enableSSHSupport = true;
# };

    programs.gnupg.agent = {
        enable = true;
        enableSSHSupport = true;
        pinentryPackage = pkgs.pinentry-qt;
    };

# List services that you want to enable:

# Enable the OpenSSH daemon.
    services.openssh = {
        enable = true;
        settings = {
            X11Forwarding = true;
            PermitRootLogin = "no"; # disable root login
                PasswordAuthentication = false; # disable password login
        };
        openFirewall = true;
    };

    services.greetd = {
        enable = true;
        settings = {
            default_session = {
                command = "${pkgs.tuigreet}/bin/tuigreet " +
                    "--time --asterisks --remember --remember-session " +
                    "--sessions ${config.services.displayManager.sessionData.desktops}/share/wayland-sessions";
            };
        };
    };

    fonts = {
        packages = with pkgs; [
            adwaita-fonts

                noto-fonts-color-emoji
                nerd-fonts.symbols-only

                noto-fonts-cjk-sans
                noto-fonts-cjk-serif

                source-code-pro
                hack-font
                jetbrains-mono
                maple-mono.variable
        ];
    };

# Open ports in the firewall.
# networking.firewall.allowedTCPPorts = [ ... ];
# networking.firewall.allowedUDPPorts = [ ... ];
# Or disable the firewall altogether.
# networking.firewall.enable = false;

# Copy the NixOS configuration file and link it from the resulting system
# (/run/current-system/configuration.nix). This is useful in case you
# accidentally delete configuration.nix.
# system.copySystemConfiguration = true;

# This enables microcode updates for CPUs, which may improve performance.
    hardware.enableRedistributableFirmware = true;

# Set up Bluetooth.
    hardware.bluetooth = {
        enable = true;
        powerOnBoot = true;
        settings = {
            General = {
                Experimental = true;
                FastConnectable = true;
            };
            Policy = {
                AutoEnable = true;
            };
        };
    };
    services.blueman.enable = true;

    services.gvfs.enable = true;

    services.postgresql.enable = true;

# Remove nix-channel related tools & configs, we use flakes instead.
    nix.channel.enable = false;

# This option defines the first version of NixOS you have installed on this particular machine,
# and is used to maintain compatibility with application data (e.g. databases) created on older NixOS versions.
#
# Most users should NEVER change this value after the initial install, for any reason,
# even if you've upgraded your system to a new NixOS release.
#
# This value does NOT affect the Nixpkgs version your packages and OS are pulled from,
# so changing it will NOT upgrade your system - see https://nixos.org/manual/nixos/stable/#sec-upgrading for how
# to actually do that.
#
# This value being lower than the current NixOS release does NOT mean your system is
# out of date, out of support, or vulnerable.
#
# Do NOT change this value unless you have manually inspected all the changes it would make to your configuration,
# and migrated your data accordingly.
#
# For more information, see `man configuration.nix` or https://nixos.org/manual/nixos/stable/options#opt-system.stateVersion .
    system.stateVersion = "25.05"; # Did you read the comment?
}

