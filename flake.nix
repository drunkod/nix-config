{
  description = "NixOS + standalone home-manager config flakes to get you started!";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";
  };

  outputs = {nixpkgs, ...}: let
    forAllSystems = nixpkgs.lib.genAttrs [
      "aarch64-linux"
      "i686-linux"
      "x86_64-linux"
      "aarch64-darwin"
      "x86_64-darwin"
    ];
  in {
    templates = {
      minimal = {
        description = ''
          Minimal flake - contains only the configs.
          Contains the bare minimum to migrate your existing legacy configs to flakes.
        '';
        path = ./minimal;
      };
      standard = {
        description = ''
          Standard flake - augmented with boilerplate for custom packages, overlays, and reusable modules.
          Perfect migration path for when you want to dive a little deeper.
        '';
        path = ./standard;
      };
      lenovo = {
        description = ''
          lenovo flake - augmented with boilerplate for custom packages, overlays, and reusable modules.
          Perfect migration path for when you want to dive a little deeper.
        '';
        path = ./lenovo;
      };
      vlenovo = {
        description = ''
          vlenovo flake - augmented with boilerplate for custom packages, overlays, and reusable modules.
          Perfect migration path for when you want to dive a little deeper.
        '';
        path = ./vlenovo;
      };
      acer = {
        description = ''
          acer flake - augmented with boilerplate for custom packages, overlays, and reusable modules.
          Perfect migration path for when you want to dive a little deeper.
        '';
        path = ./acer;
      };
      
    };
    formatter = forAllSystems (system: nixpkgs.legacyPackages.${system}.alejandra);
  };
}
