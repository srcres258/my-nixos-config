# AGENTS.md

Personal NixOS/Home Manager flake. Follow these rules to keep changes
safe, consistent, and verifiable.

## 1) Repository Layout

```
flake.nix                                 # Flake entry
configuration.nix                         # Shared base NixOS module
home/default.nix                          # Home Manager entry (imports ./pure + ./system)
home/options.nix                          # Custom my.* option declarations
home/pure/                                # Portable home modules (CLI-only, works on WSL)
home/system/                              # System-dependent home modules (GUI, Wayland)
home/develop.nix                          # Standalone dev-only home profile
devices/<host>/configuration.nix          # Per-host system config
devices/<host>/home/default.nix           # Per-host home overlay
devices/<host>/hardware-configuration.nix # Hardware scan (auto-generated)
platforms/native/                         # Native (physical machine) platform modules
platforms/orangepi/                       # Orange Pi platform modules
```

Primary: **Nix**. Secondary: **Lua** (`home/pure/init.lua`,
`home/pure/yazi/init.lua`), shell snippets, KDL (`platforms/*/home/config.kdl`).

No `.cursorrules`, `.cursor/rules/`, or `.github/copilot-instructions.md`.
If added later, treat as higher priority.

## 2) Build / Lint / Test Commands

Run all commands from repo root. No task runner or test framework —
use the smallest flake build as a "single test".

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
| `mkPureHomeConfig` | `homeManagerConfiguration` | `inputs`, `system`, `pkgs-unstable` | `extraModules` only (WSL) |

### Module Hierarchy

```
flake.nix factories
 ├── configuration.nix          (shared base system)
 │    ├── platforms/<platform>/configuration.nix
 │    └── devices/<host>/configuration.nix → hardware-configuration.nix
 └── home/                      (full home: mkHomeConfig)
      ├── pure/                 (portable: also used by mkPureHomeConfig)
      │    ├── options.nix      (custom my.* options)
      │    └── *.nix
      └── system/               (GUI / platform-dependent)
           └── *.nix
```

Secrets via `builtins.getEnv` at flake boundary only, never hardcoded.

## 4) Code Style Guidelines

### Nix Syntax

- **4-space indentation** throughout. 2-space inside `let ... in`.
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
- Minimal modules: `{ ... }: { ... }` when no args needed.
- Declare `pkgs`/`config`/`inputs` in function signature when used.
- `home.stateVersion` set **per-device** only, never globally.
- `home.username` and `home.homeDirectory` in `home/pure/default.nix`.
- Use `lib.mkDefault` for overridable defaults.

### Package Lists

- `with pkgs; [ ... ]`, grouped by purpose with section comments
  (`# Rust language`, `# Fonts`).
- Conditional: `++ lib.optionals (!pkgs.stdenv.hostPlatform.isAarch64) [ ... ]`.
- NUR: `with nur.repos; [ srcres258.X ]`.
- Unstable: `with pkgs-unstable; [ ... ]`.
- Pinned: `inputs.<name>.legacyPackages.${system}.<pkg>`.

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

- `nixpkgs-fmt` output is authoritative for Nix.
- Rely on eval/build failures, not opaque fallbacks.
- Never suppress errors with `null` unless using `lib.mkDefault`.
- Keep `hardware-configuration.nix` auto-generated; do not hand-edit.
- Keep embedded shell snippets idempotent.

## 5) Validation Strategy

1. `nix flake check --no-build` — catch eval errors fast.
2. Targeted build for changed scope:
   - System: `nix build .#nixosConfigurations.<host>.config.system.build.toplevel`
   - Home: `nix build .#homeConfigurations."<user>@<host>".activationPackage`
3. `nix flake check` — full check only when needed.
4. `nixpkgs-fmt <file>` on changed Nix files.
