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
    "vfat"
    "nls_cp437"
    "nls_iso8859_1"
    "xhci_pci"
    "mmc_block"
    "sd_mod"
    "usb_storage"
  ];
  boot.initrd.kernelModules = lib.mkForce [ "pcie_rockchip_host" "pci" "nvme_core" "nvme" "dm_mod" "btrfs" ];
  boot.initrd.systemd.enable = false;
  boot.initrd.postDeviceCommands = ''
    rootUuid="1aab64c8-3fe8-46f4-8aff-124f2ea7868d"
    swapUuid="b439618d-cd52-4bc9-8509-c327a3c026aa"
    bootUuid="3A12-AB1C"

    for _ in $(seq 1 90); do
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

      if command -v blkid >/dev/null 2>&1; then
        rootDev="$(blkid -U "$rootUuid" || true)"
        if [ -n "$rootDev" ]; then
          mkdir -p /dev/disk/by-uuid
          ln -sf "$rootDev" "/dev/disk/by-uuid/$rootUuid"
        fi

        swapDev="$(blkid -U "$swapUuid" || true)"
        if [ -n "$swapDev" ]; then
          mkdir -p /dev/disk/by-uuid
          ln -sf "$swapDev" "/dev/disk/by-uuid/$swapUuid"
        fi

        bootDev="$(blkid -U "$bootUuid" || true)"
        if [ -n "$bootDev" ]; then
          mkdir -p /dev/disk/by-uuid
          ln -sf "$bootDev" "/dev/disk/by-uuid/$bootUuid"
        fi
      fi

      if [ -e "/dev/disk/by-uuid/$rootUuid" ]; then
        break
      fi

      sleep 1
    done
  '';
  boot.kernelParams = lib.mkAfter [ "root=UUID=1aab64c8-3fe8-46f4-8aff-124f2ea7868d" "rootwait" "rootdelay=90" "rootfstype=btrfs" ];

  # The NVMe index can change across boots on RK3588. Prefer UUID-based root
  # lookup and recreate by-uuid symlinks in stage-1 if udev is late.
  fileSystems."/".device = lib.mkForce "/dev/disk/by-uuid/1aab64c8-3fe8-46f4-8aff-124f2ea7868d";
  fileSystems."/home".device = lib.mkForce "/dev/disk/by-uuid/1aab64c8-3fe8-46f4-8aff-124f2ea7868d";
  fileSystems."/nix".device = lib.mkForce "/dev/disk/by-uuid/1aab64c8-3fe8-46f4-8aff-124f2ea7868d";
  fileSystems."/boot".device = lib.mkForce "/dev/disk/by-uuid/3A12-AB1C";
  swapDevices = lib.mkForce [ { device = "/dev/disk/by-uuid/b439618d-cd52-4bc9-8509-c327a3c026aa"; } ];

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
