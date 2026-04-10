{ pkgs
, lib
, ...
}: {
  # Orange Pi 5 (RK3588s) runs on aarch64 Linux.
  nixpkgs.hostPlatform = lib.mkDefault "aarch64-linux";

  # Typical bootloader path for ARM SBC images.
  # Orange Pi 5 with SPI-flashed U-Boot boots from /boot/extlinux/extlinux.conf.
  boot.loader = {
    grub.enable = false;
    timeout = 3;
    generic-extlinux-compatible = {
      enable = true;
      # Keep a few generations in extlinux menu for rollback while avoiding clutter.
      configurationLimit = 10;
    };
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

  # 为常见 USB 外设提供更完整的运行支持。
  hardware.usb-modeswitch.enable = true;

  services.pipewire = {
    enable = true;
    pulse.enable = true;
    alsa.enable = true;
    alsa.support32Bit = true;
  };

  security.rtkit.enable = true;

  # Orange Pi 上 man-cache 生成会显著拉长/卡住构建，关闭缓存生成以提升构建稳定性。
  documentation.man.generateCaches = false;

  # USB 无线网卡在 SBC 上常见，优先使用 iwd 并关闭省电避免断流/掉速。
  networking.networkmanager.wifi = {
    backend = "iwd";
    powersave = false;
  };

  # 兼容常见联发科 USB 设备模式切换。
  services.udev.extraRules = ''
    ACTION=="add", SUBSYSTEM=="usb", \
        ATTRS{idVendor}=="0e8d", ATTRS{idProduct}=="2870", \
        RUN+="${pkgs.usb-modeswitch}/bin/usb_modeswitch -v 0e8d -p 2870 -K -W"
  '';

  # 4. 如果你的配置中启用了很多桌面/输入/蓝牙/pipewire 等包，可以临时禁用部分 hwdb 来源（可选）
  # services.udev.extraHwdb = lib.mkForce "# disabled to avoid build failure";
}
