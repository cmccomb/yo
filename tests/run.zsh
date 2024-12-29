#!/usr/bin/env zsh

source src || source ../src

function answer_should_contain() {
  # Parse arguments
  local expected=$1
  local query="${*:2}"

  # Print test description
  echo "Testing query: 'yo ${query}' (answer must contain \"${expected}\")"

  # Measure start time
  local start_time
  start_time=$(gdate +%s.%N)

  # Make variables
  local output
  output=$(eval "yo ${query} --quiet")

  # Measure end time
  local end_time
  end_time=$(gdate +%s.%N)

  # Calculate elapsed time
  local elapsed_time
  elapsed_time=$(echo "$end_time - $start_time" | bc | awk '{printf "%.2f", $0}')

  if [[ $output == *"${expected}"* ]]; then
    echo "  ✅ Test passed in ${elapsed_time}s with answer: ${output}"
    return 0
  else
    echo "  ❌ Test failed in ${elapsed_time}s with answer: ${output}"
    return 1
  fi
}

# Run test for basic queries with model overrides
answer_should_contain "Paris" "What is the capital of France --task-model"
answer_should_contain "asdf" "What is the capital of France --casual-model"
answer_should_contain "Paris" "What is the capital of France --balanced-model"
answer_should_contain "Paris" "What is the capital of France --serious-model"

# Test --usage flag
answer_should_contain "--help" "--usage what flag should i use to get help for the yo command --task-model"

# Run test for more queries with --surf flag
answer_should_contain "Rome" "--surf what city is the vatican located in --task-model"