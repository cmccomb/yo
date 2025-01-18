#!/usr/bin/env zsh
# shellcheck enable=all

source tests/utilities.zsh

# Run setup
setup

# Run test for basic queries
answer_should_contain \
  "Paris" \
  "--task-model" \
  "What is the capital of France"

# Run test for more queries
answer_should_contain \
  "Italy" \
  "--task-model" \
  "what country is rome located in"

# Run test for more queries
answer_should_contain \
  "German" \
  "--task-model" \
  "what nationality was Einstein"

# Run test for basic queries
answer_should_contain \
  "beans" \
  "--task-model" \
  "one word answer only is coffee made from beans or fruit"

# Run cleanup
cleanup
