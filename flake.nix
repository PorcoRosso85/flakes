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
          ./parts/devshell/default.nix
          ./parts/lazygit-delta/default.nix
          ./parts/repo-checks.nix

          ./parts/opencode/devshell.nix
          ./parts/opencode/checks.nix

          ./parts/helix/contract.nix

          ./parts/languages/python.nix
          ./parts/languages/bun.nix
          ./parts/languages/rust.nix
          ./parts/languages/go.nix
          ./parts/languages/zig.nix
          ./parts/languages/nix.nix
          ./parts/languages/cue.nix
          ./parts/languages/contract.nix
        ];

        flake.flakeModules = {
          default = ./parts/opencode/devshell.nix;
          devshell = ./parts/opencode/devshell.nix;
          devshellCheck = ./parts/opencode/checks.nix;
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
