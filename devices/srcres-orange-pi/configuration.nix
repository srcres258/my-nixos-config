{ lib, ... }: {
  imports = [
    ./hardware-configuration.nix
  ];

  # Ensure NVMe root-on-SSD is discoverable in stage-1 initrd on RK3588.
  # Force deterministic module inclusion/load order and add active reprobe loop
  # because the PCIe/NVMe link can come up late on this board.
  boot.initrd.availableKernelModules = lib.mkForce [
    "pcie_rockchip_host"
    "pci"
    "nvme_core"
    "nvme"
    "dm_mod"
    "btrfs"
    "xhci_pci"
    "mmc_block"
    "sd_mod"
  ];
  boot.initrd.kernelModules = lib.mkForce [ "pcie_rockchip_host" "pci" "nvme_core" "nvme" "dm_mod" "btrfs" ];
  boot.initrd.systemd.enable = false;
  boot.initrd.postDeviceCommands = ''
    for _ in $(seq 1 60); do
      if [ -e /sys/bus/pci/rescan ]; then
        echo 1 > /sys/bus/pci/rescan
      fi

      modprobe pcie_rockchip_host >/dev/null 2>&1 || true
      modprobe pci >/dev/null 2>&1 || true
      modprobe nvme_core >/dev/null 2>&1 || true
      modprobe nvme >/dev/null 2>&1 || true
      modprobe dm_mod >/dev/null 2>&1 || true
      modprobe btrfs >/dev/null 2>&1 || true

      if command -v udevadm >/dev/null 2>&1; then
        udevadm trigger --subsystem-match=pci --action=add || true
        udevadm trigger --subsystem-match=block --action=add || true
        udevadm settle --timeout=3 || true
      fi

      if [ -b /dev/nvme0n1p3 ]; then
        break
      fi

      sleep 1
    done
  '';
  boot.kernelParams = lib.mkAfter [ "root=/dev/nvme0n1p3" "rootwait" "rootdelay=60" "rootfstype=btrfs" ];

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
