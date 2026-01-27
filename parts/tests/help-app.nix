{ ... }:
{
  perSystem =
    { pkgs, ... }:
    let
      help = pkgs.writeShellApplication {
        name = "help";
        runtimeInputs = [ pkgs.coreutils ];
        text = ''
          cat <<'EOF'
          Entrypoints (recommended)

          CI / DoD:
            nix flake check
            nix run .#test-integration
            nix run .#test-e2e

          Human (interactive):
            # Editor
            nix shell .#editor-tools

            # Git tools (lazygit + delta)
            nix shell .#git-tools

            # Verify lazygit+delta integration
            nix run .#test-lazygit-delta

            # Lazygit
            nix shell .#git-tools -c lazygit -p "$PWD"

            # Editor + language tooling (example: Go)
            nix shell .#editor-tools .#go-tooling

            # One-shot command examples
            nix shell .#editor-tools -c opencode --version
            nix shell .#editor-tools -c hx --version
            nix shell .#editor-tools .#go-tooling -c opencode debug lsp diagnostics path/to/file.go
          EOF
        '';
      };
    in
    {
      apps.help = {
        type = "app";
        program = "${help}/bin/help";
        meta.description = "Print recommended repo entrypoints";
      };
    };
}
