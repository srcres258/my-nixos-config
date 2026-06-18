# AGENTS.md

Personal NixOS/Home Manager flake. Keep this file short and only include facts an agent would miss without help.

## Read first
- `flake.nix` defines the real entrypoints: `mkNixOSConfig`, `mkHomeConfig`, `mkPureHomeConfig`.
- `configuration.nix` is the shared NixOS base and has no imports.
- `home/default.nix` imports `./pure` and `./system`.
- `home/pure/opencode.nix` configures OpenCode for this repo.
- `devices/<host>/*` and `platforms/*` contain the host/platform overrides.

## Commands
Run from repo root.
- `nix flake check --no-build` first.
- `nix flake check` for full verification.
- System build: `nix build .#nixosConfigurations.<host>.config.system.build.toplevel`
- Home build: `nix build .#homeConfigurations."srcres@<host>".activationPackage`
- Format touched Nix files with `nixpkgs-fmt`.
- Only if touching those languages: `stylua`, `yapf -ir`, `pyright`, `cargo fmt`, `cargo clippy`.

## Repo-specific gotchas
- There is no CI, pre-commit, or task runner here; flake checks are the source of truth.
- `home/default.nix` fetches NUR with `builtins.fetchTarball`; the first build needs network.
- `nix flake update` touches the legacy pins (`mill-legacy-nixpkgs`, `go-ethereum-legacy-nixpkgs`, `vscode-legacy-nixpkgs`); prefer `nix flake lock --update-input <name>`.
- `SRCRES_PASSWORD` is only consumed by `mkNixOSConfig`.
- `hardware-configuration.nix` files are auto-generated; do not hand-edit them.
- `home.stateVersion` and `system.stateVersion` are per-host; do not bump them casually.
- Orange Pi is `aarch64-linux`; WSL uses `nixos-wsl.nixosModules.default` and has no `hardware-configuration.nix`.
- Orange Pi is the only host with `home.stateVersion = "25.11"`; it also overrides `home.username` and `home.homeDirectory`.
- Ignore `result/`, `result-*`, and `out/`.

## Style / workflow
- Nix style: 4-space indentation, comma-first function args, `let ... in`, `imports = [ ... ]`.
- Prefer `lib.mkDefault`, `lib.mkForce`, and `lib.mkAfter` over ad hoc overrides.
- Keep embedded shell snippets idempotent.
- When changing OpenCode behavior, edit the Nix module in `home/pure/opencode.nix`, not generated config under `~/.config/opencode/`.
