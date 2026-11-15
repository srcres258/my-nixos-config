# Minimal NixOS configuration for a Raspberry Pi 4 Model B.
#
# Unlike every other host in this repository, srcres-rpi does not load the
# shared ./configuration.nix base: that base carries a full desktop stack
# (niri, flatpak, large package/font sets) which this board does not need.
# Everything required to boot and administer the machine lives here.
{ lib
, pkgs
, inputs
, ...
}: {
  imports = [
    # nixpkgs' aarch64 SD-image builder: creates the FAT /boot/firmware
    # partition plus the ext4 root layout that the U-Boot chainload below
    # expects. Build with:
    #   nix build .#nixosConfigurations.srcres-rpi.config.system.build.sdImage
    "${inputs.nixpkgs}/nixos/modules/installer/sd-card/sd-image-aarch64.nix"
  ];

  # The Raspberry Pi GPU firmware cannot read extlinux.conf, so stage the
  # firmware partition and chainload U-Boot, which then boots the NixOS
  # generations listed in extlinux.conf.
  hardware.raspberry-pi.firmware = {
    # Repopulate /boot/firmware on every switch so kernel/firmware updates
    # actually reach the SD card.
    enable = true;
    uboot.enable = true;
  };

  # sd-image-aarch64.nix mounts the firmware partition with `noauto`, so it is
  # never mounted at boot and the firmware activation script above would skip
  # itself every time. Mount it (still `nofail`, so a bad card cannot block
  # boot) and stop tracking access times on the FAT partition too.
  fileSystems."/boot/firmware".options = lib.mkForce [ "nofail" "noatime" ];

  hardware.enableRedistributableFirmware = true;

  # NixOS enables zfs by default, which would build a zfs kernel module against
  # the vendor kernel for no benefit here: root is ext4 and /boot/firmware is
  # vfat.
  boot.supportedFilesystems.zfs = lib.mkForce false;

  # The nixos-hardware raspberry-pi-4 profile selects a vendor `linux-rpi`
  # kernel built from source, so it is generally not in a binary cache.
  # Uncomment the next line to fall back to the mainline kernel instead.
  # boot.kernelPackages = pkgs.linuxPackages_latest;

  # --------------------------------------------------------------------------
  # SD card write reduction
  #
  # The system disk is the TF card, so everything below either keeps writes in
  # RAM or batches them. Nothing here makes the root filesystem volatile:
  # /nix, /home, /etc, /var/lib and friends stay on the ext4 partition and
  # survive reboots. See AGENTS.md before adding a tmpfs root / impermanence.
  # --------------------------------------------------------------------------

  # Stop updating access times on every read of the root filesystem.
  # List options are merged, so the sd-image device/fsType stay intact.
  fileSystems."/".options = [ "noatime" ];

  # /tmp lives in RAM. tmpfsSize is an upper bound, not a reservation, so an
  # idle system does not lose 2 GiB of the 8 GiB to it.
  boot.tmp = {
    useTmpfs = true;
    tmpfsSize = "25%";
  };

  # Keep the journal in /run (tmpfs) instead of /var/log so log traffic never
  # reaches the card. Trade-off: logs from before a reboot are gone, which also
  # means a crash that needs post-mortem debugging leaves no trace. Drop the
  # `storage` line (journald then defaults to `auto`) if that matters more than
  # card wear.
  services.journald = {
    storage = "volatile";
    extraConfig = ''
      RuntimeMaxUse=64M
      RuntimeMaxFileSize=8M
    '';
  };

  # No on-disk swap; compress spare pages into a zram device instead. 25% of
  # 8 GiB is the logical swap size, again not a reservation. lz4 keeps the
  # CPU cost low on the Pi 4; the zstd default compresses better.
  swapDevices = [ ];
  zramSwap = {
    enable = true;
    memoryPercent = 25;
    algorithm = "lz4";
  };

  # Core dumps would be one-off large writes to the card.
  systemd.coredump.enable = false;

  # The extlinux builder copies every generation's kernel and initrd into
  # /boot/nixos on the root filesystem. Keep 5 generations instead of the
  # default 20 so stale copies do not pile up on the card (rollback still works
  # within those 5).
  boot.loader.generic-extlinux-compatible.configurationLimit = 5;

  # Batch dirty-page writeback instead of flushing every 5s/30s. This trades
  # up to ~2 minutes of unflushed data on a power cut for far fewer small
  # writes. Both values are centiseconds.
  boot.kernel.sysctl = {
    "vm.dirty_writeback_centisecs" = 6000;
    "vm.dirty_expire_centisecs" = 12000;
  };

  networking = {
    hostName = "srcres-rpi";
    networkmanager.enable = true;
    firewall.enable = true;
  };

  services.openssh = {
    enable = true;
    settings.PasswordAuthentication = true;
    openFirewall = true;
  };

  users.users.srcres = {
    # See ./configuration.nix: the hash is read at activation time so the
    # closure stays reproducible. On a freshly flashed card there is no file
    # yet, so log in on the serial console / attached keyboard and run
    # `passwd` once, or drop the file into /var/lib/nixos/secrets first.
    hashedPasswordFile = "/var/lib/nixos/secrets/srcres.passwd";
    isNormalUser = true;
    description = "src_resources";
    extraGroups = [
      "wheel"
      "networkmanager"
    ];
    shell = pkgs.fish;
  };

  programs.fish.enable = true;

  environment.systemPackages = with pkgs; [
    # Editors and shell basics.
    vim
    git
    wget
    tmux
    tree

    # Diagnostics and archives.
    file
    unzip
    htop
    pciutils
    usbutils
    lm_sensors

    home-manager
  ];

  # Set your time zone.
  time.timeZone = "Asia/Shanghai";

  # Select internationalisation properties.
  i18n.defaultLocale = "en_US.UTF-8";

  # Remove nix-channel related tools & configs, we use flakes instead.
  nix.channel.enable = false;

  nix.settings = {
    experimental-features = [ "nix-command" "flakes" ];
    trusted-users = [
      "root"
      "srcres"
    ];
    substituters = [
      "https://mirrors.tuna.tsinghua.edu.cn/nix-channels/store"
      "https://mirrors.ustc.edu.cn/nix-channels/store"
    ];
    # Cachix: yazi, nur-packages-srcres258, and the CI-built aarch64 cache.
    # Drop the last entry from both lists if the cache is ever deleted.
    extra-substituters = [
      "https://yazi.cachix.org"
      "https://nur-packages-srcres258.cachix.org"
      "https://srcres-nixos-config.cachix.org"
    ];
    extra-trusted-public-keys = [
      "yazi.cachix.org-1:Dcdz63NZKfvUCbDGngQDAZq6kOroIrFoyO064uvLh8k="
      "nur-packages-srcres258.cachix.org-1:3Nn/bNoV5HnI1RoN5uOtkHrPq078veIhjJZmF0FUGP0="
      "srcres-nixos-config.cachix.org-1:BOlbM7cuGZ1trhfpJ3Yhtr1jHff1hIkM8NUhvqK/ISg="
    ];
  };

  # This option defines the first version of NixOS installed on this host.
  system.stateVersion = "26.05";
}
