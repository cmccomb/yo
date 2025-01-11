#!/usr/bin/env sh
# shellcheck enable=all

########################################################################################################################
### TOKEN COUNTING FUNCTIONS ###########################################################################################
########################################################################################################################

# Write a function to convert tokens to characters
tokens_to_characters() {

	# Parse arguments
	tokens=$1

	# Check that inputs are valid
	check_integer tokens || return 1

	# Calculate the number of characters and divide by four
  characters=$(echo "scale=0; (${tokens} * $(read_setting general.characters_per_token)) / $(read_setting general.token_estimation_correction_factor)" | bc)

	# Return result
	printf "%.0f" "${characters}"

	# Return successfully
	return 0
}

# Write a function to convert tokens to characters
characters_to_tokens() {

	# Parse arguments
	characters=$1

	# Check that inputs are valid
	check_integer characters || return 1

	# Calculate the number of characters and divide by four
  tokens=$(echo "(((${characters} + $(read_setting general.characters_per_token) - 1) / $(read_setting general.characters_per_token)) * $(read_setting general.token_estimation_correction_factor))" | bc)

	# Return result
	printf "%.0f" "${tokens}"

	# Return successfully
	return 0
}

# Function to calculate the approximate number of tokens
estimate_number_of_tokens() {

	# Estimate the number of tokens
	characters_to_tokens "${#1}" || {
		echo "Error: Failed to estimate the number of tokens." >&2
		return 1
	}

	# Return successfully
	return 0
}

count_number_of_tokens() {

	# Parse arguments
	repo_name=$1
	file_name=$2
	text=$3

	# Check that inputs are valid
	model_is_available "${repo_name}" "${file_name}" || return 1
	check_nonempty text || return 1

	# Make variables
	model_path="/Users/${USER}/Library/Caches/llama.cpp/$(echo "${repo_name}" | sed 's/\//_/g')_${file_name}"

	# Count the number of tokens
	tokens=$(llama-tokenize --model "${model_path}" --prompt "${text}" --show-count --log-disable) || {
		echo "Error: Failed to count the number of tokens." >&2
		return 1
	}

	# Return everything after the last ": "
	echo "${tokens##*: }"

	# Return successfully
	return 0

}
