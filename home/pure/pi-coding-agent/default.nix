{ pkgs, inputs, ... }:

{
  # Installed straight from the upstream pi flake, which only exports
  # packages/apps/overlays (no Home Manager module). Declarative config
  # files under ~/.pi/agent would have to be maintained here by hand.
  home.packages = [ inputs.pi.packages.${pkgs.system}.default ];
}
