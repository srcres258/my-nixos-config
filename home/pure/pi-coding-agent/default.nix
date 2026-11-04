{ pkgs
, lib
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
  # `~/.pi/agent/settings.json` alone, which Pi writes itself
  # (`lastChangelogVersion`, `pi install` adding to `packages`, ...).
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
in
{
  home.packages = [ inputs.pi.packages.${pkgs.system}.default ];

  home.file = lib.mapAttrs' mkExtensionLink piExtensions // {
    # Theme shipped by the pi-furry-partner package above. Resources under
    # `pi.themes` are dropped when the package is loaded as an extension.
    ".pi/agent/themes/pi-furry-night.json".source =
      "${piExtensions.pi-furry-partner}/themes/pi-furry-night.json";
  };
}
