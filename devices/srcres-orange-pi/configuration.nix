{ lib, pkgs, config, ... }:
let
  aic8800d80Src = pkgs.fetchFromGitHub {
    owner = "shenmintao";
    repo = "aic8800d80";
    rev = "05710dff05dabce66ab3ee80f40484892c512b3c";
    hash = "sha256-QVpuJrCssBf4fwycq7oN0Oi9OxpQUqrSTQuHk5UE9+U=";
  };

  aic8800d80 = config.boot.kernelPackages.callPackage (
    { stdenv, kernel }:
    stdenv.mkDerivation {
      pname = "aic8800d80";
      version = "unstable-2026-04-13";
      src = aic8800d80Src;

      nativeBuildInputs = kernel.moduleBuildDependencies;

      buildPhase = ''
        runHook preBuild
        make -C drivers/aic8800 \
          KVER=${kernel.modDirVersion} \
          KDIR=${kernel.dev}/lib/modules/${kernel.modDirVersion}/build
        runHook postBuild
      '';

      installPhase = ''
        runHook preInstall
        modDir=$out/lib/modules/${kernel.modDirVersion}/kernel/drivers/net/wireless/aic8800
        mkdir -p "$modDir"
        install -m 644 drivers/aic8800/aic_load_fw/aic_load_fw.ko "$modDir"/
        install -m 644 drivers/aic8800/aic8800_fdrv/aic8800_fdrv.ko "$modDir"/
        runHook postInstall
      '';
    }
  ) { };

  aic8800d80Firmware = pkgs.stdenvNoCC.mkDerivation {
    pname = "aic8800d80-firmware";
    version = "unstable-2026-04-13";
    src = aic8800d80Src;

    installPhase = ''
      runHook preInstall
      mkdir -p $out/lib/firmware
      cp -r fw/* $out/lib/firmware/

      # Some AIC8800 USB variants probe as "AIC8800DC" while others use
      # "AIC8800D80" firmware layout. Provide compatibility links so both
      # probe paths resolve at runtime.
      if [ -d $out/lib/firmware/aic8800D80 ] && [ ! -e $out/lib/firmware/aic8800DC ]; then
        ln -s aic8800D80 $out/lib/firmware/aic8800DC
      fi
      if [ -d $out/lib/firmware/aic8800DC ] && [ ! -e $out/lib/firmware/aic8800D80 ]; then
        ln -s aic8800DC $out/lib/firmware/aic8800D80
      fi

      if [ -e $out/lib/firmware/aic8800D80/fmacfw_patch_8800dc_u02.bin ] && [ ! -e $out/lib/firmware/aic8800DC/fmacfw_patch_8800dc_u02.bin ]; then
        mkdir -p $out/lib/firmware/aic8800DC
        ln -s ../aic8800D80/fmacfw_patch_8800dc_u02.bin $out/lib/firmware/aic8800DC/fmacfw_patch_8800dc_u02.bin
      fi

      mkdir -p $out/lib/udev/rules.d
      cat > $out/lib/udev/rules.d/99-aic8800d80-mode-switch.rules <<'EOF'
      ACTION=="add", SUBSYSTEM=="block", ENV{DEVTYPE}=="disk", KERNEL=="sd*", ATTRS{idVendor}=="a69c", ATTRS{idProduct}=="5721", RUN+="${pkgs.util-linux}/bin/eject /dev/%k"
      ACTION=="add", SUBSYSTEM=="block", ENV{DEVTYPE}=="disk", KERNEL=="sd*", ATTRS{idVendor}=="a69c", ATTRS{idProduct}=="5723", RUN+="${pkgs.util-linux}/bin/eject /dev/%k"
      ACTION=="add", SUBSYSTEM=="block", ENV{DEVTYPE}=="disk", KERNEL=="sd*", ATTRS{idVendor}=="a69c", ATTRS{idProduct}=="5724", RUN+="${pkgs.util-linux}/bin/eject /dev/%k"
      ACTION=="add", SUBSYSTEM=="block", ENV{DEVTYPE}=="disk", KERNEL=="sd*", ATTRS{idVendor}=="a69c", ATTRS{idProduct}=="5725", RUN+="${pkgs.util-linux}/bin/eject /dev/%k"
      ACTION=="add", SUBSYSTEM=="block", ENV{DEVTYPE}=="disk", KERNEL=="sd*", ATTRS{idVendor}=="a69c", ATTRS{idProduct}=="5726", RUN+="${pkgs.util-linux}/bin/eject /dev/%k"
      ACTION=="add", SUBSYSTEM=="block", ENV{DEVTYPE}=="disk", KERNEL=="sd*", ATTRS{idVendor}=="a69c", ATTRS{idProduct}=="5727", RUN+="${pkgs.util-linux}/bin/eject /dev/%k"
      ACTION=="add", SUBSYSTEM=="block", ENV{DEVTYPE}=="disk", KERNEL=="sd*", ATTRS{idVendor}=="a69c", ATTRS{idProduct}=="572a", RUN+="${pkgs.util-linux}/bin/eject /dev/%k"
      ACTION=="add", SUBSYSTEM=="block", ENV{DEVTYPE}=="disk", KERNEL=="sd*", ATTRS{idVendor}=="a69c", ATTRS{idProduct}=="572c", RUN+="${pkgs.util-linux}/bin/eject /dev/%k"
      EOF
      runHook postInstall
    '';
  };
in
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
  boot.initrd.kernelModules = lib.mkForce [ "phy_rockchip_naneng_combphy" "pcie_rockchip_host" "pci" "nvme_core" "nvme" "crc32c_cryptoapi" "dm_mod" "btrfs" ];
  boot.kernelModules = [
    "pcie_rockchip_host"
    "nvme"
    "nvme_core"
    "tun"
    "aic_load_fw"
    "aic8800_fdrv"
  ];
  # AICSemi driver reads firmware via aic_load_fw module parameter aic_fw_path.
  # On NixOS firmware lives under /run/current-system/firmware.
  boot.extraModprobeConfig = ''
    options aic_load_fw aic_fw_path=/run/current-system/firmware
  '';
  boot.extraModulePackages = [ aic8800d80 ];
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
    "earlycon"
  ];

  # The NVMe index can change across boots on RK3588. Prefer UUID-based root
  # lookup and recreate by-uuid symlinks in stage-1 if udev is late.
  fileSystems."/".device = lib.mkForce "/dev/disk/by-uuid/1aab64c8-3fe8-46f4-8aff-124f2ea7868d";
  fileSystems."/home".device = lib.mkForce "/dev/disk/by-uuid/1aab64c8-3fe8-46f4-8aff-124f2ea7868d";
  fileSystems."/nix".device = lib.mkForce "/dev/disk/by-uuid/1aab64c8-3fe8-46f4-8aff-124f2ea7868d";
  fileSystems."/boot".device = lib.mkForce "/dev/disk/by-uuid/3A12-AB1C";
  swapDevices = lib.mkForce [{ device = "/dev/disk/by-uuid/b439618d-cd52-4bc9-8509-c327a3c026aa"; }];

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

  # AIC8800D80 USB Wi-Fi driver (aic8800_fdrv + aic_load_fw) and firmware.
  # This out-of-tree driver requests raw .bin/.txt filenames via request_firmware
  # and does not resolve NixOS-compressed .zst firmware paths.
  hardware.firmwareCompression = "none";
  hardware.firmware = [ aic8800d80Firmware ];
  services.udev.packages = [ aic8800d80Firmware ];
  
  # This option defines the first version of NixOS installed on this host.
  system.stateVersion = "25.11";
}
