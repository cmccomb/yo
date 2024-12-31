#!/usr/bin/env zsh
# shellcheck enable=all

source tests/utilities.zsh

# Run setup
setup

# Run test for basic queries
answer_should_contain "--help" "--task-model --usage what option can I use to see your help message"

# Run test for basic queries
answer_should_contain "--task-model" "--task-model --usage what are the options i can use to override the default model with the task model"

# Run cleanup
cleanup
