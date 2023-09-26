{ pkgs ? import ../../../nix { } }:
let shidod = (pkgs.callPackage ../../../. { });
in
shidod.overrideAttrs (oldAttrs: {
  patches = oldAttrs.patches or [ ] ++ [
    ./broken-shidod.patch
  ];
})
