# opencode-auth

OpenCode + opencode-openai-codex-auth configuration for OAuth authentication with ChatGPT Plus/Pro (Codex Subscription).

## Entrypoints

### CI / DoD

```bash
nix flake check
nix run .#test-integration
nix run .#test-e2e
```

### Human (interactive)

```bash
# Show quick help
nix run .#help

# Editor tools (hx, opencode)
nix shell .#editor-tools

# Git tools
nix shell .#git-tools

# Editor + language tooling (example: Go)
nix shell .#editor-tools .#go-tooling
```

## Usage

```bash
# Example: show help
nix run .#help

# Example: run opencode with repo config
nix shell .#editor-tools -c opencode

# Example: authenticate (requires network and user interaction)
opencode auth login

# Example: smoke
opencode --version
```

## Files

- `opencode.json`: Minimal vanilla config (schema only)
- `flake.nix`: flake-parts setup (no devShells)
- `parts/languages/*.nix`: Language tooling parts (v1 contract)

## DoD

- [ ] `~/.config/opencode/opencode.json` is symlinked
- [ ] `~/.local/share/opencode/auth.json` exists (authenticated)
- [ ] `opencode run "hello" --model=openai/gpt-5.1-codex-low` returns response
