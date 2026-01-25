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

    environment.systemPackages = with pkgs; [
        docker-compose
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
        enable = true;
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

