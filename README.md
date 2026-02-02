![tools_claude](tools_claude.png)

# tools_claude

Hermetic, cross-platform Bazel toolchain for [Claude Code](https://github.com/anthropics/claude-code) - Anthropic's AI coding assistant CLI. If you want a Bazel ruleset that uses this toolchain, see [rules_claude](https://github.com/buildbuddy-rules/rules_claude).

## Setup

Add the dependency to your `MODULE.bazel` using `git_override`:

```starlark
bazel_dep(name = "tools_claude", version = "0.1.0")
git_override(
    module_name = "tools_claude",
    remote = "https://github.com/buildbuddy-rules/tools_claude.git",
    commit = "50ec71d17d4352cd2a48e0c16d564e27841a62ff",
)
```

The toolchain is automatically registered. By default, it downloads version `2.1.25` with SHA256 verification for reproducible builds.

### Pinning a Claude Code version

To pin a specific Claude Code CLI version:

```starlark
claude = use_extension("@tools_claude//claude:claude.bzl", "claude")
claude.download(version = "2.0.0")
```

### Using the latest version

To always fetch the latest version:

```starlark
claude = use_extension("@tools_claude//claude:claude.bzl", "claude")
claude.download(use_latest = True)
```

## Usage

### In genrule

Use the toolchain in a genrule via `toolchains` and make variable expansion:

```starlark
load("@tools_claude//claude:defs.bzl", "CLAUDE_TOOLCHAIN_TYPE")

genrule(
    name = "my_genrule",
    srcs = ["input.py"],
    outs = ["output.md"],
    cmd = """
        export HOME=.home
        $(CLAUDE_BINARY) --dangerously-skip-permissions -p \
            'Read $(location input.py) and write API documentation to $@'
    """,
    toolchains = [CLAUDE_TOOLCHAIN_TYPE],
)
```

The `$(CLAUDE_BINARY)` make variable expands to the path of the Claude Code binary.

**Note:** The `export HOME=.home` line is required because Bazel runs genrules in a sandbox where the real home directory is not writable. Claude Code writes configuration and debug files to `$HOME`, so redirecting it to a writable location within the sandbox prevents permission errors. The `--dangerously-skip-permissions` flag allows Claude to read and write files without interactive approval.

### In custom rules

Use the toolchain in your rule implementation:

```starlark
load("@tools_claude//claude:defs.bzl", "CLAUDE_TOOLCHAIN_TYPE")

def _my_rule_impl(ctx):
    toolchain = ctx.toolchains[CLAUDE_TOOLCHAIN_TYPE]
    claude_binary = toolchain.claude_info.binary

    out = ctx.actions.declare_file(ctx.label.name + ".md")
    ctx.actions.run(
        executable = claude_binary,
        arguments = [
            "--dangerously-skip-permissions",
            "-p",
            "Read {} and write API documentation to {}".format(ctx.file.src.path, out.path),
        ],
        inputs = [ctx.file.src],
        outputs = [out],
        env = {"HOME": ".home"},
        use_default_shell_env = True,
    )
    return [DefaultInfo(files = depset([out]))]

my_rule = rule(
    implementation = _my_rule_impl,
    attrs = {
        "src": attr.label(allow_single_file = True, mandatory = True),
    },
    toolchains = [CLAUDE_TOOLCHAIN_TYPE],
)
```

### In tests

For tests that need to run the Claude binary at runtime, use the runtime toolchain type. This ensures the binary matches the target platform where the test executes:

```starlark
load("@tools_claude//claude:defs.bzl", "CLAUDE_RUNTIME_TOOLCHAIN_TYPE")

def _claude_test_impl(ctx):
    toolchain = ctx.toolchains[CLAUDE_RUNTIME_TOOLCHAIN_TYPE]
    claude_binary = toolchain.claude_info.binary

    test_script = ctx.actions.declare_file(ctx.label.name + ".sh")
    ctx.actions.write(
        output = test_script,
        content = """#!/bin/bash
export HOME="$TEST_TMPDIR"
{claude} --version
""".format(claude = claude_binary.short_path),
        is_executable = True,
    )
    return [DefaultInfo(
        executable = test_script,
        runfiles = ctx.runfiles(files = [claude_binary]),
    )]

claude_test = rule(
    implementation = _claude_test_impl,
    test = True,
    toolchains = [CLAUDE_RUNTIME_TOOLCHAIN_TYPE],
)
```

### Toolchain types

There are two toolchain types depending on your use case:

- **`CLAUDE_TOOLCHAIN_TYPE`** - Use for build-time actions (genrules, custom rules). Selected based on the execution platform. Use this when Claude's output isn't platform-specific.

- **`CLAUDE_RUNTIME_TOOLCHAIN_TYPE`** - Use for tests or run targets where the Claude binary executes on the target platform.

### Public API

From `@tools_claude//claude:defs.bzl`:

| Symbol | Description |
|--------|-------------|
| `CLAUDE_TOOLCHAIN_TYPE` | Toolchain type for build actions (exec platform only) |
| `CLAUDE_RUNTIME_TOOLCHAIN_TYPE` | Toolchain type for test/run (target platform) |
| `ClaudeInfo` | Provider with `binary` field containing the Claude Code executable |
| `claude_toolchain` | Rule for defining custom toolchain implementations |

## Supported platforms

- `darwin_arm64` (macOS Apple Silicon)
- `darwin_amd64` (macOS Intel)
- `linux_arm64`
- `linux_amd64`

## Authentication

Claude Code requires an `ANTHROPIC_API_KEY` to function. Since Bazel runs actions in a sandbox, you need to explicitly pass the API key through using `--action_env`.

### Option 1: Pass from environment

To pass the API key from your shell environment, add to your `.bazelrc`:

```
common --action_env=ANTHROPIC_API_KEY
```

Then ensure `ANTHROPIC_API_KEY` is set in your shell before running Bazel.

### Option 2: Hardcode in user.bazelrc

For convenience, you can hardcode the API key in a `user.bazelrc` file that is gitignored:

1. Add `user.bazelrc` to your `.gitignore`:
   ```
   echo "user.bazelrc" >> .gitignore
   ```

2. Create a `.bazelrc` that imports `user.bazelrc`:
   ```
   echo "try-import %workspace%/user.bazelrc" >> .bazelrc
   ```

3. Create `user.bazelrc` with your API key:
   ```
   common --action_env=ANTHROPIC_API_KEY=sk-ant-...
   ```

## Requirements

- Bazel 7.0+ with bzlmod enabled

## Acknowledgements

Claude and Claude Code are trademarks of Anthropic, PBC.
