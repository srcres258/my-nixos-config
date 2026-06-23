# AGENTS.md

Personal NixOS/Home Manager flake. Keep this short; only include facts an agent would likely miss.

## Entry points
- `flake.nix` defines `nixosConfigurations.*`, `homeConfigurations."srcres@*"`, and the `packages.${system}.srcres` dev env.
- `configuration.nix` is the shared NixOS base; host-specific NixOS modules live in `devices/<host>/` and platform-specific pieces in `platforms/<native|orangepi>/`.
- `home/default.nix` is the shared Home Manager layer (`./pure` + `./system`). WSL uses `mkPureHomeConfig`, so it skips `./home` and loads `home/pure` directly.
- Edit OpenCode config in `home/pure/opencode.nix`; do not touch generated files under `~/.config/opencode/`.

## Commands
Run from repo root.
- `nix flake check --no-build` first, then `nix flake check` for full verification.
- System build: `nix build .#nixosConfigurations.<host>.config.system.build.toplevel`
- Home build: `nix build .#homeConfigurations."srcres@<host>".activationPackage`
- Format touched Nix files with `nixpkgs-fmt`.

## Gotchas
- There is no CI, pre-commit, or task runner here; flake checks are the source of truth.
- `home/default.nix` imports NUR and also fetches `srcres258/nur-packages` via `builtins.fetchTarball`; the first build needs network.
- `nix flake lock --update-input <name>` is preferred over `nix flake update` for the legacy pins.
- `SRCRES_PASSWORD` is only consumed by `mkNixOSConfig`.
- `hardware-configuration.nix` files are auto-generated; do not hand-edit them.
- `home.stateVersion` / `system.stateVersion` are per-host; do not bump casually.
- Orange Pi is `aarch64-linux`; WSL uses `nixos-wsl.nixosModules.default`.
- Ignore `result/`, `result-*`, and `out/`.

## Style
- Nix style: 4-space indentation, comma-first function args, `let ... in`, `imports = [ ... ]`.
- Prefer `lib.mkDefault`, `lib.mkForce`, and `lib.mkAfter` over ad hoc overrides.
- Keep embedded shell snippets idempotent.
