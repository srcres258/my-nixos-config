    set -euo pipefail

    source "$CONFIG_FILE"

    readonly VMCTL_LOCK_FILE="${WINDOWS_VM_STORAGE_ROOT}/vmctl.lock"

    die() {
      printf 'vmctl: %s\n' "$*" >&2
      exit 1
    }

    warn() {
      printf 'vmctl: warning: %s\n' "$*" >&2
    }

    info() {
      printf 'vmctl: %s\n' "$*"
    }

    virsh_system() {
      command virsh -c qemu:///system "$@"
    }

    ensure_profile_supported() {
      case "$1" in
        rdp)
          [ "$PROFILE_rdp_ENABLED" = "1" ] || die "profile rdp is disabled in NixOS config"
          ;;
        virtio)
          [ "$PROFILE_virtio_ENABLED" = "1" ] || die "profile virtio is disabled in NixOS config"
          ;;
        vfio)
          [ "$PROFILE_vfio_ENABLED" = "1" ] || die "profile vfio is disabled in NixOS config"
          ;;
        *)
          die "unknown profile '$1'"
          ;;
      esac
    }

    profile_domain() {
      case "$1" in
        rdp) printf '%s' "$PROFILE_rdp_DOMAIN" ;;
        virtio) printf '%s' "$PROFILE_virtio_DOMAIN" ;;
        vfio) printf '%s' "$PROFILE_vfio_DOMAIN" ;;
        *) die "unknown profile '$1'" ;;
      esac
    }

    profile_install_domain() {
      case "$1" in
        rdp) printf '%s' "$PROFILE_rdp_INSTALL_DOMAIN" ;;
        virtio) printf '%s' "$PROFILE_virtio_INSTALL_DOMAIN" ;;
        vfio) printf '%s' "$PROFILE_vfio_INSTALL_DOMAIN" ;;
        *) die "unknown profile '$1'" ;;
      esac
    }

    profile_xml() {
      case "$1" in
        rdp) printf '%s' "$PROFILE_rdp_XML" ;;
        virtio) printf '%s' "$PROFILE_virtio_XML" ;;
        vfio) printf '%s' "$PROFILE_vfio_XML" ;;
        *) die "unknown profile '$1'" ;;
      esac
    }

    profile_install_xml_template() {
      case "$1" in
        rdp) printf '%s' "$PROFILE_rdp_INSTALL_XML_TEMPLATE" ;;
        virtio) printf '%s' "$PROFILE_virtio_INSTALL_XML_TEMPLATE" ;;
        vfio) printf '%s' "$PROFILE_vfio_INSTALL_XML_TEMPLATE" ;;
        *) die "unknown profile '$1'" ;;
      esac
    }

    sed_escape() {
      printf '%s' "$1" | sed -e 's/\\/\\\\/g' -e 's/&/\\&/g' -e 's/|/\\|/g'
    }

    render_install_xml() {
      local template windows_iso virtio_iso output
      template="$1"
      windows_iso="$(sed_escape "$2")"
      virtio_iso="$(sed_escape "$3")"
      output="$(mktemp)"
      printf '%s' "$template" | sed -e "s|__WINDOWS_ISO__|$windows_iso|g" -e "s|__VIRTIO_ISO__|$virtio_iso|g" > "$output"
      printf '%s' "$output"
    }

    profile_connection_hint() {
      case "$1" in
        rdp)
          printf 'xfreerdp /v:%s /cert:ignore /dynamic-resolution' "$WINDOWS_VM_RDP_TARGET"
          ;;
        virtio)
          printf 'remote-viewer spice://127.0.0.1:%s' "$WINDOWS_VM_SPICE_PORT"
          ;;
        vfio)
          if [ "$WINDOWS_VM_LOOKING_GLASS_ENABLED" = "1" ]; then
            printf 'TODO: start your Looking Glass client against %s' "$WINDOWS_VM_LOOKING_GLASS_SOCKET"
          else
            printf 'TODO: connect to the physical GPU output or fill in Looking Glass parameters'
          fi
          ;;
        *)
          die "unknown profile '$1'"
          ;;
      esac
    }

    profile_defined() {
      virsh_system dominfo "$1" >/dev/null 2>&1
    }

    profile_state() {
      if ! profile_defined "$1"; then
        printf 'undefined'
        return 0
      fi
      virsh_system domstate "$1" | tr -d '\r'
    }

    profile_running() {
      case "$(profile_state "$1")" in
        running|paused|pmsuspended)
          return 0
          ;;
        *)
          return 1
          ;;
      esac
    }

    require_disk() {
      [ -f "$WINDOWS_VM_DISK_PATH" ] || die "missing base disk: $WINDOWS_VM_DISK_PATH (run 'vmctl create-disk')"
    }

    require_install_media() {
      local windows_iso="$1"
      local virtio_iso="$2"
      [ -f "$windows_iso" ] || die "missing Windows ISO: $windows_iso"
      [ -f "$virtio_iso" ] || die "missing virtio ISO: $virtio_iso"
    }

    require_libvirt() {
      virsh_system uri >/dev/null 2>&1 || die "cannot reach qemu:///system; check libvirtd and libvirtd group membership"
    }

    with_lock() {
      mkdir -p "$(dirname "$VMCTL_LOCK_FILE")"
      exec 9>"$VMCTL_LOCK_FILE"
      flock -n 9 || die "another vmctl operation is already running; shared qcow2 access is locked"
      "$@"
    }

    other_profile_running() {
      local target="$1"
      for profile in rdp virtio vfio; do
        [ "$profile" = "$target" ] && continue
        if profile_defined "$profile" && profile_running "$profile"; then
          printf '%s' "$profile"
          return 0
        fi
      done
      return 1
    }

    print_profile_row() {
      local profile defined state connection diskpath
      profile="$1"
      if profile_defined "$profile"; then
        defined=yes
      else
        defined=no
      fi
      state="$(profile_state "$profile")"
      connection="$(profile_connection_hint "$profile")"
      diskpath="$WINDOWS_VM_DISK_PATH"
      printf '%-8s %-8s %-12s %-42s %s\n' "$profile" "$defined" "$state" "$diskpath" "$connection"
    }

    command_list() {
      printf '%-8s %-8s %-12s %-42s %s\n' "PROFILE" "DEFINED" "STATE" "DISK" "CONNECT"
      printf '%-8s %-8s %-12s %-42s %s\n' "-------" "-------" "-----------" "----" "-------"
      for profile in rdp virtio vfio; do
        print_profile_row "$profile"
      done
    }

    command_status() {
      if [ "$#" -eq 0 ]; then
        command_list
        return 0
      fi

      local profile
      profile="$1"
      ensure_profile_supported "$profile"
      printf 'profile: %s\n' "$profile"
      printf 'domain: %s\n' "$(profile_domain "$profile")"
      printf 'state: %s\n' "$(profile_state "$profile")"
      printf 'disk: %s\n' "$WINDOWS_VM_DISK_PATH"
      printf 'connect: %s\n' "$(profile_connection_hint "$profile")"
      if profile_defined "$profile"; then
        printf '\nlibvirt:\n'
        virsh_system dominfo "$(profile_domain "$profile")"
      fi
    }

    command_define() {
      local profile domain xml
      profile="$1"
      ensure_profile_supported "$profile"
      require_disk
      require_libvirt
      domain="$(profile_domain "$profile")"
      xml="$(profile_xml "$profile")"
      info "defining $domain"
      virsh_system define "$xml" >/dev/null
      info "defined $domain"
    }

    command_undefine() {
      local profile domain
      profile="$1"
      ensure_profile_supported "$profile"
      require_libvirt
      domain="$(profile_domain "$profile")"
      if ! profile_defined "$profile"; then
        info "$domain is already undefined"
        return 0
      fi
      if profile_running "$profile"; then
        die "$domain is running; stop it first"
      fi
      info "undefining $domain (disk is preserved)"
      virsh_system undefine "$domain" --nvram >/dev/null
    }

    command_create_disk() {
      if [ -f "$WINDOWS_VM_DISK_PATH" ]; then
        info "disk already exists: $WINDOWS_VM_DISK_PATH"
        return 0
      fi
      mkdir -p "$(dirname "$WINDOWS_VM_DISK_PATH")"
      info "creating qcow2 disk: $WINDOWS_VM_DISK_PATH (${WINDOWS_VM_DISK_SIZE_GIB}G)"
      qemu-img create -f qcow2 "$WINDOWS_VM_DISK_PATH" "${WINDOWS_VM_DISK_SIZE_GIB}G" >/dev/null
    }

    command_stop() {
      local profile domain
      profile="$1"
      ensure_profile_supported "$profile"
      require_libvirt
      domain="$(profile_domain "$profile")"
      if ! profile_defined "$profile"; then
        info "$domain is not defined"
        return 0
      fi
      if ! profile_running "$profile"; then
        info "$domain is already stopped"
        return 0
      fi
      info "requesting graceful shutdown for $domain"
      virsh_system shutdown "$domain" >/dev/null
    }

    command_force_stop() {
      local profile domain
      profile="$1"
      ensure_profile_supported "$profile"
      require_libvirt
      domain="$(profile_domain "$profile")"
      if ! profile_defined "$profile"; then
        info "$domain is not defined"
        return 0
      fi
      if ! profile_running "$profile"; then
        info "$domain is already stopped"
        return 0
      fi
      info "forcing poweroff for $domain"
      virsh_system destroy "$domain" >/dev/null
    }

    command_start() {
      local profile domain blocker
      profile="$1"
      ensure_profile_supported "$profile"
      require_disk
      require_libvirt
      domain="$(profile_domain "$profile")"
      if ! profile_defined "$profile"; then
        die "$domain is not defined; run 'vmctl define $profile' first"
      fi
      if profile_running "$profile"; then
        info "$domain is already running"
        printf '%s\n' "$(profile_connection_hint "$profile")"
        return 0
      fi
      if blocker="$(other_profile_running "$profile")"; then
        die "shared qcow2 is already in use by running profile '$blocker'"
      fi
      info "starting $domain"
      virsh_system start "$domain" >/dev/null
      printf '%s\n' "next: $(profile_connection_hint "$profile")"
    }

    command_install() {
      local profile install_domain install_template install_xml blocker windows_iso virtio_iso
      profile=""
      windows_iso="$WINDOWS_VM_WINDOWS_ISO"
      virtio_iso="$WINDOWS_VM_VIRTIO_ISO"

      while [ "$#" -gt 0 ]; do
        case "$1" in
          --windows-iso)
            [ "$#" -ge 2 ] || die "usage: vmctl install <profile> [--windows-iso PATH] [--virtio-iso PATH]"
            windows_iso="$2"
            shift 2
            ;;
          --windows-iso=*)
            windows_iso="${1#*=}"
            shift
            ;;
          --virtio-iso)
            [ "$#" -ge 2 ] || die "usage: vmctl install <profile> [--windows-iso PATH] [--virtio-iso PATH]"
            virtio_iso="$2"
            shift 2
            ;;
          --virtio-iso=*)
            virtio_iso="${1#*=}"
            shift
            ;;
          --help|-h)
            die "usage: vmctl install <profile> [--windows-iso PATH] [--virtio-iso PATH]"
            ;;
          *)
            if [ -z "$profile" ]; then
              profile="$1"
              shift
            else
              die "unexpected install argument: $1"
            fi
            ;;
        esac
      done

      [ -n "$profile" ] || die "usage: vmctl install <profile> [--windows-iso PATH] [--virtio-iso PATH]"
      ensure_profile_supported "$profile"
      require_disk
      require_install_media "$windows_iso" "$virtio_iso"
      require_libvirt
      if blocker="$(other_profile_running "$profile")"; then
        die "shared qcow2 is already in use by running profile '$blocker'"
      fi
      install_domain="$(profile_install_domain "$profile")"
      install_template="$(profile_install_xml_template "$profile")"
      install_xml="$(render_install_xml "$install_template" "$windows_iso" "$virtio_iso")"
      trap 'rm -f "$install_xml"' EXIT INT TERM
      if profile_defined "$profile" && profile_running "$profile"; then
        die "base domain $(profile_domain "$profile") is already running; stop it first"
      fi
      if [ "$profile" = "vfio" ]; then
        warn "vfio install mode is a bootstrap path; it does not require host GPU passthrough to start the installer"
      fi
      info "creating transient installer domain $install_domain"
      virsh_system create "$install_xml" >/dev/null
      rm -f "$install_xml"
      trap - EXIT INT TERM
      if [ -n "${DISPLAY:-}" ] || [ -n "${WAYLAND_DISPLAY:-}" ]; then
        exec remote-viewer "spice://127.0.0.1:${WINDOWS_VM_SPICE_PORT}"
      fi
      info "use: remote-viewer spice://127.0.0.1:${WINDOWS_VM_SPICE_PORT}"
    }

    command_connect() {
      local profile
      profile="$1"
      ensure_profile_supported "$profile"
      require_libvirt
      if ! profile_defined "$profile" || ! profile_running "$profile"; then
        die "$(profile_domain "$profile") is not running"
      fi
      case "$profile" in
        rdp)
          exec xfreerdp /v:"$WINDOWS_VM_RDP_TARGET" /cert:ignore /dynamic-resolution
          ;;
        virtio)
          exec remote-viewer "spice://127.0.0.1:${WINDOWS_VM_SPICE_PORT}"
          ;;
        vfio)
          printf '%s\n' "$(profile_connection_hint "$profile")"
          ;;
        *)
          die "unknown profile '$profile'"
          ;;
      esac
    }

    command_console() {
      local profile domain
      profile="$1"
      ensure_profile_supported "$profile"
      require_libvirt
      domain="$(profile_domain "$profile")"
      if ! profile_defined "$profile"; then
        die "$domain is not defined"
      fi
      info "Windows usually ignores the serial console; use Ctrl+] to exit"
      exec virsh_system console "$domain"
    }

    command_doctor() {
      local failures=0

      check() {
        local label="$1"
        shift
        if "$@"; then
          printf 'ok   %s\n' "$label"
        else
          printf 'fail %s\n' "$label"
          failures=1
        fi
      }

      warn_if_missing() {
        local label="$1"
        shift
        if "$@"; then
          printf 'ok   %s\n' "$label"
        else
          printf 'warn %s\n' "$label"
        fi
      }

      printf 'host checks:\n'
      check "/dev/kvm present" test -e /dev/kvm
      check "virsh can reach qemu:///system" sh -c 'virsh -c qemu:///system uri >/dev/null 2>&1'
      check "current user is in libvirtd group" sh -c 'case " $(id -nG) " in *" libvirtd "*) true ;; *) false ;; esac'
      warn_if_missing "OVMF metadata visible under /run/libvirt/nix-ovmf" test -e /run/libvirt/nix-ovmf/OVMF_CODE.fd
      warn_if_missing "swtpm binary available to libvirt" command -v swtpm >/dev/null 2>&1
      check "qemu-img present" command -v qemu-img >/dev/null 2>&1
      check "virt-install present" command -v virt-install >/dev/null 2>&1
      check "virsh present" command -v virsh >/dev/null 2>&1

      printf '\nshared VM paths:\n'
      printf 'disk: %s\n' "$WINDOWS_VM_DISK_PATH"
      printf 'iso dir: %s\n' "$WINDOWS_VM_ISO_DIRECTORY"
      printf 'Windows ISO: %s\n' "$WINDOWS_VM_WINDOWS_ISO"
      printf 'virtio ISO: %s\n' "$WINDOWS_VM_VIRTIO_ISO"

      warn_if_missing "Windows ISO exists" test -f "$WINDOWS_VM_WINDOWS_ISO"
      warn_if_missing "virtio ISO exists" test -f "$WINDOWS_VM_VIRTIO_ISO"
      warn_if_missing "qcow2 disk exists" test -f "$WINDOWS_VM_DISK_PATH"

      printf '\nlibvirt service:\n'
      warn_if_missing "qemu:///system URI works now" sh -c 'virsh -c qemu:///system uri >/dev/null 2>&1'

      if [ "$PROFILE_vfio_ENABLED" = "1" ]; then
        printf '\nvfio checks:\n'
        warn_if_missing "IOMMU kernel cmdline present" sh -c 'case "$(cat /proc/cmdline)" in *intel_iommu=on*|*amd_iommu=on*) true ;; *) false ;; esac'
        warn_if_missing "vfio kernel modules appear loaded" sh -c 'lsmod | grep -q "^vfio"'
        if [ -n "$WINDOWS_VM_VFIO_GPU_PCI" ]; then
          warn_if_missing "GPU PCI device visible" sh -c 'lspci -D -s "$1" >/dev/null 2>&1' sh "$WINDOWS_VM_VFIO_GPU_PCI"
          warn_if_missing "GPU driver currently bound to vfio-pci" sh -c 'lspci -D -nnk -s "$1" | grep -q "Kernel driver in use: vfio-pci"' sh "$WINDOWS_VM_VFIO_GPU_PCI"
        else
          warn "vfio.gpuPciAddress is TODO"
        fi
      fi

      if command -v virt-host-validate >/dev/null 2>&1; then
        printf '\nvirt-host-validate qemu:\n'
        if virt-host-validate qemu; then
          printf 'ok   virt-host-validate qemu passed\n'
        else
          warn "virt-host-validate qemu reported issues (inspect above output)"
        fi
      fi

      return "$failures"
    }

    case "${1:-}" in
      list)
        command_list
        ;;
      define)
        [ $# -eq 2 ] || die "usage: vmctl define <profile>"
        with_lock command_define "$2"
        ;;
      undefine)
        [ $# -eq 2 ] || die "usage: vmctl undefine <profile>"
        with_lock command_undefine "$2"
        ;;
      start)
        [ $# -eq 2 ] || die "usage: vmctl start <profile>"
        with_lock command_start "$2"
        ;;
      stop)
        [ $# -eq 2 ] || die "usage: vmctl stop <profile>"
        with_lock command_stop "$2"
        ;;
      force-stop)
        [ $# -eq 2 ] || die "usage: vmctl force-stop <profile>"
        with_lock command_force_stop "$2"
        ;;
      status)
        case $# in
          1) command_status ;;
          2) command_status "$2" ;;
          *) die "usage: vmctl status [profile]" ;;
        esac
        ;;
      install)
        [ $# -eq 2 ] || die "usage: vmctl install <profile>"
        with_lock command_install "$2"
        ;;
      connect)
        [ $# -eq 2 ] || die "usage: vmctl connect <profile>"
        command_connect "$2"
        ;;
      console)
        [ $# -eq 2 ] || die "usage: vmctl console <profile>"
        command_console "$2"
        ;;
      create-disk)
        with_lock command_create_disk
        ;;
      doctor)
        command_doctor
        ;;
      help|--help|-h|"")
        cat <<'EOF'
    vmctl - unified Windows VM control

    usage:
      vmctl list
      vmctl define <profile>
      vmctl undefine <profile>
      vmctl start <profile>
      vmctl stop <profile>
      vmctl force-stop <profile>
      vmctl status [profile]
      vmctl install <profile> [--windows-iso PATH] [--virtio-iso PATH]
      vmctl connect <profile>
      vmctl console <profile>
      vmctl create-disk
      vmctl doctor

    profiles:
      rdp     - graphical install + stable RDP-oriented desktop
      virtio  - SPICE + virtio-gpu test profile
      vfio    - GPU passthrough profile (requires host-side VFIO setup)
EOF
        ;;
      *)
        die "unknown command '$1' (try 'vmctl help')"
        ;;
    esac
