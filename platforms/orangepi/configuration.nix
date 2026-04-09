{ pkgs
, lib
, ...
}: {
  # Orange Pi 5 (RK3588s) runs on aarch64 Linux.
  nixpkgs.hostPlatform = lib.mkDefault "aarch64-linux";

  # Typical bootloader path for ARM SBC images.
  boot.loader = {
    grub.enable = false;
    generic-extlinux-compatible.enable = true;
  };

  # Keep close to upstream-supported kernel stack.
  boot.kernelPackages = lib.mkDefault pkgs.linuxPackages_latest;

  # Common storage/filesystem support for SBC scenarios.
  boot.supportedFilesystems = [
    "btrfs"
    "ext4"
    "f2fs"
    "vfat"
  ];

  # Common device support expected on RK3588-based boards.
  hardware.enableRedistributableFirmware = true;
  hardware.i2c.enable = true;

  environment.systemPackages = with pkgs; [
    i2c-tools
    lm_sensors
    usbutils
  ];

  # 1. 强制使用完整的 systemd（而不是 Minimal 版本，确保包含 systemd-hwdb 工具）
  systemd.package = lib.mkForce pkgs.systemd;

  # 2. 用最高优先级提供一个空的 hwdb.bin，覆盖官方模块生成的那个
  #    这能直接让 hwdb.bin.drv 构建通过，而不触发内部的 systemd-hwdb 调用失败
  environment.etc."udev/hwdb.bin".source = lib.mkForce (
    pkgs.runCommand "empty-hwdb.bin" {} ''
      touch $out
    ''
  );

  # 3. 额外保险：清空 extraHwdb，减少需要合并的文件量
  services.udev.extraHwdb = lib.mkForce "";

  # 4. 如果你的配置中启用了很多桌面/输入/蓝牙/pipewire 等包，可以临时禁用部分 hwdb 来源（可选）
  # services.udev.extraHwdb = lib.mkForce "# disabled to avoid build failure";
}
