"""Example test rule using the runtime toolchain."""

load("@tools_claude//claude:defs.bzl", "CLAUDE_RUNTIME_TOOLCHAIN_TYPE")

def _claude_version_test_impl(ctx):
    toolchain = ctx.toolchains[CLAUDE_RUNTIME_TOOLCHAIN_TYPE]
    claude_binary = toolchain.claude_info.binary

    test_script = ctx.actions.declare_file(ctx.label.name + ".sh")
    ctx.actions.write(
        output = test_script,
        content = """#!/bin/bash
set -e
export HOME="$TEST_TMPDIR"
echo "Claude binary: {claude}"
{claude} --version
""".format(claude = claude_binary.short_path),
        is_executable = True,
    )
    return [DefaultInfo(
        executable = test_script,
        runfiles = ctx.runfiles(files = [claude_binary]),
    )]

claude_version_test = rule(
    implementation = _claude_version_test_impl,
    test = True,
    toolchains = [CLAUDE_RUNTIME_TOOLCHAIN_TYPE],
)
