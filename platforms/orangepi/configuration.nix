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

  # 1. 彻底禁用 hwdb 生成（这是目前最推荐的方式）
  systemd.hwdb.enable = lib.mkForce false;

  # 2. 强制使用完整的 systemd（避免 Minimal 版本缺少 systemd-hwdb 工具）
  systemd.package = lib.mkForce pkgs.systemd;

  # 3. 用高优先级强制覆盖 hwdb.bin 为一个空文件（解决冲突）
  environment.etc."udev/hwdb.bin".source = lib.mkForce (pkgs.writeText "empty-hwdb.bin" "");

  # 可选：额外保险，防止 udev 模块继续尝试生成
  services.udev.extraHwdb = lib.mkForce "";
}
