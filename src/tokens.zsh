#!/usr/bin/env zsh
# shellcheck enable=all

########################################################################################################################
### TOKEN COUNTING FUNCTIONS ###########################################################################################
########################################################################################################################

# Write a function to convert tokens to characters
function tokens_to_characters() {

	# Parse arguments
	local tokens=$1

	# Check that inputs are valid
	check_integer tokens || return 1

	# Make variables
	local characters

	# Calculate the number of characters and divide by four
	characters=$(((tokens * ${CHARACTERS_PER_TOKEN:-"4"}) / ${TOKEN_ESTIMATION_CORRECTION_FACTOR:-"1.2"}))

	# Return result
	printf "%.0f" "${characters}"

	# Return successfully
	return 0
}

# Write a function to convert tokens to characters
function characters_to_tokens() {

	# Parse arguments
	local characters=$1

	# Check that inputs are valid
	check_integer characters || return 1

	# Make variables
	local tokens

	# Calculate the number of characters and divide by four
	tokens=$((((characters + CHARACTERS_PER_TOKEN - 1) / CHARACTERS_PER_TOKEN) * TOKEN_ESTIMATION_CORRECTION_FACTOR))

	# Return result
	printf "%.0f" "${tokens}"

	# Return successfully
	return 0
}

# Function to calculate the approximate number of tokens
function estimate_number_of_tokens() {

	# Estimate the number of tokens
	characters_to_tokens "${#1}" || {
		echo "Error: Failed to estimate the number of tokens." >&2
		return 1
	}

	# Return successfully
	return 0
}

function count_number_of_tokens() {

  # Parse arguments
  local repo_name=$1 file_name=$2 text=$3

  # Check that inputs are valid
  local model_path
  model_path="/Users/${USER}/Library/Caches/llama.cpp/${repo_name//\//_}_${file_name}"
  check_path model_path || return 1
  check_nonempty text || return 1

  # Count the number of tokens
  tokens=$(llama-tokenize --model "${model_path}" --prompt "${text}" --show-count --log-disable || {
    echo "Error: Failed to count the number of tokens." >&2
    return 1
  })

  # Return everything after the last ": "
  echo "${tokens##*: }"

  # Return successfully
  return 0

}