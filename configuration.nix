{
    inputs,
    config,
    lib,
    pkgs,
    srcres-password,
    ...
}: {
    nix.gc.automatic = false;

    networking.networkmanager.enable = true;
# Open some ports for testing purposes.
    networking.firewall = {
        allowedTCPPorts = [ 11451 ];
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

# Define a user account. Don't forget to set a password with ‘passwd’.
    users.users.srcres = {
        initialPassword = srcres-password;
        isNormalUser = true;
        description = "src_resources";
        extraGroups = [
            "wheel" # Enable ‘sudo’ for the user.
            "networkmanager"
            "audio"
            "docker"
            "wireshark"
        ];
        shell = pkgs.fish;
    };

    nix.settings.experimental-features = [ "nix-command" "flakes" ];

# List packages installed in system profile.
# You can use https://search.nixos.org/ to find more packages (and options).
    environment.systemPackages = with pkgs; ([
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
        rar
        unrar

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

        nix-output-monitor

        killall

        pv

        net-tools
    ]);
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

    programs.nh.enable = true;

    programs.wireshark.enable = true;

# List services that you want to enable:

# Enable the OpenSSH daemon.
    services.openssh = {
        enable = true;
        settings = {
            X11Forwarding = true;
            PermitRootLogin = "yes";
            PasswordAuthentication = true;
        };
        openFirewall = true;
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

            terminus_font

            cascadia-code
        ];
        fontDir.enable = true;
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

    services.flatpak.enable = true;

# Ethereum private blockchain config.
    # services.ethereum.geth.myprivate = {
    #     enable = true;
    #     openFirewall = true;
    #     args = {
    #         networkid = 114514;
    #         nodiscover = true;
    #         mine = true;
    #         miner = {
    #             threads = 1;
    #             etherbase = "0xYourAccountAddress";
    #         };
    #         http = {
    #             enable = true;
    #             addr = "0.0.0.0";
    #             port = 8545;
    #             api = [ "eth" "net" "web3" "personal" "miner" ];
    #         };
    #         syncmode = "full";
    #     };
    #     extraArgs = [
    #         "--datadir" "/var/lib/geth-myprivate"
    #         "--unlock" "0xYourAccountAddress"
    #         "--password" "/path/to/password.txt"
    #         "--allow-insecure-unlock"
    #     ];
    # };

# Remove nix-channel related tools & configs, we use flakes instead.
    nix.channel.enable = false;

    nix.settings.substituters = [
        "https://mirror.sjtu.edu.cn/nix-channels/store"
        "https://mirrors.ustc.edu.cn/nix-channels/store"
    ];
}

