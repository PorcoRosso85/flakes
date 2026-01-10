{
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    flake-parts.url = "github:hercules-ci/flake-parts";
    opencode.url = "github:anomalyco/opencode/v1.1.6";
  };

  outputs =
    inputs@{ flake-parts, ... }:
    flake-parts.lib.mkFlake { inherit inputs; } {
      systems = [
        "x86_64-linux"
        "aarch64-linux"
      ];

      imports = [
        ./parts/devshell.nix
        ./parts/devshell-check.nix
      ];

      flake.flakeModules.default = ./parts/devshell.nix;
    };
}
