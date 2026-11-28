{ pkgs
, lib
, config
, inputs
, ...
}:
let
  system = pkgs.stdenv.hostPlatform.system;

  # Declarative Pi extensions.
  #
  # Pi auto-discovers `~/.pi/agent/extensions/*.ts|*.js` and
  # `~/.pi/agent/extensions/<dir>/index.ts`, and it follows symlinks (see
  # collectAutoExtensionEntries in packages/coding-agent/src/core/package-manager.ts).
  # Each entry below is therefore linked from the Nix store into the user
  # extension directory. That keeps extension code immutable while leaving
  # `~/.pi/agent/settings.json` writable, which Pi needs since it writes that
  # file itself (`lastChangelogVersion`, `pi install` adding to `packages`, ...).
  # The few keys Nix does own there are merged in by the activation step below.
  #
  # Key   = name inside ~/.pi/agent/extensions/. Use `foo` for a directory
  #         (needs index.ts or package.json with `pi.extensions`) and
  #         `foo.ts` for a single file.
  # Value = a store path or Nix path. Typical sources:
  #         - pkgs.nur.repos.<user>.<package> for a NUR repository's package.
  #         - inputs.<flake>.packages.${system}.default
  #           for a package directory that ships extensions/, package.json and
  #           its own node_modules/.
  #         - inputs.<flake> + "/extensions/foo.ts" for a bare source file.
  #
  # Caveats:
  #   - Store paths are read-only, so an extension must keep mutable config
  #     and runtime state outside its own directory.
  #   - A flake *source* tree has no node_modules/. Extensions importing npm
  #     dependencies need that flake's package output (or a local derivation)
  #     instead of the raw source path.
  #   - Pi only reads `pi.extensions` from a package directory reached through
  #     this directory. Its `pi.skills` / `pi.prompts` / `pi.themes` entries are
  #     only honoured for packages declared in `settings.json`, so link those
  #     resources separately below.
  #
  # Anything beyond a plain source (custom `target`, `recursive`, ...) is
  # better written as a regular `home.file` entry further down.
  piExtensions = {
    pi-furry-partner = pkgs.nur.repos.srcres258.pi-furry-partner-hd;
    pi-gpt-conv-decode =
      inputs.pi-gpt-conv-decode.packages.${system}.default;
  };

  mkExtensionLink = name: source:
    lib.nameValuePair ".pi/agent/extensions/${name}" { inherit source; };

  # Declarative Pi settings baseline.
  #
  # `~/.pi/agent/settings.json` must stay writable: Pi rewrites it itself
  # (`lastChangelogVersion`, `pi install` appending to `packages`, and
  # `setDefaultModelAndProvider` when a model switch is persisted), and a
  # read-only store symlink would make those writes fail. So the keys below are
  # merged into the existing file at activation time instead of being linked:
  # baseline keys win, every other key Pi wrote is preserved.
  #
  # Consequence: persisting a different model inside Pi only lasts until the
  # next `home-manager switch`, which restores the model set here.
  piSettings = {
    defaultProvider = "deepseek";
    defaultModel = "deepseek-flash";
  };
  piSettingsBaseline = pkgs.writeText "pi-settings-baseline.json"
    (builtins.toJSON piSettings);
  piSettingsPath = "${config.home.homeDirectory}/.pi/agent/settings.json";
in
{
  home.packages = [ inputs.pi.packages.${pkgs.system}.default ];

  home.file = lib.mapAttrs' mkExtensionLink piExtensions // {
    # Theme shipped by the pi-furry-partner package above. Resources under
    # `pi.themes` are dropped when the package is loaded as an extension.
    ".pi/agent/themes/pi-furry-night.json".source =
      "${piExtensions.pi-furry-partner}/themes/pi-furry-night.json";
  };

  # ── Activation: merge the Nix baseline into the Pi-written settings file ──
  home.activation.initPiSettings = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
    TARGET="${piSettingsPath}"
    BASELINE="${piSettingsBaseline}"

    mkdir -p "$(dirname "$TARGET")"
    if [ ! -f "$TARGET" ]; then
      # First run: seed the file from the baseline alone.
      install -m 0644 "$BASELINE" "$TARGET"
    else
      # Subsequent runs: recursive merge, baseline keys override.
      TMP="$(mktemp "$TARGET.XXXXXX")"
      if ${pkgs.jq}/bin/jq -s '.[0] * .[1]' "$TARGET" "$BASELINE" > "$TMP"; then
        chmod 644 "$TMP"
        # Only replace on a real change, so the mtime stays put otherwise.
        if cmp -s "$TMP" "$TARGET"; then
          rm -f "$TMP"
        else
          mv "$TMP" "$TARGET"
        fi
      else
        rm -f "$TMP"
        echo "initPiSettings: could not parse $TARGET as JSON, leaving it untouched" >&2
        exit 1
      fi
    fi
  '';
}
