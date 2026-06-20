# AGENTS.md

Personal NixOS/Home Manager flake. Keep this file short; only include facts an agent would likely miss.

## Read first
- `flake.nix` is the real entrypoint: `mkNixOSConfig`, `mkHomeConfig`, `mkPureHomeConfig` define the system/home outputs.
- `configuration.nix` is the shared NixOS base; host/platform specifics live in `devices/<host>/*` and `platforms/*`.
- `home/default.nix` imports `./pure` and `./system`.
- WSL is wired through `mkPureHomeConfig`, so it skips the shared `./home` layer and uses `home/pure` only.
- `home/pure/opencode.nix` is the source of truth for OpenCode config; do not edit generated files under `~/.config/opencode/`.

## Commands
Run from repo root.
- `nix flake check --no-build` first.
- `nix flake check` for full verification.
- System build: `nix build .#nixosConfigurations.<host>.config.system.build.toplevel`
- Home build: `nix build .#homeConfigurations."srcres@<host>".activationPackage`
- Format touched Nix files with `nixpkgs-fmt`.
- Only if touching those languages: `stylua`, `yapf -ir`, `pyright`, `cargo fmt`, `cargo clippy`.

## Repo gotchas
- There is no CI, pre-commit, or task runner here; flake checks are the source of truth.
- `home/default.nix` fetches NUR with `builtins.fetchTarball`; the first build needs network.
- `nix flake update` touches the legacy pins (`mill-legacy-nixpkgs`, `go-ethereum-legacy-nixpkgs`, `vscode-legacy-nixpkgs`); prefer `nix flake lock --update-input <name>`.
- `SRCRES_PASSWORD` is only consumed by `mkNixOSConfig`.
- `hardware-configuration.nix` files are auto-generated; do not hand-edit them.
- `home.stateVersion` and `system.stateVersion` are per-host; do not bump them casually.
- Orange Pi is `aarch64-linux`; WSL uses `nixos-wsl.nixosModules.default` and has no `hardware-configuration.nix`.
- Ignore `result/`, `result-*`, and `out/`.

## Style / workflow
- Nix style: 4-space indentation, comma-first function args, `let ... in`, `imports = [ ... ]`.
- Prefer `lib.mkDefault`, `lib.mkForce`, and `lib.mkAfter` over ad hoc overrides.
- Keep embedded shell snippets idempotent.
