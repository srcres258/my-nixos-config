# srcres258's personal NixOS configuration

This repository now includes a declarative Windows VM framework for native NixOS hosts.
The main entry point is `vmctl`, which wraps `virsh`, `qemu-img`, `remote-viewer`, and
`xfreerdp` so day-to-day VM work stays terminal-first.

## Architecture

- `modules/virtualization/windows-vm/default.nix` defines the NixOS module
- `modules/virtualization/windows-vm/templates.nix` generates libvirt XML templates
- `modules/virtualization/windows-vm/vmctl.nix` and `vmctl.sh` provide the CLI
- `platforms/native/configuration.nix` imports the module for x86_64 native hosts

The framework is declarative, but the Windows qcow2 disk and ISO files stay outside the
Nix store under `/var/lib/libvirt/`.

## Profiles

| Profile | Purpose | Display / connect |
| --- | --- | --- |
| `rdp` | Stable daily-use Windows desktop | SPICE for install, then RDP |
| `virtio` | Test virtio-gpu / SPICE remote graphics | SPICE + virtio-gpu |
| `vfio` | GPU passthrough skeleton | Physical GPU / Looking Glass placeholder |

All profiles share one Windows qcow2 disk. Only one profile may run at a time.

## Default paths

- Disk: `/var/lib/libvirt/images/windows-main.qcow2`
- ISO dir: `/var/lib/libvirt/iso`
- NVRAM dir: `/var/lib/libvirt/qemu/nvram`
- swtpm dir: `/var/lib/libvirt/swtpm`

The default ISO filenames are:

- `Windows11.iso`
- `virtio-win.iso`

## Example configuration

```nix
{
  my.virtualization.windowsVm = {
    enable = true;
    user = "srcres";

    diskPath = "/var/lib/libvirt/images/windows-main.qcow2";
    diskSizeGiB = 128;
    isoDirectory = "/var/lib/libvirt/iso";

    # Default install media. You can still override these per command.
    windowsIsoFile = "Windows11.iso";
    virtioIsoFile = "virtio-win.iso";

    network.mode = "nat";
    rdp.defaultTarget = "192.168.122.10";

    profiles.rdp.enable = true;
    profiles.virtio.enable = false;
    profiles.vfio.enable = false;
  };
}
```

## Flexible ISO selection

The ISO path does **not** have to be hard-coded in the Nix config. `vmctl install`
accepts temporary overrides:

```bash
vmctl install rdp   --windows-iso /mnt/isos/Win11_23H2_x64.iso   --virtio-iso /mnt/isos/virtio-win.iso
```

If you omit those flags, `vmctl` uses the Nix config defaults.

## First-time workflow

1. Put the ISOs into the ISO directory.
2. Create the shared disk:
   ```bash
   vmctl create-disk
   ```
3. Define a profile:
   ```bash
   vmctl define rdp
   ```
4. Start install mode (this creates a transient `win11-rdp-install` domain):
   ```bash
   vmctl install rdp
   ```
   or with explicit ISOs:
   ```bash
   vmctl install rdp --windows-iso /mnt/isos/Win11.iso --virtio-iso /mnt/isos/virtio-win.iso
   ```
5. Complete the Windows install in the SPICE window.
6. Enable RDP inside Windows (Windows Home cannot host RDP).
7. Start the normal profile:
   ```bash
   vmctl start rdp
   ```
8. Connect from Linux:
   ```bash
   vmctl connect rdp
   ```

## Common commands

- `vmctl list` — show all profiles, definition state, running state, disk path, connection hint
- `vmctl status [profile]` — detailed state
- `vmctl stop <profile>` — graceful shutdown
- `vmctl force-stop <profile>` — hard poweroff
- `vmctl undefine <profile>` — remove the libvirt definition, keep disk/NVRAM/TPM state
- `vmctl console <profile>` — serial/monitor debug path
- `vmctl doctor` — host checks (`/dev/kvm`, libvirt, OVMF, swtpm, virt-install, `qemu-img`, VFIO hints)

## Profile notes

### `rdp`

- Best default for office work
- Uses SPICE during installation so the first boot is visible
- After installation, use `xfreerdp` via `vmctl connect rdp`

### `virtio`

- Uses `virtio-gpu` with SPICE
- Good for testing the remote graphics path and virtio display behavior
- Still shares the same Windows disk as `rdp`

### `vfio`

- Requires host-side VFIO/IOMMU setup before it is actually useful
- Fill in GPU PCI address, optional audio function PCI address, and vendor:device IDs
- No GPU hot-switching: profile changes are pre-boot only
- `vmctl connect vfio` currently prints a Looking Glass / physical-display hint unless you fill in your own client workflow

## Host-side VFIO skeleton

If you enable the VFIO profile, the module will add a kernel-parameter / initrd skeleton only:

- `intel_iommu=on` (override if your host is not Intel)
- `iommu=pt`
- `vfio`, `vfio_pci`, `vfio_iommu_type1`
- optional `vfio-pci.ids=...`

You still need to provide the actual GPU PCI addresses and make sure the host GPU driver is not claiming the passthrough device.

## Troubleshooting

- **No `/dev/kvm`**: virtualization is disabled in BIOS/UEFI or the host module is missing.
- **libvirt connection fails**: check `virtualisation.libvirtd.enable = true` and `libvirtd` group membership.
- **Windows disk missing**: run `vmctl create-disk` before `vmctl define` / `vmctl start`.
- **ISO missing**: place `Windows11.iso` and `virtio-win.iso` into the ISO directory.
- **RDP connect fails**: verify the guest has an RDP-capable Windows edition (Pro/Enterprise, not Home).
- **VFIO does nothing**: fill in the PCI addresses, IOMMU parameters, and host driver binding first.

## License

Licensed under the [MIT License](https://spdx.org/licenses/MIT.html).
