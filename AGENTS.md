# AGENTS.md

This repository is a personal NixOS/Home Manager flake.
Use this guide to keep agent changes safe and consistent.

## 1) Repository Scope

- Root flake: `flake.nix`
- System base module: `configuration.nix`
- Home Manager entrypoint: `home/default.nix`
- Host modules: `devices/*/configuration.nix` and `devices/*/home/default.nix`
- Shared home modules: `home/pure/*` and `home/system/*`

Main language is **Nix**, with embedded shell snippets and some Lua (`home/pure/init.lua`).

## 2) Additional Rule Files (Checked)

No extra agent rule files were found:

- `.cursorrules`: not present
- `.cursor/rules/`: not present
- `.github/copilot-instructions.md`: not present

If these are added later, treat them as higher-priority instructions.

## 3) Build / Lint / Test Commands

## 3.1 Core Flake Commands

Run from repo root (`/home/srcres/nix-config`):

- Update lockfile inputs:
  - `nix flake update`
- Show outputs:
  - `nix flake show --no-write-lock-file`
- Fast evaluation checks (no build):
  - `nix flake check --no-build`
- Full checks:
  - `nix flake check`

## 3.2 NixOS Build / Switch

Known hosts are defined in `flake.nix` (for example `srcres-desktop`, `srcres-laptop`, `srcres-wsl`, `srcres-desktop-x99`).

Build one host closure:
- `nix build .#nixosConfigurations.srcres-desktop.config.system.build.toplevel`

Switch one host (on target machine):
- `sudo nixos-rebuild switch --flake .#srcres-desktop`

Use the same pattern for other host names.

## 3.3 Home Manager Build / Switch

Known home targets are `<user>@<host>`, for example `srcres@srcres-desktop`.

Build activation package:
- `nix build .#homeConfigurations."srcres@srcres-desktop".activationPackage`

Switch Home Manager:
- `home-manager switch --flake .#srcres@srcres-desktop`

If `home-manager` is not globally installed:
- `nix run nixpkgs#home-manager -- switch --flake .#srcres@srcres-desktop`

## 3.4 Flake Package Build

Build exported package env:
- `nix build .#packages.x86_64-linux.srcres`

## 3.5 Formatting / Typecheck Tools

There is no single root task runner (no root Makefile/package.json/pyproject/Cargo project).
Use tool-specific commands based on touched files:

- Nix format:
  - `nixpkgs-fmt <file-or-dir>`
- Lua format (if available in environment):
  - `stylua <path>`
- Python format + typecheck (if Python files are introduced/changed):
  - `yapf -ir <path>`
  - `pyright`
- Rust format + lint (if Rust files are introduced/changed):
  - `cargo fmt`
  - `cargo clippy`

## 3.6 Running a Single Test (Important)

This repo currently has **no canonical unit-test framework at root**.
So there is no stable built-in single-test command like `pytest -k`, `cargo test <name>`, or `npm test -- <pattern>`.

Use smallest target build as a practical scoped check:

- System target check:
  - `nix build .#nixosConfigurations.<host>.config.system.build.toplevel`
- Home target check:
  - `nix build .#homeConfigurations."<user>@<host>".activationPackage`

Treat these as the closest equivalent to “single test” in this repository.

## 4) Code Style Guidelines

## 4.1 Nix

- Prefer 4-space indentation to match existing Nix files.
- Prefer `let ... in` for local values and intermediate expressions.
- Use `inherit` when forwarding existing names (`inherit system pkgs`).
- Keep module wiring explicit via `imports = [ ... ];`.
- Prefer `with pkgs; [ ... ]` for package lists when already used nearby.
- Use descriptive `lowerCamelCase` attribute names unless schema requires otherwise.

## 4.2 Imports and Module Composition

- Follow existing split:
  - `home/default.nix` imports `./pure` and `./system`.
  - Device-specific logic stays under `devices/<name>/...`.
- Add modules in the nearest existing subtree.
- Prefer imports over duplicating inline blocks across hosts.

## 4.3 Formatting and Width

- VSCode settings in repo indicate:
  - `editor.tabSize = 2`
  - rulers at 80 / 100 / 120 columns
- For Nix, formatter output (`nixpkgs-fmt`) is authoritative.
- Keep long strings and lists wrapped for readability.

## 4.4 Types and Explicitness

- Nix is dynamic; clarity comes from explicit names and local bindings.
- In Lua, use `local` bindings and add EmmyLua annotations when useful.
- For typed languages introduced later (TS/Python/Rust), prefer explicit public API types.

## 4.5 Naming

- Nix attributes: `lowerCamelCase` (e.g., `homeConfigurations`, `extraSpecialArgs`).
- Host/device names should remain consistent with existing style (`srcres-desktop`, etc.).
- Keep flake output names stable once introduced.

## 4.6 Error Handling

- Nix: rely on evaluation/build failure; avoid opaque fallback behavior.
- Document expectations when reading env vars (`builtins.getEnv`).
- Shell snippets in Nix strings should be idempotent and safe to re-run.
- Lua: use guarded calls (`pcall`) for optional integrations.

## 4.7 Comments

- Add comments for non-obvious intent or constraints.
- Prefer concise, high-signal comments.
- Keep Markdown docs direct and short.

## 5) Quick Command Cheat Sheet

- `nix flake show --no-write-lock-file`
- `nix flake check --no-build`
- `nix build .#nixosConfigurations.srcres-desktop.config.system.build.toplevel`
- `sudo nixos-rebuild switch --flake .#srcres-desktop`
- `nix build .#homeConfigurations."srcres@srcres-desktop".activationPackage`
- `home-manager switch --flake .#srcres@srcres-desktop`
- `nix build .#packages.x86_64-linux.srcres`

When unsure, validate by building the smallest affected flake attribute.