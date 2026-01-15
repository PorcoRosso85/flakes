# opencode-auth

OpenCode + opencode-openai-codex-auth configuration for OAuth authentication with ChatGPT Plus/Pro (Codex Subscription).

## Usage

```bash
# Enter devShell (includes opencode, jq, git)
nix develop

# Link config globally
mkdir -p ~/.config/opencode
ln -sf "$PWD/opencode.json" ~/.config/opencode/opencode.json

# Reset cache (if needed)
rm -rf ~/.cache/opencode/node_modules ~/.cache/opencode/bun.lock

# Start opencode
opencode

# Authenticate (stop Codex CLI on port 1455 first)
pkill -f codex || true
opencode auth login
# Select: OpenAI → ChatGPT Plus/Pro (Codex Subscription)

# Test
opencode run "hello" --model=openai/gpt-5.1-codex-low
```

## Files

- `opencode.json`: Configuration with plugin pinned at `@4.2.0`
- `flake.nix`: DevShell with opencode, jq, git
- `parts/languages/*.nix`: Language tooling parts (v1 contract)

## DoD

- [ ] `~/.config/opencode/opencode.json` is symlinked
- [ ] `~/.local/share/opencode/auth.json` exists (authenticated)
- [ ] `opencode run "hello" --model=openai/gpt-5.1-codex-low` returns response
