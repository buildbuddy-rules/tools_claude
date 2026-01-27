# tools_claude

Bazel toolchain for [Claude Code](https://github.com/anthropics/claude-code) - Anthropic's AI coding assistant CLI.

## Setup

Add the dependency to your `MODULE.bazel` using `git_override`:

```starlark
bazel_dep(name = "tools_claude", version = "0.1.0")
git_override(
    module_name = "tools_claude",
    remote = "https://github.com/buildbuddy-rules/tools_claude.git",
    commit = "775f240df9ebac5e9e4c4c55debca873a6cd0ab2",
)
```

The toolchain is automatically registered and downloads the latest Claude Code binary.

### Pinning a Claude Code version

To pin a specific Claude Code CLI version:

```starlark
claude = use_extension("@tools_claude//claude:claude.bzl", "claude")
claude.download(version = "1.0.30")
```

## Usage

### In custom rules

Use the toolchain in your rule implementation:

```starlark
load("@tools_claude//claude:defs.bzl", "CLAUDE_TOOLCHAIN_TYPE")

def _my_rule_impl(ctx):
    toolchain = ctx.toolchains[CLAUDE_TOOLCHAIN_TYPE]
    claude_binary = toolchain.claude_info.binary

    # Use claude_binary in your actions
    ctx.actions.run(
        executable = claude_binary,
        arguments = ["--help"],
        # ...
    )

my_rule = rule(
    implementation = _my_rule_impl,
    toolchains = [CLAUDE_TOOLCHAIN_TYPE],
)
```

### Public API

From `@tools_claude//claude:defs.bzl`:

| Symbol | Description |
|--------|-------------|
| `CLAUDE_TOOLCHAIN_TYPE` | Toolchain type string for use in `toolchains` attribute |
| `ClaudeInfo` | Provider with `binary` field containing the Claude Code executable |
| `claude_toolchain` | Rule for defining custom toolchain implementations |

## Supported platforms

- `darwin_arm64` (macOS Apple Silicon)
- `darwin_amd64` (macOS Intel)
- `linux_arm64`
- `linux_amd64`

## Requirements

- Bazel 7.0+ with bzlmod enabled
- `ANTHROPIC_API_KEY` environment variable for Claude Code to function
