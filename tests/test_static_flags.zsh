#!/usr/bin/env zsh

source tests/utilities.zsh

# Run setup
setup

# Run test for basic queries
answer_should_contain "--help" "--task-model --usage what option should I use to see your help message"

# Run test for basic queries
answer_should_contain "--task-model" "--task-model --usage what option should I use to override with the task model"

# Run cleanup
cleanup
