{
  description = "opencode + opencode-openai-codex-auth devshell";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
  };

  outputs = { self, nixpkgs }:
    let
      system = "x86_64-linux";
      pkgs = nixpkgs.legacyPackages.${system};

      opencodeBin = pkgs.writeShellScriptBin "opencode" ''
        exec nix run github:NixOS/nixpkgs/nixos-unstable#opencode -- "$@"
      '';
    in {
      devShells.${system}.default = pkgs.mkShell {
        packages = [ opencodeBin pkgs.jq pkgs.git ];
        shellHook = ''
          echo "opencode: nixpkgs/nixos-unstable#opencode (v$(nix eval --raw github:NixOS/nixpkgs/nixos-unstable#opencode.version 2>/dev/null || echo 'unknown'))"
          echo ""
          echo "Link config:"
          echo "  mkdir -p ~/.config/opencode"
          echo "  ln -sf $PWD/opencode.json ~/.config/opencode/opencode.json"
        '';
      };
    };
}
