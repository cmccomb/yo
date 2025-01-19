#!/usr/bin/env zsh
# shellcheck enable=all

source tests/utilities.zsh

# Run setup
setup

# Test the --usage flag
answer_should_contain \
	"-h|--help" \
	"--task-model --usage" \
	"what option can I use to see your help message"
answer_should_contain \
	"-tm|--task-model" \
	"--task-model --usage" \
	"what are the options i can use to override the default model with the task model"

# Run cleanup
cleanup
