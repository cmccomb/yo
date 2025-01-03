#!/usr/bin/env zsh
# shellcheck enable=all

source tests/utilities.zsh

# Run setup
setup

# Test the --system flag
answer_should_contain "$(sysctl -n hw.ncpu)" "--task-model --system how many cores do i have"

# Test the --directory flag
answer_should_contain "$(pwd)" "--task-model --directory what directory am I in"

# Test the --file flag
echo "red is better than blue" > "secret.txt"
answer_should_contain "Red" "--task-model --file secret.txt in one word what is better than blue"

# Run cleanup
cleanup
