{ ... }:
{
  perSystem =
    { pkgs, ... }:
    let
      cuePkg = pkgs.buildGoModule rec {
        pname = "cue";
        version = "0.15.1";
        src = pkgs.fetchFromGitHub {
          owner = "cue-lang";
          repo = "cue";
          rev = "v${version}";
          hash = "sha256-0DxJK5S1uWR5MbI8VzUxQv+YTwIIm1yK77Td+Qf278I=";
        };
        vendorHash = "sha256-ivFw62+pg503EEpRsdGSQrFNah87RTUrRXUSPZMFLG4=";
        subPackages = [ "cmd/cue" ];
        ldflags = [
          "-s"
          "-w"
          "-X cuelang.org/go/cmd/cue/cmd.version=v${version}"
        ];
      };

      cueTooling = pkgs.symlinkJoin {
        name = "cue-tooling";
        paths = [ cuePkg ];
      };

      cueLsp = pkgs.writeShellScriptBin "cue-lsp" ''
        exec cue lsp "$@"
      '';

      cueFmt = pkgs.writeShellScriptBin "cue-fmt" ''
        exec cue fmt "$@"
      '';

      cueLint = pkgs.writeShellScriptBin "cue-lint" ''
        # Minimal lint wrapper: keep it generic, project supplies args.
        exec cue vet "$@"
      '';
    in
    {
      packages.cue-tooling = cueTooling;
      packages.cue-lsp = cueLsp;
      packages.cue-lint = cueLint;
      packages.cue-fmt = cueFmt;

      devShells.cue = pkgs.mkShell {
        packages = [ cueTooling ];
      };

      checks.cue-smoke = pkgs.runCommand "cue-smoke" { nativeBuildInputs = [ cueTooling ]; } ''
        set -euo pipefail

        cue version >/dev/null
        cue lsp --help >/dev/null

        touch "$out"
      '';
    };
}
