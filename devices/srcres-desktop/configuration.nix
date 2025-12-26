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

    boot.loader.grub.minegrub-theme = {
        enable = true;
        splash = "100% Flakes!";
        background = "background_options/1.8  - [Classic Minecraft].png";
        boot-options-count = 4;
    };
    boot.initrd.kernelModules = [ "amdgpu" ];
    services.xserver.videoDrivers = [ "amdgpu" ];
    hardware.graphics = {
        enable = true;
        extraPackages = with pkgs; [
            # Provides OpenCL ICD loader.
            rocmPackages.clr.icd
        ];
    };

    networking = {
        hostName = "srcres-desktop";
        defaultGateway = "172.16.0.1";

        firewall.enable = false;
    };

    environment.systemPackages = with pkgs; [
        # Add other system-wide ROCm tools.
        rocmPackages.rocminfo
        ocl-icd
    ];

# Enable deepcool display
    services.hardware.deepcool-digital-linux = {
        enable = true;
        extraArgs = [
            "--mode" "cpu_temp"
                "--update" "500"
                "--alarm"
        ];
    };

    hardware.amdgpu.opencl.enable = true;

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

