#!/usr/bin/env zsh
# shellcheck enable=all

source tests/utilities.zsh

# Run setup
setup

# Run test for basic queries
answer_should_contain "Paris" "--task-model What is the capital of France"

# Run test for more queries with --surf flag
answer_should_contain "Rome" "--task-model what city is the vatican located in"

# Run test for more queries with --surf flag
answer_should_contain "German" "--task-model what nationality was Einstein"

# Run cleanup
cleanup
