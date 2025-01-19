#!/usr/bin/env zsh
# shellcheck enable=all

source tests/utilities.zsh

# Run setup
setup

# Run test for yo update
answer_should_contain \
  "" \
  "" \
  "update"

# Run test for yo settings
answer_should_contain "Llama-3.2-1B-Instruct-Q4_K_M.gguf" "settings"

# Run test for yo settings model.task.temperature
answer_should_contain "0.2" "settings model.task.temperature"

# Run test for yo settings model.task.temperature
answer_should_contain "New value for model.task.temperature: 0.1" "settings model.task.temperature 0.1"

# Run cleanup
cleanup
