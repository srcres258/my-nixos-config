{ lib, ... }: {
  imports = [
    ./hardware-configuration.nix
  ];

  # Ensure NVMe root-on-SSD is discoverable in stage-1 initrd on RK3588.
  # hardware-configuration.nix may contain a minimal module list from scan time,
  # so we append required PCI/NVMe modules here at host level.
  boot.initrd.availableKernelModules = lib.mkAfter [
    "pci"
    "pcie_rockchip_host"
    "nvme_core"
    "nvme"
  ];
  boot.initrd.kernelModules = lib.mkAfter [ "pcie_rockchip_host" "nvme_core" "nvme" ];
  boot.kernelParams = lib.mkAfter [ "rootwait" ];

  networking = {
    hostName = "srcres-orange-pi";

    # Keep device behavior consistent with other hosts in this repository.
    networkmanager.enable = true;
    nftables.enable = true;
    firewall.enable = false;
  };

  # Orange Pi 5 normally runs headless for infra/dev workloads.
  services.openssh = {
    enable = true;
    settings = {
      PasswordAuthentication = true;
      PermitRootLogin = "yes";
      X11Forwarding = true;
    };
    openFirewall = true;
  };

  # Keep ARM-specific graphics path explicit and minimal.
  hardware.graphics.enable = true;

  # This option defines the first version of NixOS installed on this host.
  system.stateVersion = "25.11";
}
