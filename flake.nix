{
  description = "opencode-auth: devShell for OpenCode OAuth config";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";

    flake-parts = {
      url = "github:hercules-ci/flake-parts";
      inputs.nixpkgs-lib.follows = "nixpkgs";
    };

    opencode = {
      url = "github:anomalyco/opencode/v1.1.6";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs =
    inputs@{ flake-parts, ... }:
    let
      result = flake-parts.lib.mkFlake { inherit inputs; } {
        systems = [
          "x86_64-linux"
          "aarch64-linux"
        ];

        imports = [
          ./parts/devshell.nix
          ./parts/devshell-check.nix
          ./parts/devshell/default.nix
          ./parts/cue.nix
          ./parts/lazygit-delta/default.nix
        ];

        flake.flakeModules = {
          default = ./parts/devshell.nix;
          devshell = ./parts/devshell.nix;
          devshellCheck = ./parts/devshell-check.nix;
        };
      };
    in
    result
    // {
      lib = (result.lib or { }) // {
        mkGitGhShell = { pkgs, ... }@args: import ./parts/devshell/mkGitGhShell.nix args;
      };
    };
}
