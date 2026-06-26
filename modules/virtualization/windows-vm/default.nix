{ config
, lib
, pkgs
, ...
}:
let
  cfg = config.my.virtualization.windowsVm;
  diskDir = lib.removeSuffix "/${lib.baseNameOf cfg.diskPath}" cfg.diskPath;
  templates = import ./templates.nix { inherit lib; };

  windowsIsoPath = "${cfg.isoDirectory}/${cfg.windowsIsoFile}";
  virtioIsoPath = "${cfg.isoDirectory}/${cfg.virtioIsoFile}";

  mkProfileArtifacts =
    { name
    , enabled
    , baseGraphicsXml
    , baseVideoXml
    , baseExtraDevicesXml ? ""
    , installVideoXml ? templates.mkVideoXml "rdp"
    , installExtraDevicesXml ? ""
    }:
    let
      baseDomain = "${cfg.vmNamePrefix}-${name}";
      installDomain = "${baseDomain}-install";

      nvramPath = "${cfg.storage.nvramDir}/${baseDomain}.fd";
      tpmStateDir = "${cfg.storage.swtpmDir}/${baseDomain}";
      guestAgentPath = "${cfg.storage.channelDir}/${baseDomain}.org.qemu.guest_agent.0";

      baseXml = pkgs.writeText "${baseDomain}.xml" (
        templates.mkDomainXml {
          name = baseDomain;
          memoryMiB = cfg.memoryMiB;
          vcpus = cfg.vcpus;
          diskPath = cfg.diskPath;
          networkMode = cfg.network.mode;
          bridgeName = cfg.network.bridgeName;
          graphicsXml = baseGraphicsXml;
          videoXml = baseVideoXml;
          tpmStateDir = tpmStateDir;
          nvramPath = nvramPath;
          guestAgentChannelPath = guestAgentPath;
          extraDevicesXml = baseExtraDevicesXml;
        }
      );

      installMediaXml = lib.concatStringsSep "\n" [
        (templates.mkCdromXml {
          path = windowsIsoPath;
          targetDev = "sda";
          bootOrder = 1;
        })
        (templates.mkCdromXml {
          path = virtioIsoPath;
          targetDev = "sdb";
          bootOrder = 2;
        })
      ];

      installMediaXmlTemplate = lib.concatStringsSep "\n" [
        (templates.mkCdromXml {
          path = "__WINDOWS_ISO__";
          targetDev = "sda";
          bootOrder = 1;
        })
        (templates.mkCdromXml {
          path = "__VIRTIO_ISO__";
          targetDev = "sdb";
          bootOrder = 2;
        })
      ];

      installXml = pkgs.writeText "${installDomain}.xml" (
        templates.mkDomainXml {
          name = installDomain;
          memoryMiB = cfg.memoryMiB;
          vcpus = cfg.vcpus;
          diskPath = cfg.diskPath;
          networkMode = cfg.network.mode;
          bridgeName = cfg.network.bridgeName;
          graphicsXml = templates.mkSpiceGraphicsXml cfg.spice.port;
          videoXml = installVideoXml;
          tpmStateDir = tpmStateDir;
          nvramPath = nvramPath;
          guestAgentChannelPath = guestAgentPath;
          installMediaXml = installMediaXml;
          extraDevicesXml = installExtraDevicesXml;
          bootFromCdrom = true;
        }
      );

      installXmlTemplate = pkgs.writeText "${installDomain}.template.xml" (
        templates.mkDomainXml {
          name = installDomain;
          memoryMiB = cfg.memoryMiB;
          vcpus = cfg.vcpus;
          diskPath = cfg.diskPath;
          networkMode = cfg.network.mode;
          bridgeName = cfg.network.bridgeName;
          graphicsXml = templates.mkSpiceGraphicsXml cfg.spice.port;
          videoXml = installVideoXml;
          tpmStateDir = tpmStateDir;
          nvramPath = nvramPath;
          guestAgentChannelPath = guestAgentPath;
          installMediaXml = installMediaXmlTemplate;
          extraDevicesXml = installExtraDevicesXml;
          bootFromCdrom = true;
        }
      );
    in
    {
      inherit enabled baseDomain installDomain baseXml installXml installXmlTemplate;
    };

  profileArtifacts = {
    rdp = mkProfileArtifacts {
      name = "rdp";
      enabled = cfg.profiles.rdp.enable;
      baseGraphicsXml = templates.mkSpiceGraphicsXml cfg.spice.port;
      baseVideoXml = templates.mkVideoXml "rdp";
    };

    # The virtio profile keeps the installer path simple (QXL + SPICE) but
    # switches the normal boot to virtio-gpu so the remote-graphics chain can
    # be tested without GPU passthrough.
    virtio = mkProfileArtifacts {
      name = "virtio";
      enabled = cfg.profiles.virtio.enable;
      baseGraphicsXml = templates.mkSpiceGraphicsXml cfg.spice.port;
      baseVideoXml = templates.mkVideoXml "virtio";
    };

    # The vfio profile is intentionally strict: normal boot has no emulated
    # graphics so the physical GPU is the primary display path.
    # The install XML keeps a SPICE fallback so the first Windows install can
    # still be completed from the terminal.
    vfio = mkProfileArtifacts {
      name = "vfio";
      enabled = cfg.profiles.vfio.enable;
      baseGraphicsXml = "";
      baseVideoXml = "";
      baseExtraDevicesXml = lib.concatStringsSep "\n" (lib.filter (x: x != "") [
        (lib.optionalString (cfg.vfio.gpuPciAddress != null) (templates.mkHostdevXml cfg.vfio.gpuPciAddress))
        (lib.optionalString (cfg.vfio.audioPciAddress != null) (templates.mkHostdevXml cfg.vfio.audioPciAddress))
      ]);
    };
  };

  vmctlConfigFile = pkgs.writeText "windows-vm-vmctl.conf" ''
    WINDOWS_VM_STORAGE_ROOT=${lib.strings.escapeShellArg cfg.storage.rootDir}
    WINDOWS_VM_DISK_PATH=${lib.strings.escapeShellArg cfg.diskPath}
    WINDOWS_VM_DISK_SIZE_GIB=${toString cfg.diskSizeGiB}
    WINDOWS_VM_ISO_DIRECTORY=${lib.strings.escapeShellArg cfg.isoDirectory}
    WINDOWS_VM_WINDOWS_ISO=${lib.strings.escapeShellArg windowsIsoPath}
    WINDOWS_VM_VIRTIO_ISO=${lib.strings.escapeShellArg virtioIsoPath}
    WINDOWS_VM_NETWORK_MODE=${lib.strings.escapeShellArg cfg.network.mode}
    WINDOWS_VM_NETWORK_BRIDGE=${lib.strings.escapeShellArg cfg.network.bridgeName}
    WINDOWS_VM_RDP_TARGET=${lib.strings.escapeShellArg cfg.rdp.defaultTarget}
    WINDOWS_VM_SPICE_PORT=${toString cfg.spice.port}
    WINDOWS_VM_LOOKING_GLASS_ENABLED=${if cfg.lookingGlass.enable then "1" else "0"}
    WINDOWS_VM_LOOKING_GLASS_SOCKET=${lib.strings.escapeShellArg cfg.lookingGlass.socketPath}
    WINDOWS_VM_VFIO_GPU_PCI=${lib.strings.escapeShellArg (if cfg.vfio.gpuPciAddress == null then "" else cfg.vfio.gpuPciAddress)}
    WINDOWS_VM_VFIO_AUDIO_PCI=${lib.strings.escapeShellArg (if cfg.vfio.audioPciAddress == null then "" else cfg.vfio.audioPciAddress)}
    WINDOWS_VM_VFIO_VENDOR_DEVICE_IDS=${lib.strings.escapeShellArg (lib.concatStringsSep "," cfg.vfio.vendorDeviceIds)}
    WINDOWS_VM_VFIO_IOMMU_KERNEL_PARAM=${lib.strings.escapeShellArg cfg.vfio.iommuKernelParam}

    PROFILE_rdp_ENABLED=${if cfg.profiles.rdp.enable then "1" else "0"}
    PROFILE_rdp_DOMAIN=${lib.strings.escapeShellArg profileArtifacts.rdp.baseDomain}
    PROFILE_rdp_INSTALL_DOMAIN=${lib.strings.escapeShellArg profileArtifacts.rdp.installDomain}
    PROFILE_rdp_XML=${lib.strings.escapeShellArg profileArtifacts.rdp.baseXml}
    PROFILE_rdp_INSTALL_XML_TEMPLATE=${lib.strings.escapeShellArg profileArtifacts.rdp.installXmlTemplate}

    PROFILE_virtio_ENABLED=${if cfg.profiles.virtio.enable then "1" else "0"}
    PROFILE_virtio_DOMAIN=${lib.strings.escapeShellArg profileArtifacts.virtio.baseDomain}
    PROFILE_virtio_INSTALL_DOMAIN=${lib.strings.escapeShellArg profileArtifacts.virtio.installDomain}
    PROFILE_virtio_XML=${lib.strings.escapeShellArg profileArtifacts.virtio.baseXml}
    PROFILE_virtio_INSTALL_XML_TEMPLATE=${lib.strings.escapeShellArg profileArtifacts.virtio.installXmlTemplate}

    PROFILE_vfio_ENABLED=${if cfg.profiles.vfio.enable then "1" else "0"}
    PROFILE_vfio_DOMAIN=${lib.strings.escapeShellArg profileArtifacts.vfio.baseDomain}
    PROFILE_vfio_INSTALL_DOMAIN=${lib.strings.escapeShellArg profileArtifacts.vfio.installDomain}
    PROFILE_vfio_XML=${lib.strings.escapeShellArg profileArtifacts.vfio.baseXml}
    PROFILE_vfio_INSTALL_XML_TEMPLATE=${lib.strings.escapeShellArg profileArtifacts.vfio.installXmlTemplate}
  '';

  vmctlPackage = import ./vmctl.nix {
    inherit lib pkgs;
    configFile = vmctlConfigFile;
  };
in
{
  options.my.virtualization.windowsVm = {
    enable = lib.mkEnableOption "Windows VM framework";

    user = lib.mkOption {
      type = lib.types.str;
      default = "srcres";
      description = "Primary Linux user who should be allowed to manage libvirt.";
    };

    vmNamePrefix = lib.mkOption {
      type = lib.types.str;
      default = "win11";
      description = "Prefix used for all libvirt domain names.";
    };

    storage = {
      rootDir = lib.mkOption {
        type = lib.types.str;
        default = "/var/lib/libvirt";
        description = "Root directory for VM state that must survive rebuilds.";
      };

      nvramDir = lib.mkOption {
        type = lib.types.str;
        default = "/var/lib/libvirt/qemu/nvram";
        description = "Directory that stores per-domain OVMF NVRAM files.";
      };

      swtpmDir = lib.mkOption {
        type = lib.types.str;
        default = "/var/lib/libvirt/swtpm";
        description = "Directory that stores per-domain swtpm state.";
      };

      channelDir = lib.mkOption {
        type = lib.types.str;
        default = "/var/lib/libvirt/qemu/channel/target";
        description = "Directory used for guest-agent channel sockets.";
      };
    };

    diskPath = lib.mkOption {
      type = lib.types.str;
      default = "/var/lib/libvirt/images/windows-main.qcow2";
      description = "Shared qcow2 disk used by all Windows profiles.";
    };

    diskSizeGiB = lib.mkOption {
      type = lib.types.ints.positive;
      default = 128;
      description = "Default qcow2 size when vmctl creates the shared disk.";
    };

    isoDirectory = lib.mkOption {
      type = lib.types.str;
      default = "/var/lib/libvirt/iso";
      description = "Directory that stores Windows and virtio installation ISOs.";
    };

    windowsIsoFile = lib.mkOption {
      type = lib.types.str;
      default = "Windows11.iso";
      description = "Filename of the Windows installer ISO inside isoDirectory.";
    };

    virtioIsoFile = lib.mkOption {
      type = lib.types.str;
      default = "virtio-win.iso";
      description = "Filename of the virtio driver ISO inside isoDirectory.";
    };

    memoryMiB = lib.mkOption {
      type = lib.types.ints.positive;
      default = 16384;
      description = "Guest memory size in MiB.";
    };

    vcpus = lib.mkOption {
      type = lib.types.ints.positive;
      default = 8;
      description = "Guest virtual CPU count.";
    };

    network = {
      mode = lib.mkOption {
        type = lib.types.enum [ "nat" "bridge" ];
        default = "nat";
        description = "How the guest NIC should attach to the host.";
      };

      bridgeName = lib.mkOption {
        type = lib.types.str;
        default = "br0";
        description = "Bridge name used when network.mode = \"bridge\".";
      };
    };

    rdp = {
      defaultTarget = lib.mkOption {
        type = lib.types.str;
        default = "192.168.122.10";
        description = "Default IP address or hostname used by vmctl connect rdp.";
      };
    };

    spice = {
      port = lib.mkOption {
        type = lib.types.port;
        default = 5930;
        description = "Fixed SPICE port used by rdp/virtio installer flows.";
      };
    };

    lookingGlass = {
      enable = lib.mkOption {
        type = lib.types.bool;
        default = false;
        description = "Whether vmctl should advertise a Looking Glass path for vfio.";
      };

      socketPath = lib.mkOption {
        type = lib.types.str;
        default = "/tmp/looking-glass";
        description = "Placeholder socket/path used by the Looking Glass client hint.";
      };
    };

    vfio = {
      gpuPciAddress = lib.mkOption {
        type = lib.types.nullOr lib.types.str;
        default = null;
        description = "PCI address of the GPU to pass through, e.g. 0000:01:00.0.";
      };

      audioPciAddress = lib.mkOption {
        type = lib.types.nullOr lib.types.str;
        default = null;
        description = "Optional PCI address of the GPU's audio function.";
      };

      vendorDeviceIds = lib.mkOption {
        type = lib.types.listOf lib.types.str;
        default = [ ];
        description = "Comma-separated vfio-pci.ids list (e.g. [\"10de:1b80\" \"10de:10f0\"]).";
      };

      iommuKernelParam = lib.mkOption {
        type = lib.types.str;
        default = "intel_iommu=on";
        description = "IOMMU kernel parameter skeleton used when vfio profile is enabled.";
      };
    };

    profiles = {
      rdp.enable = lib.mkOption {
        type = lib.types.bool;
        default = false;
        description = "Generate the stable RDP-oriented profile.";
      };

      virtio.enable = lib.mkOption {
        type = lib.types.bool;
        default = false;
        description = "Generate the SPICE + virtio-gpu profile.";
      };

      vfio.enable = lib.mkOption {
        type = lib.types.bool;
        default = false;
        description = "Generate the GPU-passthrough profile skeleton.";
      };
    };
  };

  config = lib.mkIf cfg.enable {
    assertions = [
      {
        assertion = lib.hasAttr cfg.user config.users.users;
        message = "my.virtualization.windowsVm.user must match an existing NixOS user entry.";
      }
      {
        assertion = cfg.network.mode != "bridge" || cfg.network.bridgeName != "";
        message = "my.virtualization.windowsVm.network.bridgeName must be set when bridge mode is enabled.";
      }
    ];

    security.polkit.enable = true;

    virtualisation.libvirtd = {
      enable = true;
      qemu.package = pkgs.qemu_kvm;
      qemu.swtpm.enable = true;
    };

    users.users.${cfg.user}.extraGroups = lib.mkAfter [ "libvirtd" ];

    # VFIO is intentionally opt-in. The NixOS-side kernel knobs here are only a
    # skeleton: they make the required boot-time dependency explicit, but they do
    # not guess which GPU should be detached from the host.
    boot.kernelParams = lib.mkIf cfg.profiles.vfio.enable (
      [
        cfg.vfio.iommuKernelParam
        "iommu=pt"
      ] ++ lib.optionals (cfg.vfio.vendorDeviceIds != [ ]) [
        "vfio-pci.ids=${lib.concatStringsSep "," cfg.vfio.vendorDeviceIds}"
      ]
    );

    boot.initrd.kernelModules = lib.mkIf cfg.profiles.vfio.enable (lib.mkAfter [
      "vfio"
      "vfio_pci"
      "vfio_iommu_type1"
    ]);

    boot.extraModprobeConfig = lib.mkIf (cfg.profiles.vfio.enable && cfg.vfio.vendorDeviceIds != [ ]) (lib.mkAfter ''
      # Bind the requested GPU functions to vfio-pci early. The actual PCI IDs
      # are host-specific and must be filled in by the user.
      options vfio-pci ids=${lib.concatStringsSep "," cfg.vfio.vendorDeviceIds}
    '');

    systemd.tmpfiles.rules = [
      "d ${cfg.storage.rootDir} 0755 root root -"
      "d ${diskDir} 0755 root libvirtd -"
      "d ${cfg.isoDirectory} 0755 root libvirtd -"
      "d ${cfg.storage.nvramDir} 0755 root libvirtd -"
      "d ${cfg.storage.swtpmDir} 0755 root libvirtd -"
      "d ${cfg.storage.channelDir} 0755 root libvirtd -"
    ];

    environment.systemPackages = [
      vmctlPackage
    ];
  };
}
