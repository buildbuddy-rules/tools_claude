"""Repository rule for downloading the Claude Code CLI binary."""

_CLAUDE_BUCKET_URL = "https://storage.googleapis.com/claude-code-dist-86c565f3-f756-42ad-8dfa-d59b1c096819/claude-code-releases"

_PLATFORMS = {
    "darwin_arm64": "darwin-arm64",
    "darwin_amd64": "darwin-x64",
    "linux_arm64": "linux-arm64",
    "linux_amd64": "linux-x64",
}

def _get_platform(repository_ctx):
    """Determine the current platform."""
    os_name = repository_ctx.os.name.lower()
    arch = repository_ctx.os.arch

    if "mac" in os_name or "darwin" in os_name:
        os_key = "darwin"
    elif "linux" in os_name:
        os_key = "linux"
    else:
        fail("Unsupported operating system: {}".format(os_name))

    if arch == "aarch64" or arch == "arm64":
        arch_key = "arm64"
    elif arch == "x86_64" or arch == "amd64":
        arch_key = "amd64"
    else:
        fail("Unsupported architecture: {}".format(arch))

    return "{}_{}".format(os_key, arch_key)

def _claude_toolchains_impl(repository_ctx):
    """Download the Claude Code binary for the specified or current platform."""
    # Use specified platform or detect current
    platform = repository_ctx.attr.platform
    if not platform:
        platform = _get_platform(repository_ctx)

    if platform not in _PLATFORMS:
        fail("Unsupported platform: {}".format(platform))

    platform_path = _PLATFORMS[platform]

    # Get version - use provided version or fetch latest
    version = repository_ctx.attr.version
    if not version:
        repository_ctx.report_progress("Fetching latest Claude Code version...")
        repository_ctx.download(
            url = "{}/latest".format(_CLAUDE_BUCKET_URL),
            output = "version.txt",
        )
        version = repository_ctx.read("version.txt").strip()
        repository_ctx.delete("version.txt")

    # Download the binary
    binary_url = "{}/{}/{}/claude".format(_CLAUDE_BUCKET_URL, version, platform_path)
    repository_ctx.report_progress("Downloading Claude Code {} for {}".format(version, platform))

    repository_ctx.download(
        url = binary_url,
        output = "claude",
        executable = True,
    )

    # Write version file for reference
    repository_ctx.file("VERSION", version)

    # Create BUILD file
    repository_ctx.file(
        "BUILD.bazel",
        content = '''
package(default_visibility = ["//visibility:public"])

exports_files(["claude"])
''',
    )

claude_toolchains = repository_rule(
    implementation = _claude_toolchains_impl,
    attrs = {
        "version": attr.string(
            doc = "Version to download. If empty, downloads the latest version.",
        ),
        "platform": attr.string(
            doc = "Platform to download for (e.g., 'darwin_arm64'). If empty, detects current platform.",
        ),
    },
    doc = "Downloads the Claude Code CLI binary for the specified platform.",
)
