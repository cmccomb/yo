#!/usr/bin/env zsh

source tests/utilities.zsh

# Run setup
setup

# Run test for basic queries
answer_should_contain "Paris" "What is the capital of France"

# Run test for more queries with --surf flag
answer_should_contain "Rome" "--surf what city is the vatican located in --task-model"

# Test model overrides
answer_should_contain "Paris" "What is the capital of France --task-model"
answer_should_contain "Paris" "What is the capital of France --balanced-model"
answer_should_contain "Paris" "What is the capital of France --serious-model"

# Run cleanup
cleanup