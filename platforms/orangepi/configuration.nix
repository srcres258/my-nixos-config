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

  # Use minimal systemd
  systemd.package = pkgs.systemdMinimal;
}
