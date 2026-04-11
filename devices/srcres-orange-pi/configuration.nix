{ lib, ... }: {
  imports = [
    ./hardware-configuration.nix
  ];

  # Ensure NVMe root-on-SSD is discoverable in stage-1 initrd on RK3588.
  # Keep PCIe/NVMe modules force-loaded early and give slow-link bring-up more time.
  boot.initrd.availableKernelModules = lib.mkAfter [
    "pci"
    "pcie_rockchip_host"
    "nvme_core"
    "nvme"
    "mmc_block"
    "sd_mod"
  ];
  boot.initrd.kernelModules = lib.mkAfter [ "pcie_rockchip_host" "nvme_core" "nvme" "pci" ];
  boot.initrd.systemd.enable = false;
  boot.initrd.postDeviceCommands = ''
    for _ in 1 2 3; do
      if [ -e /sys/bus/pci/rescan ]; then
        echo 1 > /sys/bus/pci/rescan
      fi
      if command -v udevadm >/dev/null 2>&1; then
        udevadm settle --timeout=30 || true
      fi
      sleep 1
    done
  '';
  boot.kernelParams = lib.mkAfter [ "root=/dev/nvme0n1p3" "rootwait" "rootfstype=btrfs" ];

  # Stage-1 was repeatedly timing out on /dev/disk/by-label and /dev/disk/by-uuid.
  # On this board we mount by direct NVMe partition nodes to bypass udev symlink races
  # during early boot.
  fileSystems."/".device = lib.mkForce "/dev/nvme0n1p3";
  fileSystems."/home".device = lib.mkForce "/dev/nvme0n1p3";
  fileSystems."/nix".device = lib.mkForce "/dev/nvme0n1p3";
  fileSystems."/boot".device = lib.mkForce "/dev/nvme0n1p1";
  swapDevices = lib.mkForce [ { device = "/dev/nvme0n1p2"; } ];

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
