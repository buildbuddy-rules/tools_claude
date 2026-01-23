"""Claude Code toolchain definitions."""

ClaudeInfo = provider(
    doc = "Information about the Claude Code CLI.",
    fields = {
        "binary": "The Claude Code executable file.",
    },
)

def _claude_toolchain_impl(ctx):
    """Implementation of the Claude toolchain."""
    toolchain_info = platform_common.ToolchainInfo(
        claude_info = ClaudeInfo(
            binary = ctx.file.claude,
        ),
    )
    return [toolchain_info]

claude_toolchain = rule(
    implementation = _claude_toolchain_impl,
    attrs = {
        "claude": attr.label(
            doc = "The Claude Code CLI binary.",
            allow_single_file = True,
            mandatory = True,
        ),
    },
    doc = "Defines a Claude Code toolchain.",
)

CLAUDE_TOOLCHAIN_TYPE = "@tools_claude//claude:toolchain_type"
