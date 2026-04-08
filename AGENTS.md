# AGENTS.md

This repository is a personal NixOS/Home Manager flake.
Use this guide to keep agent changes safe, consistent, and verifiable.

## 1) Repository Scope

- Root flake: `flake.nix`
- System base module: `configuration.nix`
- Home Manager entrypoint: `home/default.nix`
- Host modules: `devices/*/configuration.nix` and `devices/*/home/default.nix`
- Shared home modules: `home/pure/*` and `home/system/*`

Primary language is **Nix**, with embedded shell snippets and some Lua
(`home/pure/init.lua`, `home/pure/yazi/init.lua`).

## 2) Additional Rule Files (Checked)

No extra agent rule files are currently present:

- `.cursorrules`: not found
- `.cursor/rules/`: not found
- `.github/copilot-instructions.md`: not found

If these are added later, treat them as higher-priority instruction sources.

## 3) Build / Lint / Test Commands

Run commands from repo root: `/home/srcres/nix-config`.

### 3.1 Core Flake Commands

- Update lock file inputs:
  - `nix flake update`
- Show outputs:
  - `nix flake show --no-write-lock-file`
- Evaluate checks without building:
  - `nix flake check --no-build`
- Run full flake checks:
  - `nix flake check`

### 3.2 NixOS Build / Switch

Known NixOS hosts from `flake.nix`:
`srcres-desktop`, `srcres-laptop`, `srcres-wsl`, `srcres-desktop-x99`.

- Build one host closure (scoped validation):
  - `nix build .#nixosConfigurations.srcres-desktop.config.system.build.toplevel`
- Switch on target machine:
  - `sudo nixos-rebuild switch --flake .#srcres-desktop`

For other hosts, substitute the host key accordingly.

### 3.3 Home Manager Build / Switch

Known Home Manager targets are `<user>@<host>`;
for example: `srcres@srcres-desktop`.

- Build activation package:
  - `nix build .#homeConfigurations."srcres@srcres-desktop".activationPackage`
- Switch Home Manager:
  - `home-manager switch --flake .#srcres@srcres-desktop`
- If `home-manager` is unavailable globally:
  - `nix run nixpkgs#home-manager -- switch --flake .#srcres@srcres-desktop`

### 3.4 Flake Package Build

- Build exported package env:
  - `nix build .#packages.x86_64-linux.srcres`

### 3.5 Formatting / Typecheck Tools

There is no single root task runner (`Makefile`, `package.json`, `pyproject.toml`,
or root Cargo workspace command).
Use tooling by touched language:

- Nix format:
  - `nixpkgs-fmt <file-or-dir>`
- Lua format (if available):
  - `stylua <path>`
- Python (if introduced/changed):
  - `yapf -ir <path>`
  - `pyright`
- Rust (if introduced/changed):
  - `cargo fmt`
  - `cargo clippy`

### 3.6 Running a Single Test (Important)

This repo has **no canonical root unit-test framework**.
So there is no stable built-in single-test command like `pytest -k`,
`cargo test <name>`, or `npm test -- <pattern>`.

Use the smallest affected flake build as a practical single-test equivalent:

- System scope:
  - `nix build .#nixosConfigurations.<host>.config.system.build.toplevel`
- Home scope:
  - `nix build .#homeConfigurations."<user>@<host>".activationPackage`

## 4) Code Style Guidelines

### 4.1 Nix Style and Structure

- Use 4-space indentation in Nix files.
- Prefer `let ... in` for computed locals and intermediate values.
- Use `inherit` to forward existing names (`inherit system pkgs`).
- Keep wiring explicit via `imports = [ ... ];`.
- Prefer `with pkgs; [ ... ]` for package lists when already used nearby.
- Use descriptive `lowerCamelCase` attribute names.

### 4.2 Imports and Module Composition

- Preserve the existing split:
  - `home/default.nix` imports `./pure` and `./system`.
  - Device-specific logic stays under `devices/<host>/...`.
- Add new modules to the nearest existing subtree.
- Prefer composing modules through `imports` over duplicating blocks.

### 4.3 Flake Wiring Patterns

- Follow `flake.nix` factory patterns (`mkNixOSConfig`, `mkHomeConfig`).
- Keep `specialArgs` / `extraSpecialArgs` explicit and minimal.
- Pass secrets via environment at flake boundary (e.g. `builtins.getEnv` in
  `flake.nix`), not by hardcoding in modules.

### 4.4 Formatting and Readability

- `nixpkgs-fmt` output is authoritative for Nix formatting.
- Wrap long lists/strings for readability.
- Keep comments concise and high-signal.

### 4.5 Types, Naming, and Explicitness

- Nix is dynamic; clarity comes from explicit local names and structure.
- For Lua, prefer `local` bindings and guarded optional integration (`pcall`).
- For typed languages added later, prefer explicit public API types.
- Keep host/output names stable once introduced.

### 4.6 Error Handling and Safety

- Nix: rely on evaluation/build failures rather than opaque fallbacks.
- Document assumptions around environment reads (`builtins.getEnv`).
- Keep embedded shell snippets idempotent and safe to rerun.

## 5) Validation Strategy for Agents

After modifying Nix modules, run the smallest relevant validation first:

1. `nix flake check --no-build`
2. Targeted build for changed scope:
   - system: `nix build .#nixosConfigurations.<host>.config.system.build.toplevel`
   - home: `nix build .#homeConfigurations."<user>@<host>".activationPackage`
3. Run broader checks only when needed:
   - `nix flake check`

## 6) Quick Command Cheat Sheet

- `nix flake show --no-write-lock-file`
- `nix flake check --no-build`
- `nix build .#nixosConfigurations.srcres-desktop.config.system.build.toplevel`
- `sudo nixos-rebuild switch --flake .#srcres-desktop`
- `nix build .#homeConfigurations."srcres@srcres-desktop".activationPackage`
- `home-manager switch --flake .#srcres@srcres-desktop`
- `nix build .#packages.x86_64-linux.srcres`

When unsure, validate by building the smallest affected flake attribute first.
