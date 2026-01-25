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
nix develop .#edit
```

## Usage

```bash
# Example: run opencode with the repo config
nix develop .#edit
opencode

# Example: authenticate (requires network and user interaction)
opencode auth login

# Example: smoke
opencode --version
```

## Files

- `opencode.json`: Configuration with plugin pinned at `@4.2.0`
- `flake.nix`: DevShell with opencode, jq, git
- `parts/languages/*.nix`: Language tooling parts (v1 contract)

## DoD

- [ ] `~/.config/opencode/opencode.json` is symlinked
- [ ] `~/.local/share/opencode/auth.json` exists (authenticated)
- [ ] `opencode run "hello" --model=openai/gpt-5.1-codex-low` returns response
