#!/usr/bin/env zsh
# shellcheck enable=all

source tests/utilities.zsh

# Run setup
setup

# Test the --surf flag
answer_should_contain "-count" "--task-model --surf how do i output the total number of matches from mdfind"

# Test the --search flag
answer_should_contain "-count" "--task-model --search \"mdfind options\" how do i output the total number of matches from mdfind"

# Test the --website flag
answer_should_contain "-count" "--task-model --website \"https://ss64.com/mac/mdfind.html\" how do i output the total number of matches from mdfind"

# Run cleanup
cleanup
