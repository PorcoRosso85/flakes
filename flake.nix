{
  description = "opencode (v1.0.222) + opencode-openai-codex-auth devshell";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";
    opencode.url = "github:sst/opencode/v1.0.222";
  };

  outputs = { self, nixpkgs, opencode }:
    let
      system = "x86_64-linux";
      pkgs = nixpkgs.legacyPackages.${system};
      opencodeBin = pkgs.writeShellScriptBin "opencode" ''
        exec nix run ${opencode.outPath} -- "$@"
      '';
    in
    {
      devShells.${system}.default = pkgs.mkShell {
        packages = [
          opencodeBin
          pkgs.jq
          pkgs.git
        ];
        shellHook = ''
          echo "opencode pinned: v1.0.222"
          echo "Link config:"
          echo "  mkdir -p ~/.config/opencode"
          echo "  ln -sf $PWD/opencode.json ~/.config/opencode/opencode.json"
        '';
      };
    };
}
