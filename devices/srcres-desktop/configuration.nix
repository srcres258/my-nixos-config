# Edit this configuration file to define what should be installed on
# your system. Help is available in the configuration.nix(5) man page, on
# https://search.nixos.org/options and in the NixOS manual (`nixos-help`).

{ pkgs
, ...
}: {
  imports = [
    # Include the results of the hardware scan.
    ./hardware-configuration.nix
  ];

  boot.loader.systemd-boot = {
    edk2-uefi-shell.enable = true;
    extraEntries."windows.conf" = ''
      title Windows
      efi /efi/edk2-uefi-shell/shell.efi
      options -nointerrupt -nomap -noversion HD1e:\EFI\Microsoft\Boot\Bootmgfw.efi
      sort-key o_windows
    '';
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

  hardware.amdgpu.opencl.enable = true;

  # v2raya for VPN
  services.v2raya.enable = true;

  services.logrotate.checkConfig = false;

  # Windows VM framework: this is a NixOS-system-level module, so keep it here
  # rather than under Home Manager. The ISO paths below are just defaults; you
  # can still override them per `vmctl install` command.
  my.virtualization.windowsVm = {
    enable = true;
    user = "srcres";

    diskPath = "/var/lib/libvirt/images/windows-main.qcow2";
    diskSizeGiB = 32;
    isoDirectory = "/var/lib/libvirt/iso";

    windowsIsoFile = "Windows11.iso";
    virtioIsoFile = "virtio-win.iso";

    network.mode = "nat";
    rdp.defaultTarget = "192.168.122.10";

    profiles.rdp.enable = true;
    profiles.virtio.enable = false;
    profiles.vfio.enable = false;
  };

  # Enable deepcool display
  services.hardware.deepcool-digital-linux = {
    enable = true;
    extraArgs = [
      "--mode"
      "cpu_temp"
      "--update"
      "500"
      "--alarm"
    ];
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
  system.stateVersion = "25.05"; # Did you read the comment?
}
