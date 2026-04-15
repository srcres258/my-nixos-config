{ lib, pkgs, config, ... }:
let
  aic8800d80Src = pkgs.fetchFromGitHub {
    owner = "shenmintao";
    repo = "aic8800d80";
    rev = "05710dff05dabce66ab3ee80f40484892c512b3c";
    hash = "sha256-QVpuJrCssBf4fwycq7oN0Oi9OxpQUqrSTQuHk5UE9+U=";
  };

  aic8800d80 = config.boot.kernelPackages.callPackage (
    {
      stdenv,
      kernel,
    }:
    stdenv.mkDerivation {
      pname = "aic8800d80";
      version = "unstable-2026-04-13";
      src = aic8800d80Src;

      nativeBuildInputs = kernel.moduleBuildDependencies;

      buildPhase = ''
        runHook preBuild
        make -C drivers/aic8800 \
          KVER=${kernel.modDirVersion} \
          KDIR=${kernel.dev}/lib/modules/${kernel.modDirVersion}/build
        runHook postBuild
      '';

      installPhase = ''
        runHook preInstall
        modDir=$out/lib/modules/${kernel.modDirVersion}/kernel/drivers/net/wireless/aic8800
        mkdir -p "$modDir"
        install -m 644 drivers/aic8800/aic_load_fw/aic_load_fw.ko "$modDir"/
        install -m 644 drivers/aic8800/aic8800_fdrv/aic8800_fdrv.ko "$modDir"/
        runHook postInstall
      '';
    }
  ) { };

  aic8800d80Firmware = pkgs.stdenvNoCC.mkDerivation {
    pname = "aic8800d80-firmware";
    version = "unstable-2026-04-13";
    src = aic8800d80Src;

    installPhase = ''
      runHook preInstall
      mkdir -p $out/lib/firmware
      cp -r fw/* $out/lib/firmware/

      # Some AIC8800 USB variants probe as "AIC8800DC" while others use
      # "AIC8800D80" firmware layout. Provide compatibility links so both
      # probe paths resolve at runtime.
      if [ -d $out/lib/firmware/aic8800D80 ] && [ ! -e $out/lib/firmware/aic8800DC ]; then
        ln -s aic8800D80 $out/lib/firmware/aic8800DC
      fi
      if [ -d $out/lib/firmware/aic8800DC ] && [ ! -e $out/lib/firmware/aic8800D80 ]; then
        ln -s aic8800DC $out/lib/firmware/aic8800D80
      fi

      if [ -e $out/lib/firmware/aic8800D80/fmacfw_patch_8800dc_u02.bin ] && [ ! -e $out/lib/firmware/aic8800DC/fmacfw_patch_8800dc_u02.bin ]; then
        mkdir -p $out/lib/firmware/aic8800DC
        ln -s ../aic8800D80/fmacfw_patch_8800dc_u02.bin $out/lib/firmware/aic8800DC/fmacfw_patch_8800dc_u02.bin
      fi

      mkdir -p $out/lib/udev/rules.d
      cat > $out/lib/udev/rules.d/99-aic8800d80-mode-switch.rules <<'EOF'
      ACTION=="add", SUBSYSTEM=="block", ENV{DEVTYPE}=="disk", KERNEL=="sd*", ATTRS{idVendor}=="a69c", ATTRS{idProduct}=="5721", RUN+="${pkgs.util-linux}/bin/eject /dev/%k"
      ACTION=="add", SUBSYSTEM=="block", ENV{DEVTYPE}=="disk", KERNEL=="sd*", ATTRS{idVendor}=="a69c", ATTRS{idProduct}=="5723", RUN+="${pkgs.util-linux}/bin/eject /dev/%k"
      ACTION=="add", SUBSYSTEM=="block", ENV{DEVTYPE}=="disk", KERNEL=="sd*", ATTRS{idVendor}=="a69c", ATTRS{idProduct}=="5724", RUN+="${pkgs.util-linux}/bin/eject /dev/%k"
      ACTION=="add", SUBSYSTEM=="block", ENV{DEVTYPE}=="disk", KERNEL=="sd*", ATTRS{idVendor}=="a69c", ATTRS{idProduct}=="5725", RUN+="${pkgs.util-linux}/bin/eject /dev/%k"
      ACTION=="add", SUBSYSTEM=="block", ENV{DEVTYPE}=="disk", KERNEL=="sd*", ATTRS{idVendor}=="a69c", ATTRS{idProduct}=="5726", RUN+="${pkgs.util-linux}/bin/eject /dev/%k"
      ACTION=="add", SUBSYSTEM=="block", ENV{DEVTYPE}=="disk", KERNEL=="sd*", ATTRS{idVendor}=="a69c", ATTRS{idProduct}=="5727", RUN+="${pkgs.util-linux}/bin/eject /dev/%k"
      ACTION=="add", SUBSYSTEM=="block", ENV{DEVTYPE}=="disk", KERNEL=="sd*", ATTRS{idVendor}=="a69c", ATTRS{idProduct}=="572a", RUN+="${pkgs.util-linux}/bin/eject /dev/%k"
      ACTION=="add", SUBSYSTEM=="block", ENV{DEVTYPE}=="disk", KERNEL=="sd*", ATTRS{idVendor}=="a69c", ATTRS{idProduct}=="572c", RUN+="${pkgs.util-linux}/bin/eject /dev/%k"
      EOF
      runHook postInstall
    '';
  };

  singBoxSyncConfig = pkgs.writeShellApplication {
    name = "singbox-sync-config";
    runtimeInputs = with pkgs; [ coreutils curl python3 sing-box systemd ];
    text = ''
      set -euo pipefail

      stateDir=/var/lib/sing-box
      subscriptionsDir="$stateDir/subscriptions"
      subscriptionsFile="$subscriptionsDir/list.txt"
      secretFile="$stateDir/ui-secret"
      outputConfig="$stateDir/config.json"

      mkdir -p "$subscriptionsDir"
      touch "$subscriptionsFile"
      chmod 600 "$subscriptionsFile"

      if [ ! -s "$secretFile" ]; then
        tr -dc 'A-Za-z0-9' < /dev/urandom | head -c 32 > "$secretFile"
        echo >> "$secretFile"
      fi
      chmod 600 "$secretFile"
      secret="$(tr -d '\n' < "$secretFile")"

      workDir="$(mktemp -d)"
      trap 'rm -rf "$workDir"' EXIT

      allOutbounds="$workDir/outbounds.json"
      echo '[]' > "$allOutbounds"

      while IFS= read -r rawUrl || [ -n "$rawUrl" ]; do
        url="$(printf '%s' "$rawUrl" | sed 's/^[[:space:]]*//;s/[[:space:]]*$//')"
        if [ -z "$url" ] || [ "''${url#\#}" != "$url" ]; then
          continue
        fi

        sourcePayload="$workDir/sub-$(printf '%s' "$url" | sha256sum | cut -d' ' -f1).payload"
        if ! curl --fail --silent --show-error --location "$url" --output "$sourcePayload"; then
          echo "[sing-box] skip unreachable subscription: $url" >&2
          continue
        fi

        if ! python3 - "$sourcePayload" "$allOutbounds" <<'PY'
import base64
import json
import re
import sys
from urllib.parse import parse_qs, unquote, urlsplit


def decode_base64(data: str):
    compact = re.sub(r"\s+", "", data)
    if not compact:
        return None
    padding = "=" * ((4 - len(compact) % 4) % 4)
    for decoder in (base64.b64decode, base64.urlsafe_b64decode):
        try:
            return decoder((compact + padding).encode("utf-8")).decode("utf-8", errors="ignore")
        except Exception:
            continue
    return None


def parse_bool(value: str):
    return value.lower() in {"1", "true", "yes", "on"}


def parse_port(value: str, default: int):
    try:
        return int(value)
    except Exception:
        return default


def parse_vmess(uri: str, idx: int):
    raw = uri[len("vmess://"):]
    decoded = decode_base64(raw)
    if not decoded:
        return None
    try:
        node = json.loads(decoded)
    except Exception:
        return None

    server = node.get("add") or node.get("server")
    if not server:
        return None

    outbound = {
        "type": "vmess",
        "tag": node.get("ps") or f"vmess-{idx}",
        "server": server,
        "server_port": parse_port(str(node.get("port", "0")), 443),
        "uuid": node.get("id", ""),
        "security": "auto",
        "alter_id": parse_port(str(node.get("aid", "0")), 0),
    }

    network = str(node.get("net", "tcp") or "tcp").lower()
    if network != "tcp":
        outbound["transport"] = {"type": network}

    host = node.get("host")
    path = node.get("path")
    if network == "ws":
        transport = {"type": "ws"}
        if path:
            transport["path"] = path
        if host:
            transport["headers"] = {"Host": host}
        outbound["transport"] = transport

    tls_mode = str(node.get("tls", "") or "").lower()
    if tls_mode in {"tls", "reality", "1", "true"}:
        tls = {"enabled": True}
        sni = node.get("sni") or host
        if sni:
            tls["server_name"] = sni
        outbound["tls"] = tls

    if not outbound.get("uuid"):
        return None
    return outbound


def parse_standard_uri(uri: str, scheme: str, idx: int):
    split = urlsplit(uri)
    if not split.hostname:
        return None

    query = parse_qs(split.query)
    tag = unquote(split.fragment) if split.fragment else f"{scheme}-{idx}"

    if scheme == "ss":
        raw = uri[len("ss://"):]
        raw = raw.split("#", 1)[0]
        raw = raw.split("?", 1)[0]
        if "@" in raw:
            userinfo, hostpart = raw.rsplit("@", 1)
        else:
            decoded = decode_base64(raw)
            if not decoded or "@" not in decoded:
                return None
            userinfo, hostpart = decoded.rsplit("@", 1)
        if ":" not in userinfo:
            return None
        method, password = userinfo.split(":", 1)
        host = split.hostname or hostpart.split(":", 1)[0]
        port = split.port
        if port is None and ":" in hostpart:
            port = parse_port(hostpart.rsplit(":", 1)[1], 8388)
        return {
            "type": "shadowsocks",
            "tag": tag,
            "server": host,
            "server_port": parse_port(str(port or 8388), 8388),
            "method": method,
            "password": password,
        }

    base = {
        "tag": tag,
        "server": split.hostname,
        "server_port": parse_port(str(split.port or 443), 443),
    }

    username = unquote(split.username or "")

    if scheme == "vless":
        if not username:
            return None
        outbound = {
            **base,
            "type": "vless",
            "uuid": username,
            "flow": query.get("flow", [""])[0] or "",
        }
    elif scheme == "trojan":
        if not username:
            return None
        outbound = {
            **base,
            "type": "trojan",
            "password": username,
        }
    elif scheme == "anytls":
        if not username:
            return None
        outbound = {
            **base,
            "type": "anytls",
            "password": username,
        }
    elif scheme in {"hysteria", "hysteria2"}:
        outbound = {
            **base,
            "type": "hysteria2",
            "password": username,
        }
    else:
        return None

    transport_type = (query.get("type", [""])[0] or "").lower()
    if transport_type and transport_type != "tcp":
        outbound["transport"] = {"type": transport_type}
        if transport_type == "ws":
            path = query.get("path", [""])[0]
            host = query.get("host", [""])[0]
            if path:
                outbound["transport"]["path"] = path
            if host:
                outbound["transport"]["headers"] = {"Host": host}

    security = (query.get("security", [""])[0] or "").lower()
    if security in {"tls", "reality"} or scheme in {"anytls", "trojan", "hysteria", "hysteria2"}:
        tls = {"enabled": True}
        sni = query.get("sni", [""])[0] or split.hostname
        if sni:
            tls["server_name"] = sni
        insecure = query.get("allowInsecure", [""])[0] or query.get("insecure", [""])[0]
        if insecure and parse_bool(insecure):
            tls["insecure"] = True
        outbound["tls"] = tls

    return outbound


SUPPORTED = {"vmess", "vless", "trojan", "anytls", "hysteria", "hysteria2", "ss"}
ALLOWED_TYPES = {
    "anytls", "direct", "http", "hysteria", "hysteria2",
    "shadowsocks", "socks", "ssh", "tor", "trojan",
    "tuic", "vless", "vmess", "wireguard",
}
RESERVED_TAGS = {"proxy", "auto", "direct"}


def payload_to_lines(raw_bytes: bytes):
    text = raw_bytes.decode("utf-8", errors="ignore").strip()
    if not text:
        return []

    lines = [l.strip() for l in text.splitlines() if l.strip() and not l.strip().startswith("#")]
    if lines and all("://" in l for l in lines):
        return lines

    decoded = decode_base64(text)
    if not decoded:
        return []

    return [l.strip() for l in decoded.splitlines() if l.strip() and not l.strip().startswith("#")]


def main():
    source_payload = sys.argv[1]
    existing_outbounds_file = sys.argv[2]

    with open(source_payload, "rb") as fh:
        raw = fh.read()

    lines = payload_to_lines(raw)
    if not lines:
        print("[sing-box] no URI lines found in subscription payload", file=sys.stderr)
        return 1

    with open(existing_outbounds_file, "r") as fh:
        existing = json.load(fh)

    new_outbounds = []
    for idx, line in enumerate(lines, start=1):
        scheme = line.split("://", 1)[0].lower() if "://" in line else ""
        if scheme not in SUPPORTED:
            continue
        if scheme == "vmess":
            ob = parse_vmess(line, idx)
        else:
            ob = parse_standard_uri(line, scheme, idx)
        if not ob:
            continue
        if ob.get("type", "").lower() not in ALLOWED_TYPES:
            continue
        if not ob.get("tag"):
            continue
        if ob["tag"] in RESERVED_TAGS:
            ob["tag"] = f"{ob['tag']}-{idx}"
        new_outbounds.append(ob)

    # Deduplicate by tag, keeping first occurrence
    seen_tags = set()
    for ob in existing:
        seen_tags.add(ob.get("tag"))

    for ob in new_outbounds:
        if ob["tag"] not in seen_tags:
            existing.append(ob)
            seen_tags.add(ob["tag"])

    with open(existing_outbounds_file, "w", encoding="utf-8") as fh:
        json.dump(existing, fh, ensure_ascii=False)

    return 0


if __name__ == "__main__":
    raise SystemExit(main())
PY
        then
          echo "[sing-box] skip unsupported subscription payload format: $url" >&2
          continue
        fi
      done < "$subscriptionsFile"

      # Build proxy tag list (all provider outbound tags except reserved names)
      proxyTags="$(python3 -c "
import json, sys
obs = json.load(open(sys.argv[1]))
tags = [o['tag'] for o in obs if o.get('tag') not in {'proxy','auto','direct'}]
json.dump(tags, sys.stdout)
" "$allOutbounds")"

      # Generate sing-box 1.12+ config via Python (no jq needed)
      generated="$workDir/config.json"
      python3 - "$allOutbounds" "$secret" "$generated" <<'PYGEN'
import json
import sys

outbounds_file = sys.argv[1]
secret = sys.argv[2]
output_file = sys.argv[3]

with open(outbounds_file) as fh:
    provider_outbounds = json.load(fh)

proxy_tags = [
    o["tag"] for o in provider_outbounds
    if o.get("tag") not in {"proxy", "auto", "direct"}
]

# Build outbounds list
outbounds = list(provider_outbounds)

# selector: proxy
selector_outbounds = list(dict.fromkeys(proxy_tags + ["auto", "direct"]))
outbounds.append({
    "type": "selector",
    "tag": "proxy",
    "outbounds": selector_outbounds,
})

# urltest: auto
if proxy_tags:
    outbounds.append({
        "type": "urltest",
        "tag": "auto",
        "outbounds": list(dict.fromkeys(proxy_tags)),
        "interval": "10m",
        "tolerance": 50,
    })

# direct outbound
outbounds.append({"type": "direct", "tag": "direct"})

config = {
    "log": {
        "level": "info",
        "timestamp": True,
    },
    "dns": {
        "servers": [
            {
                "type": "https",
                "tag": "dns-remote",
                "server": "1.1.1.1",
                "detour": "proxy",
            },
            {
                "type": "https",
                "tag": "dns-direct",
                "server": "223.5.5.5",
                "detour": "direct",
            },
        ],
        "rules": [
            {
                "clash_mode": "Direct",
                "action": "route",
                "server": "dns-direct",
            },
            {
                "clash_mode": "Global",
                "action": "route",
                "server": "dns-remote",
            },
        ],
        "final": "dns-remote",
    },
    "inbounds": [
        {
            "type": "tun",
            "tag": "tun-in",
            "interface_name": "singtun0",
            "address": ["172.19.0.1/30"],
            "mtu": 9000,
            "stack": "system",
            "auto_route": True,
            "strict_route": True,
            "auto_redirect": True,
            "endpoint_independent_nat": True,
        }
    ],
    "outbounds": outbounds,
    "route": {
        "auto_detect_interface": True,
        "final": "proxy",
        "rules": [
            {
                "protocol": "dns",
                "action": "hijack-dns",
            },
            {
                "ip_is_private": True,
                "outbound": "direct",
            },
            {
                "clash_mode": "Direct",
                "outbound": "direct",
            },
            {
                "clash_mode": "Global",
                "outbound": "proxy",
            },
        ],
    },
    "experimental": {
        "cache_file": {
            "enabled": True,
            "path": "/var/lib/sing-box/cache.db",
            "store_fakeip": True,
        },
        "clash_api": {
            "external_controller": "0.0.0.0:9090",
            "secret": secret,
            "default_mode": "Rule",
            "access_control_allow_origin": [
                "http://127.0.0.1:9099",
                "http://localhost:9099",
                "http://srcres-orange-pi:9099",
            ],
            "access_control_allow_private_network": True,
        },
    },
}

with open(output_file, "w", encoding="utf-8") as fh:
    json.dump(config, fh, indent=2, ensure_ascii=False)
PYGEN

      if sing-box check -c "$generated"; then
        install -o sing-box -g sing-box -m 600 "$generated" "$outputConfig"
        echo "[sing-box] config installed successfully with $(echo "$proxyTags" | python3 -c "import json,sys; print(len(json.load(sys.stdin)))" 2>/dev/null || echo '?') proxies"
      else
        echo "[sing-box] generated config failed validation; keep previous config" >&2
        exit 1
      fi
    '';
  };
in {
  imports = [
    ./hardware-configuration.nix
  ];

  # Ensure NVMe root-on-SSD is discoverable in stage-1 initrd on RK3588.
  # Force deterministic module inclusion/load order and add active reprobe loop
  # because the PCIe/NVMe link can come up late on this board.
  boot.initrd.availableKernelModules = lib.mkForce [
    # PCIe controller + combo PHY required to bring the NVMe link up on RK3588S.
    "pcie_rockchip_host"
    "phy_rockchip_naneng_combphy"
    "pci"
    "nvme_core"
    "nvme"
    # crc32c hash is required by btrfs for data checksum and is a loadable
    # module on this kernel; without it mount fails with ENOENT.
    "crc32c_cryptoapi"
    "dm_mod"
    "btrfs"
    "vfat"
    "nls_cp437"
    "nls_iso8859_1"
    "xhci_pci"
    "mmc_block"
    "sd_mod"
    "usb_storage"
  ];
  # Keep default initrd modules enabled to avoid missing core block/udev helpers
  # during early boot discovery on RK3588.
  boot.initrd.includeDefaultModules = lib.mkForce true;
  boot.initrd.kernelModules = lib.mkForce [ "phy_rockchip_naneng_combphy" "pcie_rockchip_host" "pci" "nvme_core" "nvme" "crc32c_cryptoapi" "dm_mod" "btrfs" ];
  boot.kernelModules = [
    "pcie_rockchip_host"
    "nvme"
    "nvme_core"
    "tun"
    "aic_load_fw"
    "aic8800_fdrv"
  ];
  # AICSemi driver reads firmware via aic_load_fw module parameter aic_fw_path.
  # On NixOS firmware lives under /run/current-system/firmware.
  boot.extraModprobeConfig = ''
    options aic_load_fw aic_fw_path=/run/current-system/firmware
  '';
  boot.extraModulePackages = [ aic8800d80 ];
  boot.initrd.postDeviceCommands = ''
    rootUuid="1aab64c8-3fe8-46f4-8aff-124f2ea7868d"

    for _ in $(seq 1 45); do
      if [ -e /sys/bus/pci/rescan ]; then
        echo 1 > /sys/bus/pci/rescan
      fi

      modprobe phy_rockchip_naneng_combphy >/dev/null 2>&1 || true
      modprobe pcie_rockchip_host >/dev/null 2>&1 || true
      modprobe pci >/dev/null 2>&1 || true
      modprobe nvme_core >/dev/null 2>&1 || true
      modprobe nvme >/dev/null 2>&1 || true
      modprobe dm_mod >/dev/null 2>&1 || true
      modprobe btrfs >/dev/null 2>&1 || true
      modprobe mmc_block >/dev/null 2>&1 || true
      modprobe sd_mod >/dev/null 2>&1 || true
      modprobe usb_storage >/dev/null 2>&1 || true

      if command -v udevadm >/dev/null 2>&1; then
        udevadm trigger --subsystem-match=pci --action=add || true
        udevadm trigger --subsystem-match=nvme --action=add || true
        udevadm trigger --subsystem-match=block --action=add || true
        udevadm settle --timeout=3 || true
      fi

      # Ensure by-uuid links are materialized from current udev state first.
      mkdir -p /dev/disk/by-uuid
      if [ -d /run/udev/data ] && command -v sed >/dev/null 2>&1; then
        for meta in /run/udev/data/b*; do
          [ -f "$meta" ] || continue
          devname="$(sed -n 's/^N://p' "$meta" | head -n 1)"
          uuid="$(sed -n 's/^E:ID_FS_UUID=//p' "$meta" | head -n 1)"
          if [ -n "$devname" ] && [ -n "$uuid" ] && [ -b "/dev/$devname" ]; then
            ln -sf "/dev/$devname" "/dev/disk/by-uuid/$uuid"
          fi
        done
      fi

      # Fallback probe with blkid if udev metadata is incomplete.
      if command -v blkid >/dev/null 2>&1; then
        for dev in /dev/nvme*n* /dev/mmcblk*p* /dev/sd*; do
          if [ -b "$dev" ]; then
            uuid="$(blkid -s UUID -o value "$dev" 2>/dev/null || true)"
            if [ -n "$uuid" ]; then
              ln -sf "$dev" "/dev/disk/by-uuid/$uuid"
            fi
          fi
        done
      fi

      if [ -e "/dev/disk/by-uuid/$rootUuid" ]; then
        break
      fi

      sleep 1
    done

    if [ ! -e "/dev/disk/by-uuid/$rootUuid" ]; then
      echo "[initrd] root UUID still missing: $rootUuid"
    fi
  '';
  boot.kernelParams = lib.mkAfter [
    "root=UUID=1aab64c8-3fe8-46f4-8aff-124f2ea7868d"
    "rootwait"
    "rootdelay=60"
    "rootfstype=btrfs"
    "console=tty0"
    "earlycon"
  ];

  # The NVMe index can change across boots on RK3588. Prefer UUID-based root
  # lookup and recreate by-uuid symlinks in stage-1 if udev is late.
  fileSystems."/".device = lib.mkForce "/dev/disk/by-uuid/1aab64c8-3fe8-46f4-8aff-124f2ea7868d";
  fileSystems."/home".device = lib.mkForce "/dev/disk/by-uuid/1aab64c8-3fe8-46f4-8aff-124f2ea7868d";
  fileSystems."/nix".device = lib.mkForce "/dev/disk/by-uuid/1aab64c8-3fe8-46f4-8aff-124f2ea7868d";
  fileSystems."/boot".device = lib.mkForce "/dev/disk/by-uuid/3A12-AB1C";
  swapDevices = lib.mkForce [ { device = "/dev/disk/by-uuid/b439618d-cd52-4bc9-8509-c327a3c026aa"; } ];

  networking = {
    hostName = "srcres-orange-pi";

    # Keep device behavior consistent with other hosts in this repository.
    networkmanager.enable = true;
    nftables.enable = true;
    firewall.enable = false;

  };

  # sing-box TUN transparent proxy requires forwarding for routed traffic.
  boot.kernel.sysctl = {
    "net.ipv4.ip_forward" = 1;
    "net.ipv6.conf.all.forwarding" = 1;
  };

  environment.systemPackages = with pkgs; [
    sing-box
    metacubexd
    singBoxSyncConfig
  ];

  services.sing-box = {
    enable = true;
    settings = {
      log = {
        level = "info";
        timestamp = true;
      };
      dns = {
        servers = [
          {
            type = "https";
            tag = "dns-remote";
            server = "1.1.1.1";
            detour = "proxy";
          }
          {
            type = "https";
            tag = "dns-direct";
            server = "223.5.5.5";
            detour = "direct";
          }
        ];
        rules = [
          {
            clash_mode = "Direct";
            action = "route";
            server = "dns-direct";
          }
          {
            clash_mode = "Global";
            action = "route";
            server = "dns-remote";
          }
        ];
        final = "dns-remote";
      };
      inbounds = [
        {
          type = "tun";
          tag = "tun-in";
          interface_name = "singtun0";
          address = [ "172.19.0.1/30" ];
          mtu = 9000;
          stack = "system";
          auto_route = true;
          strict_route = true;
          auto_redirect = true;
          endpoint_independent_nat = true;
        }
      ];
      outbounds = [
        {
          type = "selector";
          tag = "proxy";
          outbounds = [ "direct" ];
        }
        {
          type = "direct";
          tag = "direct";
        }
      ];
      route = {
        auto_detect_interface = true;
        final = "proxy";
        rules = [
          {
            protocol = "dns";
            action = "hijack-dns";
          }
          {
            ip_is_private = true;
            outbound = "direct";
          }
          {
            clash_mode = "Direct";
            outbound = "direct";
          }
          {
            clash_mode = "Global";
            outbound = "proxy";
          }
        ];
      };
      experimental = {
        cache_file = {
          enabled = true;
          path = "/var/lib/sing-box/cache.db";
          store_fakeip = true;
        };
        clash_api = {
          external_controller = "0.0.0.0:9090";
          secret = "replace-after-bootstrap";
          default_mode = "Rule";
          access_control_allow_origin = [
            "http://127.0.0.1:9099"
            "http://localhost:9099"
            "http://srcres-orange-pi:9099"
          ];
          access_control_allow_private_network = true;
        };
      };
    };
  };

  services.nginx = {
    enable = true;
    virtualHosts."srcres-orange-pi" = {
      default = true;
      listen = [
        {
          addr = "0.0.0.0";
          port = 9099;
        }
      ];
      root = "${pkgs.metacubexd}";
      locations."/" = {
        index = "index.html";
        tryFiles = "$uri $uri/ /index.html";
      };
    };
  };

  systemd.tmpfiles.rules = [
    "d /var/lib/sing-box 0700 sing-box sing-box -"
    "d /var/lib/sing-box/subscriptions 0700 root root -"
    "f /var/lib/sing-box/subscriptions/list.txt 0600 root root -"
  ];

  systemd.services.singbox-sync = {
    description = "Generate runtime sing-box config from subscription list";
    after = [ "network-online.target" ];
    wants = [ "network-online.target" ];
    before = [ "sing-box.service" ];
    serviceConfig = {
      Type = "oneshot";
      User = "root";
      Group = "root";
      ExecStart = "${singBoxSyncConfig}/bin/singbox-sync-config";
    };
    wantedBy = [ "multi-user.target" ];
  };

  systemd.timers.singbox-sync = {
    wantedBy = [ "timers.target" ];
    timerConfig = {
      OnBootSec = "5min";
      OnUnitActiveSec = "1h";
      Unit = "singbox-sync.service";
    };
  };

  # Ensure runtime-generated config and secret override module defaults.
  systemd.services.sing-box = {
    after = [ "singbox-sync.service" ];
    wants = [ "singbox-sync.service" ];
    serviceConfig = {
      # In systemd drop-ins, ExecStart appends unless explicitly reset first.
      # Without the empty entry, we end up with two ExecStart lines and
      # systemd marks the unit as bad-setting (non-oneshot services allow one).
      ExecStart = lib.mkForce [
        ""
        "${pkgs.sing-box}/bin/sing-box run -c /var/lib/sing-box/config.json"
      ];
      Restart = "always";
      RestartSec = 2;
      CapabilityBoundingSet = [ "CAP_NET_ADMIN" "CAP_NET_BIND_SERVICE" ];
      AmbientCapabilities = [ "CAP_NET_ADMIN" "CAP_NET_BIND_SERVICE" ];
      ReadWritePaths = [ "/var/lib/sing-box" ];
    };
  };

  # Orange Pi 5 normally runs headless for infra/dev workloads.
  services.openssh = {
    enable = true;
    settings = {
      PasswordAuthentication = true;
      PermitRootLogin = "yes";
      X11Forwarding = true;
    };
    openFirewall = true;
  };

  # Keep ARM-specific graphics path explicit and minimal.
  hardware.graphics.enable = true;

  # AIC8800D80 USB Wi-Fi driver (aic8800_fdrv + aic_load_fw) and firmware.
  # This out-of-tree driver requests raw .bin/.txt filenames via request_firmware
  # and does not resolve NixOS-compressed .zst firmware paths.
  hardware.firmwareCompression = "none";
  hardware.firmware = [ aic8800d80Firmware ];
  services.udev.packages = [ aic8800d80Firmware ];

  # This option defines the first version of NixOS installed on this host.
  system.stateVersion = "25.11";
}
