# AGENTS.md

Personal NixOS/Home Manager flake. Keep only repo-specific facts an agent would likely miss.

## Repo map
- `flake.nix` is the entrypoint: NixOS hosts `srcres-desktop`, `srcres-laptop`, `srcres-desktop-x99`, `srcres-wsl`, `srcres-orange-pi`; Home Manager configs `srcres@<host>`; dev env `packages.${system}.srcres`.
- `configuration.nix` is the shared NixOS base. Host modules live in `devices/<host>/configuration.nix`; platform modules live in `platforms/native/` and `platforms/orangepi/`.
- `home/default.nix` composes `home/pure` + `home/system`. WSL is the exception: `mkPureHomeConfig` skips `./home` and uses `home/pure` directly.
- Edit OpenCode config only in `home/pure/opencode.nix`; do not touch generated files under `~/.config/opencode/`.

## Commands
- Run from repo root.
- Verification order: `nix flake check --no-build` first, then `nix flake check`.
- System build: `nix build .#nixosConfigurations.<host>.config.system.build.toplevel`
- Home build: `nix build .#homeConfigurations."srcres@<host>".activationPackage`
- Format touched Nix files with `nixpkgs-fmt`.

## Gotchas
- There is no CI / pre-commit / task runner in the repo; flake checks are the source of truth.
- `home/default.nix` imports NUR and fetches `srcres258/nur-packages` via `builtins.fetchTarball`; the first build needs network.
- Use `nix flake lock --update-input <name>` instead of `nix flake update` for legacy pins.
- `SRCRES_PASSWORD` is only consumed by `mkNixOSConfig`.
- `hardware-configuration.nix` files are generated; do not hand-edit them.
- `home.stateVersion` / `system.stateVersion` are per-host; don’t bump casually.
- Orange Pi is `aarch64-linux`; WSL uses `nixos-wsl.nixosModules.default`.
- Native desktops use `systemd-boot`, `linux_zen`, and `boot.binfmt.emulatedSystems = [ "aarch64-linux" "riscv64-linux" ]`; Orange Pi uses `generic-extlinux-compatible`, `linuxPackages_latest`, and extra RK3588/AIC8800D80 boot/firmware workarounds.
- Ignore `result/`, `result-*`, and `out/`.

## Style
- Nix style: 4-space indentation, comma-first function args, `let ... in`, `imports = [ ... ]`.
- Prefer `lib.mkDefault`, `lib.mkForce`, and `lib.mkAfter` over ad hoc overrides.
- Keep embedded shell snippets idempotent.
