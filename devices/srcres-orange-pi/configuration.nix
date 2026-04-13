{ lib, ... }: {
  imports = [
    ./hardware-configuration.nix
  ];

  # Ensure NVMe root-on-SSD is discoverable in stage-1 initrd on RK3588.
  # Force deterministic module inclusion/load order and add active reprobe loop
  # because the PCIe/NVMe link can come up late on this board.
  boot.initrd.availableKernelModules = lib.mkForce [
    # PCIe controller + combo PHY required to bring the NVMe link up on RK3588S.
    "pcie_rockchip_host"
    "phy_rockchip_naneng_combphy"
    "pci"
    "nvme_core"
    "nvme"
    # crc32c hash is required by btrfs for data checksum and is a loadable
    # module on this kernel; without it mount fails with ENOENT.
    "crc32c_cryptoapi"
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
  # Keep default initrd modules enabled to avoid missing core block/udev helpers
  # during early boot discovery on RK3588.
  boot.initrd.includeDefaultModules = lib.mkForce true;
  boot.initrd.kernelModules = lib.mkForce [ "phy_rockchip_naneng_combphy" "pcie_rockchip_host" "pci" "nvme_core" "nvme" "crc32c_cryptoapi" "dm_mod" "btrfs" ];
  boot.kernelModules = [ "pcie_rockchip_host" "nvme" "nvme_core" ];
  boot.initrd.postDeviceCommands = ''
    rootUuid="1aab64c8-3fe8-46f4-8aff-124f2ea7868d"

    for _ in $(seq 1 45); do
      if [ -e /sys/bus/pci/rescan ]; then
        echo 1 > /sys/bus/pci/rescan
      fi

      modprobe phy_rockchip_naneng_combphy >/dev/null 2>&1 || true
      modprobe pcie_rockchip_host >/dev/null 2>&1 || true
      modprobe pci >/dev/null 2>&1 || true
      modprobe nvme_core >/dev/null 2>&1 || true
      modprobe nvme >/dev/null 2>&1 || true
      modprobe dm_mod >/dev/null 2>&1 || true
      modprobe btrfs >/dev/null 2>&1 || true
      modprobe mmc_block >/dev/null 2>&1 || true
      modprobe sd_mod >/dev/null 2>&1 || true
      modprobe usb_storage >/dev/null 2>&1 || true

      if command -v udevadm >/dev/null 2>&1; then
        udevadm trigger --subsystem-match=pci --action=add || true
        udevadm trigger --subsystem-match=nvme --action=add || true
        udevadm trigger --subsystem-match=block --action=add || true
        udevadm settle --timeout=3 || true
      fi

      # Ensure by-uuid links are materialized from current udev state first.
      mkdir -p /dev/disk/by-uuid
      if [ -d /run/udev/data ] && command -v sed >/dev/null 2>&1; then
        for meta in /run/udev/data/b*; do
          [ -f "$meta" ] || continue
          devname="$(sed -n 's/^N://p' "$meta" | head -n 1)"
          uuid="$(sed -n 's/^E:ID_FS_UUID=//p' "$meta" | head -n 1)"
          if [ -n "$devname" ] && [ -n "$uuid" ] && [ -b "/dev/$devname" ]; then
            ln -sf "/dev/$devname" "/dev/disk/by-uuid/$uuid"
          fi
        done
      fi

      # Fallback probe with blkid if udev metadata is incomplete.
      if command -v blkid >/dev/null 2>&1; then
        for dev in /dev/nvme*n* /dev/mmcblk*p* /dev/sd*; do
          if [ -b "$dev" ]; then
            uuid="$(blkid -s UUID -o value "$dev" 2>/dev/null || true)"
            if [ -n "$uuid" ]; then
              ln -sf "$dev" "/dev/disk/by-uuid/$uuid"
            fi
          fi
        done
      fi

      if [ -e "/dev/disk/by-uuid/$rootUuid" ]; then
        break
      fi

      sleep 1
    done

    if [ ! -e "/dev/disk/by-uuid/$rootUuid" ]; then
      echo "[initrd] root UUID still missing: $rootUuid"
    fi
  '';
  boot.kernelParams = lib.mkAfter [
    "root=UUID=1aab64c8-3fe8-46f4-8aff-124f2ea7868d"
    "rootwait"
    "rootdelay=60"
    "rootfstype=btrfs"
    "console=tty0"
    "console=ttyS2,1500000"
    "earlycon"
  ];

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
