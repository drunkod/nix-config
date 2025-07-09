# Custom packages, that can be defined similarly to ones from nixpkgs
# You can build them using 'nix build .#example'
pkgs: {
  # example = pkgs.callPackage ./example { };
  codemadness-frontends = pkgs.callPackage ./codemadness-frontends { };
  sxmo-utils = pkgs.callPackage ./sxmo-1.13.0 { };
}
