{
  description = "opencode + opencode-openai-codex-auth config (repro devshell)";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";
  };

  outputs = { self, nixpkgs }:
    let
      system = "x86_64-linux";
      pkgs = nixpkgs.legacyPackages.${system};
    in
    {
      devShells.${system}.default = pkgs.mkShell {
        packages = [
          pkgs.opencode
          pkgs.jq
          pkgs.git
        ];
        shellHook = ''
          echo "Link config:"
          echo "  mkdir -p ~/.config/opencode"
          echo "  ln -sf $PWD/opencode.json ~/.config/opencode/opencode.json"
        '';
      };

      apps.${system}.opencode = {
        type = "app";
        program = "${pkgs.opencode}/bin/opencode";
      };
    };
}
