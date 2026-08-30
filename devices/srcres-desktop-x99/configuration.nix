# Edit this configuration file to define what should be installed on
# your system. Help is available in the configuration.nix(5) man page, on
# https://search.nixos.org/options and in the NixOS manual (`nixos-help`).

{ pkgs
, ...
}: {
  imports =
    [
      # Include the results of the hardware scan.
      ./hardware-configuration.nix
    ];

  boot.loader = {
    systemd-boot.enable = true;
    efi = {
      canTouchEfiVariables = true;
      efiSysMountPoint = "/boot";
    };
    timeout = 3;
  };
  boot.kernelPackages = pkgs.linuxKernel.packages.linux_zen;

  boot.initrd.kernelModules = [ "amdgpu" ];
  boot.kernelParams = [
    "mem=12G"
  ];
  services.xserver.videoDrivers = [ "amdgpu" ];
  hardware.graphics = {
    enable = true;
    extraPackages = with pkgs; [
      # Provides OpenCL ICD loader.
      rocmPackages.clr.icd
    ];
  };

  networking = {
    hostName = "srcres-desktop-x99";
    defaultGateway = "172.16.0.1";

    firewall.enable = false;
  };

  # v2raya for VPN
  services.v2raya.enable = true;
  networking.nftables.enable = true;

  environment.systemPackages = with pkgs; [
    # Add other system-wide ROCm tools.
    rocmPackages.rocminfo
    ocl-icd
  ];

  hardware.amdgpu.opencl.enable = true;

  # Enable the OpenSSH daemon.
  services.openssh = {
    enable = true;
    openFirewall = true;
  };

  # frp config
  services.frp.instances.main = {
    enable = true;
    role = "client";

    environmentFiles = [
      "/etc/frp-token"
    ];

    settings = {
      serverAddr = "my-server.srcres.top";
      serverPort = 7000;

      auth = {
        method = "token";
        token = "$FRP_TOKEN";
      };

      proxies = [
        {
          name = "mc-server";
          type = "tcp";
          localIP = "127.0.0.1";
          localPort = 11455;
          remotePort = 11451;
        }
      ];
    };
  };

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
  system.stateVersion = "26.05"; # Did you read the comment?
}

