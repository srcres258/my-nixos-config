{ lib, pkgs, config, ... }:

{
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
  boot.initrd.kernelModules = lib.mkForce [ "phy_rockchip_naneng_combphy" "pcie_rockchip_host" "pci" "nvme_core" "nvme" "crc32c_cryptoapi" "dm_mod" "btrfs" "panthor" ];
  boot.kernelModules = [
    "pcie_rockchip_host"
    "nvme"
    "nvme_core"
    "tun"
    "panthor"
  ];
  boot.initrd.systemd.extraBin = {
    blkid = "${pkgs.util-linux}/bin/blkid";
  };

  boot.initrd.systemd.services.nvme-rescan = {
    description = "Rescan PCIe bus and wait for NVMe root device";
    wantedBy = [ "initrd-root-device.target" ];
    before = [
      "initrd-root-device.target"
      "shutdown.target"
    ];
    after = [
      "systemd-modules-load.service"
      "systemd-udev-trigger.service"
    ];
    unitConfig = {
      DefaultDependencies = false;
    };
    serviceConfig = {
      Type = "oneshot";
      RemainAfterExit = true;
    };
    script = ''
      rootUuid="${
        lib.removePrefix "/dev/disk/by-uuid/" config.fileSystems."/".device
      }"

      for _ in $(seq 1 45); do
        if [ -e /sys/bus/pci/rescan ]; then
          echo 1 > /sys/bus/pci/rescan
        fi

        udevadm trigger --subsystem-match=pci --action=add || true
        udevadm trigger --subsystem-match=nvme --action=add || true
        udevadm trigger --subsystem-match=block --action=add || true
        udevadm settle --timeout=3 || true

        if [ -e "/dev/disk/by-uuid/$rootUuid" ]; then
          break
        fi

        # Fallback: recreate by-uuid symlinks from blkid if udev metadata is incomplete.
        for dev in /dev/nvme*n* /dev/mmcblk*p* /dev/sd*; do
          if [ -b "$dev" ]; then
            uuid="$(blkid -s UUID -o value "$dev" 2>/dev/null || true)"
            if [ "$uuid" = "$rootUuid" ]; then
              mkdir -p /dev/disk/by-uuid
              ln -sf "$dev" "/dev/disk/by-uuid/$uuid"
              break 2
            fi
          fi
        done

        sleep 1
      done

      if [ ! -e "/dev/disk/by-uuid/$rootUuid" ]; then
        echo "[initrd] root UUID still missing: $rootUuid"
      fi
    '';
  };

  # The systemd initrd bind-mounts /run → /sysroot/run, but the
  # bind mount target must exist. On a fresh BTRFS root subvolume
  # /sysroot/run may be absent, causing the mount to fail.
  #
  # Create /sysroot/run before the bind mount using /bin/mkdir
  # (coreutils is in initrdBin so /bin/mkdir is always available).
  # The Nix store path (${pkgs.coreutils}/bin/mkdir) is avoided
  # because cross-evaluation (x86_64 → aarch64) may resolve it
  # differently than what's actually in the initrd.
  boot.initrd.systemd.services.ensure-sysroot-run = {
    description = "Ensure /sysroot/run exists before bind mount";
    wantedBy = [ "sysroot-run.mount" ];
    before = [ "sysroot-run.mount" ];
    after = [ "sysroot.mount" ];
    unitConfig = {
      DefaultDependencies = false;
      RequiresMountsFor = "/sysroot";
    };
    serviceConfig = {
      Type = "oneshot";
      RemainAfterExit = true;
      ExecStart = "/bin/mkdir -p /sysroot/run";
    };
  };

  boot.kernelParams = lib.mkAfter [
    "root=UUID=${
      lib.removePrefix "/dev/disk/by-uuid/" config.fileSystems."/".device
    }"
    "rootwait"
    "rootdelay=60"
    "rootfstype=btrfs"
    "earlycon"
  ];

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
    };
    openFirewall = true;
  };

  # Keep ARM-specific graphics path explicit and minimal.
  hardware.graphics.enable = true;

  # This option defines the first version of NixOS installed on this host.
  system.stateVersion = "25.11";
}
