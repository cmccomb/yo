#!/usr/bin/env zsh

function setup() {
  # Make sure zsh exists, and install if not
  if ! command -v yo &> /dev/null; then
    echo "Yo is not installed. Installing..."
    zsh <(curl -s https://cmccomb.com/yo/install)
  fi

  # Warm up yo
  yo say hi -tm

  PASSES=0
  FAILS=0
}

function cleanup() {
  echo "Tests complete. ${PASSES} passed, ${FAILS} failed."
  if [[ $FAILS -gt 0 ]]; then
    exit 1
  else
    exit 0
  fi
}

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
    ((PASSES+=1))
    return 0
  else
    echo "  ❌ Test failed in ${elapsed_time}s with answer: ${output}"
    ((FAILS+=1))
    return 1
  fi
}