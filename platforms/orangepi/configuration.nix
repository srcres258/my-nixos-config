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

  # 强制使用完整 systemd（避免 Minimal 版本缺少 systemd-hwdb）
  # 如果你的 flake 里用了 systemdMinimal，这里强制覆盖
  systemd.package = pkgs.systemd;   # 而不是 systemdMinimal

  # 如果上面还不行，添加这个 overlay 来确保 hwdb 构建使用正确的工具
  nixpkgs.overlays = lib.mkBefore [
    (final: prev: {
      # 强制 hwdb 使用完整 systemd 的工具链
      systemd = prev.systemd.override {
        withHwdb = false;   # 尝试在包级别禁用（部分版本有效）
      };
    })
  ];

  # 额外保险：提供一个空的 hwdb.bin（防止 etc 模块失败）
  environment.etc."udev/hwdb.bin".source = pkgs.writeText "empty-hwdb.bin" "";

  # 可选：如果你有很多输入/硬件设备相关包，可以临时禁用部分 hwdb 来源
  services.udev.extraHwdb = lib.mkDefault "";
}
