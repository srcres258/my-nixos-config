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
`home/pure/yazi/init.lua`), shell snippets, KDL (`platforms/*/home/config.kdl`).

No `.cursorrules`, `.cursor/rules/`, or `.github/copilot-instructions.md`.
If added later, treat as higher priority.

`.vscode/` is in `.gitignore` — VS Code workspace settings are not committed.
`result` and `result-*` (Nix build symlinks) are also git-ignored.

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
          ├── home/system/default.nix        ← imports: waybar.nix, other GUI modules
          ├── platforms/<platform>/home      ← imports: vscode.nix, config.kdl
          └── devices/<host>/home

mkPureHomeConfig (WSL only):
  modules = [ ./home/pure ] ++ extraModules  ← no ./home, no ./system
    │
    └── home/pure/default.nix
          └── devices/srcres-wsl/home
```

`configuration.nix` is a flat module with **no imports**. Platform and device
modules are injected via `extraModules` in each factory call. `devices/srcres-wsl/`
has no `hardware-configuration.nix` — the WSL platform module
(`nixos-wsl.nixosModules.default`) replaces it.

`srcres-password` is only passed to `mkNixOSConfig` (not home configs). Secret
injection uses `builtins.getEnv` at the flake boundary only, never hardcoded.

`allowUnfree = true` is set in `mkPkgs` — all package resolution assumes unfree allowed.

`pkgs-unstable` is available as a module argument in **both** system (`specialArgs`)
and home-manager (`extraSpecialArgs`) modules. The `system` arg (from `specialArgs`)
is referenced via `${system}` in platform home modules for pinned legacy packages.

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

## 5) Validation Strategy

1. `nix flake check --no-build` — catch eval errors fast.
2. Targeted build for changed scope:
   - System: `nix build .#nixosConfigurations.<host>.config.system.build.toplevel`
   - Home: `nix build .#homeConfigurations."<user>@<host>".activationPackage`
3. `nix flake check` — full check only when needed.
4. `nixpkgs-fmt <file>` on changed Nix files.
