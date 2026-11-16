# AGENTS.md

Personal NixOS / Home Manager flake. Only repo-specific facts an agent would likely miss.

## Repo map

- `flake.nix` is the entrypoint. Outputs:
  - NixOS hosts: `srcres-desktop`, `srcres-laptop`, `srcres-desktop-x99`, `srcres-wsl` (all `x86_64-linux`), `srcres-orange-pi` and `srcres-rpi` (`aarch64-linux`).
  - Home Manager: `homeConfigurations."srcres@<host>"`.
  - Dev shell: `packages.${system}.srcres` (uses `home/develop.nix`, **no** graphical modules).
- `configuration.nix` (repo root) is the shared NixOS base (user, timezone, fonts, nix settings, base services). It does NOT import any host or platform modules itself.
- Per-host layering for NixOS: `./configuration.nix` + `platforms/<platform>/configuration.nix` + `devices/<host>/configuration.nix`.
  - `srcres-rpi` is the exception: it passes `withBase = false` to `mkNixOSConfig`, so the shared desktop base is skipped and `devices/srcres-rpi/configuration.nix` defines the whole minimal system (user, SSH, nix settings, package list) on top of `nixos-hardware`'s `raspberry-pi-4` module.
- Per-host layering for Home Manager: `./home` + `platforms/<platform>/home` + `devices/<host>/home`.
- Home split:
  - `home/pure/` = cross-platform user tools (fish, neovim, git, gh, fzf, ripgrep, eza, fonts, etc.).
  - `home/system/` = GUI/desktop-oriented tools and applications (kitty, firefox, fcitx5, waybar, qutebrowser, KDE apps). It is imported by `home/default.nix`, so every `mkHomeConfig` host currently loads it, including `srcres-desktop-x99` and `srcres-orange-pi`.
  - `home/develop.nix` = pure-only profile intended for the `packages.srcres` dev env; it does not load `home/system/`, platform home modules, or device home modules.
  - WSL and `srcres-rpi` are the exceptions: `mkPureHomeConfig` in `flake.nix` skips `./home` and loads only `./home/pure` plus the device home module (no `home/system/` or platform home).
- `modules/virtualization/windows-vm/*` referenced by README no longer exist locally (removed in commit `b2313fa`); README is stale. Ignore any `vmctl` instructions.

## Commands

Run from repo root.

- Verify flake (fast): `nix flake check --no-build` — catches option/type errors without building derivations. Run this first.
- Verify flake (full): `nix flake check`.
- Build a system: `nix build .#nixosConfigurations.<host>.config.system.build.toplevel`.
- Build a home: `nix build .#homeConfigurations."srcres@<host>".activationPackage`.
- Build the dev env: `nix build .#srcres`.
- Update a single legacy-pinned input: `nix flake lock --update-input <name>` (preferred over `nix flake update`).
- Format touched Nix files: `nixpkgs-fmt`.
- Build an aarch64 host image on this x86_64 desktop: `nix build .#nixosConfigurations.srcres-rpi.config.system.build.sdImage` (needs `aarch64-linux` in `extra-platforms` plus binfmt; `platforms/native/configuration.nix` provides the binfmt side, so the desktop qualifies).
- Deploy to a board over ssh, building here and activating there (no `--build-host` means "build on the machine running nixos-rebuild"):

  ```sh
  nixos-rebuild switch --flake .#srcres-rpi \
      --target-host srcres@srcres-rpi --sudo --ask-sudo-password
  ```

  Use `--build-host srcres@srcres-rpi` instead when the board should build natively (faster than qemu for big builds, but loads the Pi).

## CI / binary cache

- `.github/workflows/cache-aarch64.yml` pre-builds the aarch64-only workloads on `ubuntu-24.04-arm` and pushes them to the `srcres-nixos-config` Cachix cache. It needs the `CACHIX_AUTH_TOKEN` secret plus a cache of that name; Cachix skips paths already on `cache.nixos.org`, and the free tier is 5 GiB compressed.
- Matrix targets: `homeConfigurations."srcres@{orange-pi,rpi}".activationPackage` and the `system.build.toplevel` of both aarch64 hosts. The toplevel matters, not just `system.build.kernel`: `modules-shrunk` and the initrd are host-specific derivations that only exist once the toplevel is built, and they are where a vendor kernel missing modules listed by `hardware/all-hardware.nix` fails.
- Only aarch64 is cached, deliberately. Measured on this repo: `srcres-desktop`'s 1467-path system closure has 144 uncovered paths totalling 219 MiB, almost all generated `unit-*.service`, `X-Restart-Triggers-*` and `*-fish-completions` that rebuild in seconds — a personal cache buys nothing for x86_64 systems. The aarch64 home configs need ~763 derivations built from source (NUR Rust crates have no aarch64 output in the NUR cache), and `linux-rpi` is in no upstream cache at all.
- The job moves the Nix store onto `/mnt` with `wimpysworld/nothing-but-nix`, because the stock arm64 runner disk cannot hold a kernel build plus a few hundred crate builds.
- CI does **not** run `nix flake check`: evaluating `packages.x86_64-linux.srcres` reads a `Cargo.lock` through import-from-derivation, and a `--no-build` check will not realise that source path on a cold store (`error: path ... is not valid`). It passes locally only because the path is already in the store. The verify job evaluates each host's `system.build.toplevel` derivation instead, plus builds the WSL pure home.
- Client side is the `srcres-nixos-config` entry in `nix.settings.extra-substituters` / `extra-trusted-public-keys`, present in both `configuration.nix` and `devices/srcres-rpi/configuration.nix` (the public key comes from `curl -s https://cachix.org/api/v1/cache/srcres-nixos-config`, not from `cachix use` — NixOS owns `/etc/nix/nix.conf`).

## Gotchas

- No pre-commit, no task runner. `nix flake check` plus the CI workflow above are the source of truth.
- NUR comes in through `nur.overlays.default` in `mkPkgs` (`flake.nix`), so `pkgs.nur.repos.<user>` resolves against the revisions pinned in the `nur` input's `repos.json.lock`. `homeManagerConfiguration` receives an explicit `pkgs` and re-injects that pkgs' overlays after the module-defined ones, so a `nixpkgs.overlays` entry declared inside a home module cannot override `nur`.
- The flake is pure: no `builtins.getEnv`, so `nix build` and `nixos-rebuild` need no `--impure`. The one input that used to be impure is the user password, now `users.users.srcres.hashedPasswordFile = "/var/lib/nixos/secrets/srcres.passwd"` (in `configuration.nix`, and again in `devices/srcres-rpi/configuration.nix` for the host that skips the base).
  - `hashedPasswordFile` (type `str`) is read by `update-users-groups.pl` at activation time, not evaluation time, so the hash never enters the Nix store and CI and local builds derive the same closure. A missing file only yields a warning and the account keeps its current password.
  - Bootstrapping a fresh machine: `sudo install -d -m 0700 /var/lib/nixos/secrets` then `mkpasswd -m yescrypt | sudo tee /var/lib/nixos/secrets/srcres.passwd`; or log in on the console and run `passwd` once. `users.mutableUsers` is true, so any password option only applies when the account is created.
- `hardware-configuration.nix` files are generated by `nixos-generate-config`; do not hand-edit. The `Do not modify this file!` header is real.
- `system.stateVersion` / `home.stateVersion` are per-host and per-home; do not bump casually. Current values: `srcres-desktop` = `25.05` system / `25.05` home, `srcres-wsl` = `25.11` / `25.05`, `srcres-laptop` = `25.11` / `25.05`, `srcres-desktop-x99` = `26.05` / `26.05`, `srcres-orange-pi` = `25.11` / `25.11`, `srcres-rpi` = `26.05` / `26.05`, `packages.srcres` = `25.11`.
- Orange Pi 5 (RK3588s) specifics in `devices/srcres-orange-pi/configuration.nix` and `platforms/orangepi/configuration.nix`:
  - `boot.kernelPackages = pkgs.linuxPackages_latest` (NOT `linux_zen`), with an extlinux-compatible bootloader configuration.
  - Initrd workarounds: forced `boot.initrd.availableKernelModules` / `kernelModules`, a custom `nvme-rescan` systemd service that loops PCIe rescans for ~45s, and an `ensure-sysroot-run` service to create `/sysroot/run` before bind mount. Do not "clean these up" without keeping them — RK3588S PCIe/NVMe link comes up late.
  - The current configuration does not contain the previously used out-of-tree `aic8800d80` Wi-Fi driver, GitHub-fetched firmware, or `hardware.firmwareCompression = "none"` workaround.
  - Other ARM-specific behavior includes NetworkManager+iwd Wi-Fi settings, headless SSH access, disabled firewall, and PipeWire with Pulse and ALSA support.
- `platforms/native/configuration.nix` is imported by `srcres-desktop` and `srcres-laptop`; it enables systemd-boot, `pkgs.linuxKernel.packages.linux_zen`, and `boot.binfmt.emulatedSystems = [ "aarch64-linux" "riscv64-linux" ]`. `srcres-desktop-x99` independently sets systemd-boot and `linux_zen`, but does not import the native platform module or inherit its binfmt settings.
- WSL host imports `nixos-wsl.nixosModules.default`; WSL config is in `devices/srcres-wsl/configuration.nix`.
- Login and desktop stack: `programs.niri.enable = true` and the `xwayland-satellite` package are enabled in the base configuration. The native and Orange Pi platform modules enable `services.greetd` with `tuigreet`; WSL and `srcres-desktop-x99` do not receive those platform settings. Native additionally enables `programs.river-classic` with `pkgs.river`. Native PipeWire enables Pulse, while Orange Pi additionally enables ALSA and 32-bit ALSA support.
- `nix.channel.enable = false` — flakes only.
- Substituters / trusted-public-keys: Tsinghua + USTC mirrors (`nix.settings.substituters`), plus `https://yazi.cachix.org` and `https://nur-packages-srcres258.cachix.org` (`nix.settings.extra-substituters`). `trusted-users` includes `root` and `srcres`.
- `users.users.srcres` extra groups: `wheel networkmanager audio video render docker wireshark i2c input`. Shell is `pkgs.fish`.
- `home/develop.nix` is loaded **only** for the dev env, not for any host. `packages.srcres` will not pick up changes to `home/system/` or platform/device home modules.
- `nix flake check --no-build` does **not** evaluate `homeConfigurations` (non-standard output, and its values are not derivations), so a broken pure-home config only surfaces via `nix build .#homeConfigurations."srcres@<host>".activationPackage`. The WSL pure home is the one to watch.
- aarch64 hosts are **not cross-compiled**: `mkNixOSConfig` does `import nixpkgs { system = "aarch64-linux"; }`, so on an x86_64 machine the aarch64 stdenv runs through binfmt/qemu. Measured on zstd (forced rebuild): 5m11s via qemu vs 1m36s for a real `crossSystem` build — but cross would invalidate every `cache.nixos.org` aarch64 path, so the qemu route is deliberate. Nothing declares `nix.buildMachines`/`nix.distributedBuilds`.
- Cache reality for the aarch64 hosts (checked with `nix path-info --store https://cache.nixos.org`):
  - `linux-rpi` (the nixos-hardware vendor kernel) is **not** cached → the SD image always compiles a kernel. `ubootRaspberryPiAarch64`, `linuxPackages_latest`, `coq`, `ghc`, `electron`, `nodejs_24`, `firefox` are all cached.
  - `thunderbird` sets `meta.hydraPlatforms = [ ]`, so it is never substituted on **any** platform; `home/pure` now ships it only when `!isAarch64`.
  - The `nur.repos.srcres258` Rust tools (`bibox`, `waveql`, `sootty`, `docx-cli`, `adif-manage`, `jyyslide-util`) have no aarch64 output in the NUR cachix, so `home/pure` pulls ~292 vendored crate builds on aarch64. `home/pure`'s `texlive`/`coq`/`python.withPackages` results are cheap link trees; their dependencies come from cache.
- `srcres-rpi` (Raspberry Pi 4B) comes from the `nixos-hardware` input (`nixosModules.raspberry-pi-4`) plus nixpkgs' `sd-image-aarch64.nix`, imported by path (`"${inputs.nixpkgs}/nixos/modules/installer/sd-card/sd-image-aarch64.nix"`). Build the card image with `nix build .#nixosConfigurations.srcres-rpi.config.system.build.sdImage`.
  - The Pi GPU firmware cannot read `extlinux.conf`, so the host sets `hardware.raspberry-pi.firmware = { enable = true; uboot.enable = true; }`: U-Boot is chainloaded from the FAT partition, and the firmware partition is repopulated on every `nixos-rebuild switch`.
  - The profile defaults to the vendor `linux-rpi` kernel built from source, which is **not** in any binary cache — a full image build therefore compiles a kernel. Setting `boot.kernelPackages = pkgs.linuxPackages_latest;` (commented out in the device config) uses a cached mainline kernel instead.
  - The host sets `boot.supportedFilesystems.zfs = lib.mkForce false` and does not load the shared base; keep it that way unless the extra weight is wanted.
  - `/boot/firmware` is mounted from `sd-image-aarch64.nix` with `noauto`, which makes the firmware activation script a no-op (it checks `mountpoint -q`). The device config `mkForce`s the options to `[ "nofail" "noatime" ]`; do not drop that override.
  - `boot.initrd.availableKernelModules` disables 13 modules that `nixos/modules/hardware/all-hardware.nix` lists but the vendor `linux-rpi` config does not build (`dw-hdmi`, `dw-mipi-dsi`, `rockchipdrm`, `sun4i-drm`, FireWire, old PATA, ...). Without that, `modules-shrunk` aborts with `modprobe: FATAL: Module dw-hdmi not found in directory .../6.18.50`. Keep them as individual `lib.mkForce false` entries rather than `boot.initrd.allowMissingModules`, so a genuinely missing boot-critical module still fails at build time. Note `modprobe` treats `-` and `_` as equivalent, so compare module names normalised when checking the kernel tree.
  - Because the shared base is not loaded, base settings have to be repeated here when they are wanted, e.g. `programs.nh.enable` (the board had no `nh` for exactly that reason) and `programs.fish.enable`.
  - SD-card write policy (TF card is the only disk): `noatime` on `/` and `/boot/firmware`, `/tmp` on tmpfs (25%), volatile journald (logs in `/run`, `RuntimeMaxUse=64M`), zram swap only (`swapDevices = [ ]`, 25% lz4), `systemd.coredump` off, and `vm.dirty_writeback_centisecs`/`vm.dirty_expire_centisecs` raised to 6000/12000 to batch flushes. Root stays ext4 and `/nix`, `/home`, `/var/lib`, `/etc` are still persistent; there is no tmpfs root or impermanence setup yet. Volatile journald means pre-reboot logs are gone by design.
- `home/pure/default.nix` gates `rocmPackages.rocm-smi` behind `!isAarch64` because it has no aarch64 build; without that gate the pure home cannot be evaluated for `srcres-orange-pi` or `srcres-rpi`.
- Pi Coding Agent is installed as a plain package by `home/pure/pi-coding-agent/default.nix` (`home.packages = [ inputs.pi.packages.${pkgs.system}.default ]`). The upstream `pi` flake exports only `packages` / `apps` / `overlays` — **no** `homeManagerModules` / `nixosModules` — so there is deliberately no local Home Manager module for it. If declarative management of `~/.pi/agent/` config files (`settings.json`, `keybindings.json`, `models.json`, `AGENTS.md`) is wanted again, add it under `home/pure/pi-coding-agent/` rather than reintroducing a separate `home/modules` option module. Extensions are declared through the `piExtensions` attrset in that file, which symlinks store paths into `~/.pi/agent/extensions/` (Pi auto-discovers those and follows symlinks); `~/.pi/agent/settings.json` stays Pi-written, so do not route extensions through `settings.extensions` unless that file becomes Nix-managed on purpose. Current entries: `pi-furry-partner` from `pkgs.nur.repos.srcres258.pi-furry-partner-hd` (NUR, whose lock pins `srcres258/nur-packages` to the branch's latest commit), and `pi-gpt-conv-decode` from `github:srcres258/pi-gpt-conv-decode` package `default`. Pi ignores `pi.themes` / `pi.skills` / `pi.prompts` for a package reached through `extensions/`, so the furry theme is linked separately to `~/.pi/agent/themes/pi-furry-night.json`. The npm extensions stay in `settings.json` `packages` with exact versions (`npm:foo@x.y.z`), which Pi treats as pinned; they are not in `flake.lock` and their dependency tree is still resolved by npm.
- The `modules/virtualization/windows-vm/*` paths in the README no longer exist locally. Do not try to find or rebuild them.
- Ignore `result/`, `result-*`, and `out/`; `result*` are covered by the repository `.gitignore`, while `out/` is currently ignored by an external/global ignore rule rather than `.gitignore`.

## Style

- Nix: 4-space indent, comma-first function args, `let … in …`, `imports = [ … ]` last.
- Prefer `lib.mkDefault`, `lib.mkForce`, `lib.mkAfter` over ad hoc overrides. The Orange Pi initrd config uses these heavily — match that style when extending it.
- Keep embedded shell snippets idempotent (safe to re-run after a rebuild).