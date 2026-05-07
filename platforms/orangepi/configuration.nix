{ pkgs
, lib
, config
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

  # Linux kernel with panthor GPU driver enabled for Mali-G610 (RK3588).
  # CONFIG_DRM_PANTHOR may not be explicitly set in nixpkgs common-config;
  # override here to ensure it is compiled as a module.
  boot.kernelPackages = pkgs.linuxPackagesFor (pkgs.linux.override {
    structuredExtraConfig = with lib.kernel; {
      DRM_PANTHOR = module;
    };
  });

  # Common storage/filesystem support for SBC scenarios.
  boot.supportedFilesystems = [
    "btrfs"
    "ext4"
    "f2fs"
    "vfat"
  ];

  # Add kernel modules needed during stage-1 (NVMe + device-mapper path).
  boot.initrd.availableKernelModules = [ "nvme" "nvme_core" "pci" "xhci_pci" "dm_mod" "btrfs" ];
  boot.initrd.kernelModules = [ "nvme" "dm_mod" "btrfs" ];

  # Common device support expected on RK3588-based boards.
  hardware.enableRedistributableFirmware = true;
  hardware.i2c.enable = true;

  environment.systemPackages = with pkgs; [
    i2c-tools
    lm_sensors
    usbutils
  ];

  # Keep full systemd userspace for normal udev tooling availability.
  systemd.package = lib.mkForce pkgs.systemd;

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

    ATTR{idVendor}=="0bda", ATTR{idProduct}=="1a2b", \
        RUN+="${pkgs.usb-modeswitch}/bin/usb_modeswitch -K -v 0bda -p 1a2b"
  '';

  # 4. 如果你的配置中启用了很多桌面/输入/蓝牙/pipewire 等包，可以临时禁用部分 hwdb 来源（可选）
  # services.udev.extraHwdb = lib.mkForce "# disabled to avoid build failure";

  services.greetd = {
    enable = true;
    useTextGreeter = true;
    settings = {
      default_session = {
        command = "${pkgs.tuigreet}/bin/tuigreet " +
          "--time --asterisks --remember --remember-session " +
          "--sessions ${config.services.displayManager.sessionData.desktops}/share/wayland-sessions";
      };
    };
  };
}
