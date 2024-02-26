{ pkgs ? import ../../../nix { } }:
let anrytond = (pkgs.callPackage ../../../. { });
in
anrytond.overrideAttrs (oldAttrs: {
  patches = oldAttrs.patches or [ ] ++ [
    ./broken-anrytond.patch
  ];
})
