{ inputs, ... }:
{
  perSystem =
    { pkgs, ... }:
    let
      cue-v15 = pkgs.buildGoModule rec {
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
    in
    {
      packages.cue-v15 = cue-v15;

      checks.cue-smoke = pkgs.runCommand "cue-smoke" { nativeBuildInputs = [ cue-v15 ]; } ''
        cue version >/dev/null
        touch $out
      '';
    };
}
