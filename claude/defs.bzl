"""Public API for tools_claude."""

load(
    "//claude/private:toolchain.bzl",
    _CLAUDE_RUNTIME_TOOLCHAIN_TYPE = "CLAUDE_RUNTIME_TOOLCHAIN_TYPE",
    _CLAUDE_TOOLCHAIN_TYPE = "CLAUDE_TOOLCHAIN_TYPE",
    _ClaudeInfo = "ClaudeInfo",
    _claude_toolchain = "claude_toolchain",
)

# Toolchain
claude_toolchain = _claude_toolchain
ClaudeInfo = _ClaudeInfo
CLAUDE_TOOLCHAIN_TYPE = _CLAUDE_TOOLCHAIN_TYPE
CLAUDE_RUNTIME_TOOLCHAIN_TYPE = _CLAUDE_RUNTIME_TOOLCHAIN_TYPE
