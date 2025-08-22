#!/usr/bin/env sh
# shellcheck enable=all

# Test the --version flag
version_output=$(src/main.sh --version)
if echo "$version_output" | grep -qE '^yo v[0-9]+\.[0-9]+\.[0-9]+'; then
    echo "Version flag output: $version_output"
else
    echo "Unexpected version output: $version_output" >&2
    exit 1
fi

# Test the --help flag
help_output=$(src/main.sh --help)
if echo "$help_output" | grep -q "yo - A command-line AI assistant"; then
    echo "Help flag output contains expected description"
else
    echo "Help output missing description" >&2
    exit 1
fi

exit 0
