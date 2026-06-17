# Edit this configuration file to define what should be installed on
# your system. Help is available in the configuration.nix(5) man page, on
# https://search.nixos.org/options and in the NixOS manual (`nixos-help`).

{ inputs
, pkgs
, ...
}:
let
  minegrubTheme = pkgs.stdenvNoCC.mkDerivation {
    pname = "minegrub-theme";
    version = "3.1.0";
    src = inputs.minegrub-theme;

    nativeBuildInputs = with pkgs; [
      fastfetch
      (python3.withPackages (p: [ p.pillow ]))
    ];

    patchPhase = ''
      sed -i '$d' minegrub/update_theme.py

      top_value=$((170 + (4 - 2) * 72))
      sed -i '/^+ image {/,/^}$/s/top = 40%+[0-9]\+/top = 40%+'"$top_value"'/' minegrub/theme.txt
    '';

    buildPhase = ''
      python minegrub/update_theme.py "background_options/1.8  - [Classic Minecraft].png" "100% Flakes!"
    '';

    installPhase = ''
      cd minegrub
      mkdir -p $out/grub/themes/minegrub
      cp *.png *.pf2 theme.txt $out/grub/themes/minegrub
    '';
  };
in {
  imports = [
    # Include the results of the hardware scan.
    ./hardware-configuration.nix
  ];

  boot.loader.grub.theme = "${minegrubTheme}/grub/themes/minegrub";
  boot.loader.grub.splashImage = "${minegrubTheme}/grub/themes/minegrub/background.png";
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

  hardware.amdgpu.opencl.enable = true;

  # v2raya for VPN
  services.v2raya.enable = true;

  services.logrotate.checkConfig = false;

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
