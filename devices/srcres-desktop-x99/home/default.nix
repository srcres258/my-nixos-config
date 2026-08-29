{ pkgs
, ...
}: {
  my.python.packageGenerator = (ps: with ps; [
    # torchWithRocm
    # (torchvision.override { torch = ps.torchWithRocm; })

    torch
    torchvision
  ]);

  # !IMPORTANT!
  # This option should NOT be changed, except for installation
  # for a completely new machine or a new user.
  home.stateVersion = "26.05";
}
