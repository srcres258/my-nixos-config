{ lib }:
let
  xmlEscape = value:
    lib.replaceStrings
      [ "&" "<" ">" "\"" "'" ]
      [ "&amp;" "&lt;" "&gt;" "&quot;" "&apos;" ]
      (toString value);

  mkUuid = name:
    let
      hash = builtins.hashString "sha256" name;
    in
    "${builtins.substring 0 8 hash}-${builtins.substring 8 4 hash}-${builtins.substring 12 4 hash}-${builtins.substring 16 4 hash}-${builtins.substring 20 12 hash}";

  mkPciAddressXml = address:
    let
      match = builtins.match "([0-9a-fA-F]{4}):([0-9a-fA-F]{2}):([0-9a-fA-F]{2})\\.([0-7])" address;
    in
    if match == null then
      throw "windows-vm: invalid PCI address '${address}', expected form 0000:00:00.0"
    else
      ''
        <address domain='0x${builtins.elemAt match 0}' bus='0x${builtins.elemAt match 1}' slot='0x${builtins.elemAt match 2}' function='0x${builtins.elemAt match 3}'/>
      '';

  mkNetworkXml =
    { mode
    , bridgeName ? ""
    }:
    if mode == "bridge" then
      ''
        <interface type='bridge'>
          <source bridge='${xmlEscape bridgeName}'/>
          <model type='virtio'/>
        </interface>
      ''
    else
      ''
        <interface type='network'>
          <source network='default'/>
          <model type='virtio'/>
        </interface>
      '';

  mkSpiceGraphicsXml = port: ''
    <graphics type='spice' autoport='no' port='${toString port}' listen='127.0.0.1' tlsPort='-1'>
      <listen type='address' address='127.0.0.1'/>
    </graphics>
    <sound model='ich9'/>
    <redirdev bus='usb' type='spicevmc'/>
    <channel type='spicevmc'>
      <target type='virtio' name='com.redhat.spice.0'/>
    </channel>
  '';

  mkVideoXml = profile:
    if profile == "rdp" then ''
      <video>
        <model type='qxl' ram='65536' vram='65536' vgamem='16384' heads='1'/>
      </video>
    '' else if profile == "virtio" then ''
      <video>
        <model type='virtio' heads='1' primary='yes'/>
      </video>
    '' else "";

  mkDiskXml = diskPath: ''
    <disk type='file' device='disk'>
      <driver name='qemu' type='qcow2' cache='none' discard='unmap'/>
      <source file='${xmlEscape diskPath}'/>
      <target dev='vda' bus='virtio'/>
    </disk>
  '';

  mkCdromXml =
    { path
    , targetDev
    , bootOrder ? null
    }:
    ''
      <disk type='file' device='cdrom'>
        <driver name='qemu' type='raw'/>
        <source file='${xmlEscape path}'/>
        <target dev='${xmlEscape targetDev}' bus='sata'/>
        <readonly/>
        ${lib.optionalString (bootOrder != null) "<boot order='${toString bootOrder}'/>"}
      </disk>
    '';

  mkTpmXml = tpmStateDir: ''
    <tpm model='tpm-tis'>
      <backend type='emulator' version='2.0'>
        <source type='dir' path='${xmlEscape tpmStateDir}'/>
      </backend>
    </tpm>
  '';

  mkHostdevXml = pciAddress: ''
    <hostdev mode='subsystem' type='pci' managed='yes'>
      <source>
        ${mkPciAddressXml pciAddress}
      </source>
    </hostdev>
  '';

  mkDomainXml =
    { name
    , memoryMiB
    , vcpus
    , diskPath
    , networkMode
    , bridgeName ? ""
    , graphicsXml ? ""
    , videoXml ? ""
    , tpmStateDir ? null
    , nvramPath ? null
    , extraDevicesXml ? ""
    , installMediaXml ? ""
    , guestAgentChannelPath ? null
    , bootFromCdrom ? false
    }:
    ''
      <domain type='kvm'>
        <name>${xmlEscape name}</name>
        <uuid>${mkUuid name}</uuid>
        <memory unit='MiB'>${toString memoryMiB}</memory>
        <currentMemory unit='MiB'>${toString memoryMiB}</currentMemory>
        <vcpu placement='static'>${toString vcpus}</vcpu>
        <os firmware='efi'>
          <type arch='x86_64' machine='q35'>hvm</type>
          ${lib.optionalString (nvramPath != null) "<nvram template='/run/libvirt/nix-ovmf/OVMF_VARS.fd'>${xmlEscape nvramPath}</nvram>"}
          ${lib.optionalString bootFromCdrom "<boot dev='cdrom'/>"}
        </os>
        <features>
          <acpi/>
          <apic/>
          <hyperv>
            <relaxed state='on'/>
            <vapic state='on'/>
            <spinlocks state='on' retries='8191'/>
            <vpindex state='on'/>
            <synic state='on'/>
            <stimer state='on'/>
            <reset state='on'/>
            <frequencies state='on'/>
            <reenlightenment state='on'/>
            <tlbflush state='on'/>
            <ipi state='on'/>
            <evmcs state='on'/>
          </hyperv>
          <smm state='on'/>
        </features>
        <cpu mode='host-passthrough' check='none'/>
        <clock offset='localtime'/>
        <on_poweroff>destroy</on_poweroff>
        <on_reboot>restart</on_reboot>
        <on_crash>destroy</on_crash>
        <devices>
          ${mkDiskXml diskPath}
          ${installMediaXml}
          <controller type='pci' model='pcie-root'/>
          <controller type='usb' model='qemu-xhci'/>
          <controller type='sata' index='0'/>
          <input type='tablet' bus='usb'/>
          <serial type='pty'>
            <target port='0'/>
          </serial>
          <console type='pty'>
            <target type='serial' port='0'/>
          </console>
          ${lib.optionalString (guestAgentChannelPath != null) ''
          <channel type='unix'>
            <source mode='bind' path='${xmlEscape guestAgentChannelPath}'/>
            <target type='virtio' name='org.qemu.guest_agent.0'/>
          </channel>
          ''}
          <memballoon model='virtio'/>
          <rng model='virtio'>
            <backend model='random'>/dev/urandom</backend>
          </rng>
            ${mkNetworkXml {
              mode = networkMode;
              inherit bridgeName;
            }}
          ${graphicsXml}
          ${videoXml}
          ${lib.optionalString (tpmStateDir != null) (mkTpmXml tpmStateDir)}
          ${extraDevicesXml}
        </devices>
      </domain>
    '';
in
{
  inherit
    mkUuid
    mkNetworkXml
    mkSpiceGraphicsXml
    mkVideoXml
    mkDiskXml
    mkCdromXml
    mkTpmXml
    mkHostdevXml
    mkDomainXml;
}
