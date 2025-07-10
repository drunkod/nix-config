# Custom packages, that can be defined similarly to ones from nixpkgs
# You can build them using 'nix build .#example'
pkgs: let
  frontends = pkgs.callPackage ./codemadness-frontends { };
in {
  # example = pkgs.callPackage ./example { };
  codemadness-frontends = frontends;
  sxmo-utils = pkgs.callPackage ./sxmo-1.17.1 {
    # Pass the entire pkgs set. callPackage will find the dependencies it needs.
    # We override yt-dlp to get a newer version from the unstable channel.
    codemadness-frontends = frontends;
    yt-dlp = pkgs.unstable.yt-dlp;
  };
}
