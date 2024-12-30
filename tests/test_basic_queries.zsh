#!/usr/bin/env zsh

source tests/utilities.zsh

# Run setup
setup

# Run test for basic queries
answer_should_contain "Paris" "What is the capital of France --task-model"

# Run test for more queries with --surf flag
answer_should_contain "Rome" "what city is the vatican located in --task-model"

# Run test for more queries with --surf flag
answer_should_contain "German" "what nationality was Einstein --task-model"

# Run cleanup
cleanup
