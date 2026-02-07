{
    inputs,
    config,
    lib,
    pkgs,
    srcres-password,
    ...
}: {
    imports = [
        inputs.minegrub-theme.nixosModules.default
    ];

    boot.loader = {
        grub = {
            enable = true;
            device = "nodev";
            efiSupport = true;
            useOSProber = true;
            configurationLimit = 10;
        };
        efi = {
            canTouchEfiVariables = true;
            efiSysMountPoint = "/boot";
        };
        timeout = 10;
    };
    boot.kernelPackages = pkgs.linuxKernel.packages.linux_zen;
# Enable cross-compile toolchains by emulation.
    boot.binfmt.emulatedSystems = [ "riscv64-linux" ];
# Enable NTFS filesystem support.
    boot.supportedFilesystems = [ "ntfs" ];
# Enable extra kernel modules.
    boot.extraModulePackages = with config.boot.kernelPackages; [
        v4l2loopback
    ];
    boot.kernelModules = [ "v4l2loopback" ];
    boot.extraModprobeConfig = ''
        options v4l2loopback devices=1
        options v4l2loopback video_nr=10
        options v4l2loopback card_label="Virtual Cam"
        options v4l2loopback exclusive_caps=1
        options v4l2loopback max_width=4096
        options v4l2loopback max_height=4096
    '';

    environment.systemPackages = with pkgs; [
        docker-compose
        v4l-utils
    ];

# Allow normal users to mount NTFS filesystems.
    security.polkit.enable = true;
    services.udisks2.enable = true;

# Enable sound.
    services.pipewire = {
        enable = true;
        pulse.enable = true;
    };

# Enable touchpad support (enabled default in most desktopManager).
# services.libinput.enable = true;

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

    console.packages = with pkgs; [
        terminus_font
    ];

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

    services.postgresql = {
        enable = lib.mkDefault false;
        package = pkgs.postgresql_14;

        settings = {
            ssl = true;
        };

        dataDir = "/var/lib/postgresql/14";
    };

    security.pam.services.greetd.kwallet.enable = true;

# Docker
    virtualisation.docker = {
        enable = false;
        storageDriver = "btrfs";
        rootless = {
            enable = true;
            setSocketVariable = true;
        };
    };
}

