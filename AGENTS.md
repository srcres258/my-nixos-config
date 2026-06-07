# AGENTS.md

Personal NixOS/Home Manager flake. Follow these rules to keep changes
safe, consistent, and verifiable.

## 1) Repository Layout

```
flake.nix                                 # Flake entry + factory functions
flake.lock                                # Pinned input versions
configuration.nix                         # Shared base NixOS module (flat, no imports)
home/default.nix                          # Home Manager entry (imports ./pure + ./system)
home/options.nix                          # Custom my.* option declarations
home/develop.nix                          # Standalone dev-only home profile (imports ./pure)
home/pure/                                # Portable home modules (CLI-only, works on WSL)
home/pure/default.nix                     #   Pure module entry — imports sub-modules
home/pure/texlive/                        #   sub-group: TeX Live module
home/pure/yazi/                           #   sub-group: Yazi file manager (Nix + Lua)
home/pure/opencode.nix                    #   OpenCode agent config (via Home Manager)
home/system/                              # System-dependent home modules (GUI, Wayland)
home/system/default.nix                   #   System module entry — imports sub-modules
home/system/waybar.nix                    #   Waybar config (sub-module example)
home/system/qutebrowser/                  #   sub-group: qutebrowser config
platforms/config.kdl                      # Shared Niri compositor config (KDL format)
devices/<host>/configuration.nix          # Per-host system config
devices/<host>/home/default.nix           # Per-host home overlay
devices/<host>/hardware-configuration.nix # Hardware scan (auto-generated; WSL is exception)
platforms/native/                         # Native (physical machine) platform modules
platforms/native/configuration.nix        #   Platform system module
platforms/native/home/                    #   Platform home module
platforms/native/home/vscode.nix          #   VS Code desktop integration
platforms/orangepi/                       # Orange Pi platform modules
platforms/orangepi/configuration.nix      #   Platform system module
platforms/orangepi/home/                  #   Platform home module
```

Primary: **Nix**. Secondary: **Lua** (`home/pure/init.lua`,
`home/pure/yazi/init.lua`), shell snippets, KDL (`platforms/config.kdl`).

No `.cursorrules`, `.cursor/rules/`, or `.github/copilot-instructions.md`.
If added later, treat as higher priority.

`.vscode/` is in `.gitignore` — VS Code workspace settings are not committed.
`result` and `result-*` (Nix build symlinks) are also git-ignored.
`out/` contains Mill/Scala build artifacts for nearby projects — not Nix-generated,
not in `.gitignore`, safe to leave alone.

## 2) Build / Lint / Test Commands

Run all commands from repo root. No CI/CD, no task runner, no test framework —
use the smallest flake build as a "single test". All validation is local-only.

| Action | Command |
|--------|---------|
| Update lock file | `nix flake update` |
| Show outputs | `nix flake show --no-write-lock-file` |
| Check (eval only) | `nix flake check --no-build` |
| Check (full build) | `nix flake check` |

**NixOS Hosts**: `srcres-desktop` · `srcres-laptop` · `srcres-wsl`
· `srcres-desktop-x99` · `srcres-orange-pi` (aarch64-linux)

```bash
nix build .#nixosConfigurations.srcres-desktop.config.system.build.toplevel
sudo nixos-rebuild switch --flake .#srcres-desktop
```

**Home Manager**: `srcres@srcres-desktop` · `srcres@srcres-laptop` · `srcres@srcres-wsl`
· `srcres@srcres-desktop-x99` · `srcres@srcres-orange-pi`

```bash
nix build .#homeConfigurations."srcres@srcres-desktop".activationPackage
home-manager switch --flake .#srcres@srcres-desktop
nix run nixpkgs#home-manager -- switch --flake .#srcres@srcres-desktop  # fallback
```

| Language | Formatter |
|----------|-----------|
| Nix | `nixpkgs-fmt <file-or-dir>` |
| Lua | `stylua <path>` |
| Python | `yapf -ir <path>` / `pyright` |
| Rust | `cargo fmt` / `cargo clippy` |

Flake package: `nix build .#packages.x86_64-linux.srcres`

## 3) Flake Architecture

### Factory Functions

| Factory | Output | specialArgs | modules |
|---------|--------|-------------|---------|
| `mkNixOSConfig` | `nixosSystem` | `inputs`, `system`, `pkgs-unstable`, `srcres-password` | `[ ./configuration.nix ] ++ extraModules` |
| `mkHomeConfig` | `homeManagerConfiguration` | `inputs`, `system`, `pkgs-unstable` | `[ ./home ] ++ extraModules` |
| `mkPureHomeConfig` | `homeManagerConfiguration` | `inputs`, `system`, `pkgs-unstable` | `extraModules` only |

### Module Composition

```
mkNixOSConfig:
  modules = [ ./configuration.nix ] ++ extraModules
    │
    ├── configuration.nix         ← flat base module (no imports)
    ├── platforms/<platform>/configuration.nix
    └── devices/<host>/configuration.nix → hardware-configuration.nix

mkHomeConfig:
  modules = [ ./home ] ++ extraModules
    │
    └── home/default.nix
          ├── home/pure/default.nix          ← imports: options.nix, leaf modules, texlive/, yazi/
          ├── home/system/default.nix        ← imports: waybar.nix, qutebrowser/
          ├── platforms/<platform>/home      ← imports: vscode.nix, references config.kdl
          └── devices/<host>/home

mkPureHomeConfig (WSL only):
  modules = extraModules  ← no ./home baked in; caller passes ./home/pure
    │
    └── home/pure/default.nix        ← passed via extraModules
          └── devices/srcres-wsl/home
```

`configuration.nix` is a flat module with **no imports**. Platform and device
modules are injected via `extraModules` in each factory call. `devices/srcres-wsl/`
has no `hardware-configuration.nix` — the WSL platform module
(`nixos-wsl.nixosModules.default`) replaces it.

`srcres-password` is only passed to `mkNixOSConfig` (not home configs). Secret
injection uses `builtins.getEnv` at the flake boundary only, never hardcoded.

`nixpkgs` tracks `nixos-26.05`, `nixpkgs-unstable` tracks `nixos-unstable`.
Home Manager follows `release-26.05`.

`allowUnfree = true` is set in `mkPkgs` — all package resolution assumes unfree allowed.

`pkgs-unstable` is available as a module argument in **both** system (`specialArgs`)
and home-manager (`extraSpecialArgs`) modules. The `system` arg (from `specialArgs`)
is referenced via `${system}` in platform home modules for pinned legacy packages.

Note: the top-level `let system = "x86_64-linux";` in `flake.nix` is only used for
`packages.x86_64-linux.srcres` and the `pkgs`/`pkgs-unstable` helpers. Each NixOS
and home config overrides `system` per-host as needed (e.g., `srcres-orange-pi`
uses `"aarch64-linux"`).

### Flake Inputs — Why They Exist

| Input | Purpose |
|-------|---------|
| `nixpkgs` | Main package set (`nixos-26.05`) |
| `nixpkgs-unstable` | Bleeding-edge packages (`nixos-unstable`) |
| `mill-legacy-nixpkgs` | Pinned nixpkgs for `mill` (Scala build tool) |
| `go-ethereum-legacy-nixpkgs` | Pinned nixpkgs for `go-ethereum` (Ethereum client) |
| `vscode-legacy-nixpkgs` | Pinned nixpkgs for `vscode.fhs` wrapper |
| `nur` | Nix User Repository overlay |
| `home-manager` | Home Manager (`release-26.05`) |
| `nixos-wsl` | WSL platform module |
| `minegrub-theme` | GRUB Minecraft theme |
| `vscode-extensions` | `nix-vscode-extensions` overlay |
| `foundry` | Foundry Ethereum dev tools (overlay → `foundry-bin`) |
| `yazi` | Yazi file manager built from source (overridden in `home/pure/yazi/`) |

The three legacy-nixpkgs inputs pin specific nixpkgs revisions for packages that
are broken or unavailable in the current nixpkgs. `yazi` is built from the
upstream repo rather than nixpkgs to get the latest version with plugin support.

## 4) Code Style Guidelines

### Nix Syntax

- **4-space indentation** throughout. 2-space inside `let ... in` in `flake.nix`;
  4-space inside `let ... in` within modules.
- **Function arguments**: comma-first, one per line, `...` at end:
  `{ config, pkgs, lib, ... }:`
- **`let ... in`** for computed locals.
- **`inherit`** to forward names (`inherit system pkgs;`).
- **`with pkgs; [ ... ]`** for package lists.
- **`imports = [ ... ];`** for module composition; prefer over duplication.
- **Attribute names**: `lowerCamelCase` (`packageGenerator`, `javaPkg`).

### Module Patterns

- One `.nix` file per program/concern (`git.nix`, `waybar.nix`).
  Group sub-concerns in directories with `default.nix`.
- The shared `configuration.nix` is intentionally monolithic — it holds base
  system config all hosts share. New concerns should be extracted to separate
  modules over time.
- Minimal modules: `{ ... }: { ... }` when no args needed.
- Declare `pkgs`/`config`/`inputs` in function signature when used.
- `home.stateVersion` set **per-device** only, never in shared modules.
  Exception: the dev-only profile (`develop.nix`) sets it inline in `flake.nix`.
- `home.username` and `home.homeDirectory` in `home/pure/default.nix`.
- Use `lib.mkDefault` for overridable defaults.

### Package Lists

- `with pkgs; [ ... ]`, grouped by purpose with section comments
  (`# Rust language`, `# Fonts`).
- Conditional: `++ lib.optionals (!pkgs.stdenv.hostPlatform.isAarch64) [ ... ]`.
- NUR: `with nur.repos; [ srcres258.X ]`.
- Unstable: `with pkgs-unstable; [ ... ]`.
- Pinned: `inputs.<name>.legacyPackages.${system}.<pkg>` for legacy/pinned
  packages (e.g. `go-ethereum-legacy-nixpkgs`, `mill-legacy-nixpkgs`).

### Override Patterns

- Use `lib.mkDefault` for overridable defaults in platform/base modules.
- Use `lib.mkForce` to override auto-generated `hardware-configuration.nix`
  values or platform defaults (e.g. kernel modules, fileSystems).
- Use `lib.mkAfter` to append to list-type options (e.g. kernel boot params).

### Custom Options

- Declared in `home/options.nix` under `my.*` prefix.
- Example: `my.python.packageGenerator` — device modules inject
  extra packages via `my.python.packageGenerator = ps: [ ... ];`.

### Lua Conventions

- `local` bindings; `pcall` for guarded optional integration.
- Neovim `init.lua` loaded via `builtins.readFile` + `builtins.replaceStrings`
  for Nix store path interpolation (e.g. `{{METALS_BINARY_PATH}}`).
- `require('plugin').setup({ ... })` pattern for plugin config.
- Guard VSCode code: `if not vim.g.vscode then ... end`.

### Formatting & Safety

- `nixpkgs-fmt` output is authoritative for Nix. No formatter config files
  exist — the tool's defaults are the convention.
- Rely on eval/build failures, not opaque fallbacks.
- Never suppress errors with `null` unless using `lib.mkDefault`.
- Keep `hardware-configuration.nix` auto-generated; do not hand-edit.
- Keep embedded shell snippets idempotent.
- Comments in Chinese (e.g. platform configs) are acceptable; there is no language restriction.

### OpenCode Config

This repo configures OpenCode itself via `home/pure/opencode.nix` — agent settings,
permission rules, and MCP servers are managed through Home Manager.
When modifying OpenCode behavior, edit the Nix module, not `~/.config/opencode/`.

## 5) Gotchas & Hard-Won Context

### NUR / fetchTarball — Network Dependency

The NUR repo is pulled via `builtins.fetchTarball` in `home/default.nix`:
```nix
remoteUrl = "https://github.com/${username}/nur-packages/archive/main.tar.gz";
```
This means **the first build requires network access**. An offline build will
fail on this tarball fetch. This is separate from the NUR overlay
(`nur.overlays.default`) used in the system-level `mkPkgs`.

### nix flake update — Touches Legacy Pins

`nix flake update` updates **all** flake inputs, including the three
legacy-nixpkgs pins (`mill-legacy-nixpkgs`, `go-ethereum-legacy-nixpkgs`,
`vscode-legacy-nixpkgs`). These are pinned to specific revisions because newer
nixpkgs broke those packages. Updating them blindly will likely break builds.
Prefer `nix flake lock --update-input <specific-input>` to update only what's
needed.

### Secret Injection

`srcres-password` comes from `builtins.getEnv "SRCRES_PASSWORD"` — if the env
var is empty, the build still succeeds but users can't log in. Only
`mkNixOSConfig` receives it; home configs never see it.

### Orange Pi (aarch64-linux) — Cross-Compilation

Orange Pi uses `system = "aarch64-linux"` and is cross-evaluated from x86_64.
It uses `lib.mkForce` extensively to override auto-generated
`hardware-configuration.nix` values (kernel modules, initrd config). Key quirks:

- **Custom out-of-tree kernel module** (`aic8800d80` Wi-Fi): compiled via
  `kernelPackages.callPackage` with inline `mkDerivation` + firmware derivation
  in `devices/srcres-orange-pi/configuration.nix`
- **`hardware.firmwareCompression = "none"`**: out-of-tree driver can't read
  NixOS-compressed `.zst` firmware
- **Systemd initrd services**: `boot.initrd.systemd.services` for PCIe/NVMe
  rescan and `/sysroot/run` directory creation (BTRFS root subvolume)
- **`boot.kernelParams = lib.mkAfter [...]`**: appends root UUID, rootwait,
  rootdelay, rootfstype after platform defaults

Some packages in `configuration.nix` are gated with
`!pkgs.stdenv.hostPlatform.isAarch64` — these are excluded from Orange Pi builds.

### WSL — No platforms/wsl/

There is **no** `platforms/wsl/` directory. The WSL platform module is the
external `nixos-wsl.nixosModules.default`, passed directly in `mkNixOSConfig`
for the WSL host. WSL uses `mkPureHomeConfig` (pure-only, no GUI modules).
`devices/srcres-wsl/` has no `hardware-configuration.nix` — the nixos-wsl
module replaces it.

### stateVersion — Don't Touch

`home.stateVersion` is set **per-device** in `devices/<host>/home/default.nix`.
`system.stateVersion` is set in device `configuration.nix` files. These must
never be changed except when provisioning a brand-new machine. Current values
vary between "25.05" and "25.11" — newer NixOS releases should not cause you
to upgrade these.

### hardware-configuration.nix

Auto-generated by `nixos-generate-config`. Never hand-edit. Only
`devices/srcres-wsl/` lacks one — WSL doesn't need it.

### develop.nix — Dev-Only Profile

`home/develop.nix` is a standalone Home Manager profile that imports only
`./pure` (no system/GUI modules). Built into a flake package at
`packages.x86_64-linux.srcres`. Sets `home.stateVersion` inline in `flake.nix`,
not in a device module.

### Custom Options

`my.python.packageGenerator` in `home/options.nix` allows device modules to
inject extra Python packages. Used by `srcres-desktop` and `srcres-desktop-x99`
home configs. Default: `ps: [ ]`.

### Custom Systemd User Services

Device home configs define `systemd.user.services` for wallpaper management:
- `mpvpaper` service on desktop/desktop-x99 (video wallpaper via mpv)
- `swaybg` service on orange-pi (static wallpaper, lighter for SBC)

These are NOT in shared modules — each device wires its own.

### VS Code Activation Hook

`platforms/native/home/vscode.nix` uses `lib.hm.dag.entryAfter [ "writeBoundary" ]`
and `config.lib.file.mkOutOfStoreSymlink` to merge Nix-managed VS Code settings
with user changes. The orange-pi vscode.nix is a simplified variant without
this hook. If VS Code settings aren't persisting, check this activation.

### Composite initLua Pattern

Neovim config (`home/pure/neovim.nix`) combines two Lua sources:
1. An **inline `initLua` string** for treesitter setup
2. `builtins.readFile ./init.lua` with `builtins.replaceStrings` for
   `{{METALS_BINARY_PATH}}` store path interpolation

Both are concatenated. When editing Neovim config, check both the Nix module
and the Lua file.

### Host Quick Reference

| Host | System | Platform | stateVersion |
|------|--------|----------|-------------|
| srcres-desktop | x86_64-linux | native | 25.05 |
| srcres-laptop | x86_64-linux | native | 25.11 (sys) / 25.05 (home) |
| srcres-wsl | x86_64-linux | nixos-wsl | 25.11 (sys) / 25.05 (home) |
| srcres-desktop-x99 | x86_64-linux | native | 25.11 (sys) / 25.05 (home) |
| srcres-orange-pi | aarch64-linux | orangepi | 25.11 |

## 6) Validation Strategy

1. `nix flake check --no-build` — catch eval errors fast.
2. Targeted build for changed scope:
   - System: `nix build .#nixosConfigurations.<host>.config.system.build.toplevel`
   - Home: `nix build .#homeConfigurations."<user>@<host>".activationPackage`
3. `nix flake check` — full check only when needed.
4. `nixpkgs-fmt <file>` on changed Nix files.
