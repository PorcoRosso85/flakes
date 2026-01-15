package languages

// SSOT decisions for parts/languages/*

// bun-ts-runtime-policy:
// bun を JS/TS 系の slug として固定する。
// ただし TypeScript の tsc / typescript-language-server は実行時に Node.js を必要とし得るため、
// "nodeを直接使わない" を維持しつつ、推移依存としての node を許容する。

ts_runtime_policy: {
  slug: "bun"
  node_transitive_runtime_allowed: true
  note: "bun is the SSOT slug; tsc/ts-lsp may depend on node at runtime"
}

nix_formatter_choice: {
  formatter: "nixfmt-rfc-style"
  note: "Prefer nixfmt-rfc-style as the Nix formatter SSOT"
}

zig_lint_policy: {
  lint_command: "zig fmt --check"
  note: "Zig has no dedicated linter; treat format-check as lint to satisfy contract v1"
}

breaking_remove_parts_cue: {
  allow: false
  note: "Keep legacy cue shim file until all consumers migrate"
}
