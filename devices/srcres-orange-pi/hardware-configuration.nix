{ lib
, ...
}: {
  # Placeholder hardware profile for srcres-orange-pi.
  # Replace with a generated file from the target device:
  #   nixos-generate-config --root /mnt
  # and copy /mnt/etc/nixos/hardware-configuration.nix here.
  fileSystems."/" = lib.mkDefault {
    device = "/dev/disk/by-label/NIXOS_SD";
    fsType = "ext4";
  };
}
