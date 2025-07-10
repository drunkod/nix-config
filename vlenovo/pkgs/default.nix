# Custom packages, that can be defined similarly to ones from nixpkgs
# You can build them using 'nix build .#example'
pkgs: let
  frontends = pkgs.callPackage ./codemadness-frontends { };
in {
  # example = pkgs.callPackage ./example { };
  codemadness-frontends = frontends;
  sxmo-utils = pkgs.callPackage ./sxmo-1.17.1 { codemadness-frontends = frontends; };
}
