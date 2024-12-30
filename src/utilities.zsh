#!/usr/bin/env zsh

########################################################################################################################
### UTILITY FUNCTIONS ##################################################################################################
########################################################################################################################

function get_epoch_in_seconds_and_decimals() {
	gdate +%s.%N
}

function get_value_from_name() {
	eval echo "\${${variable_name}}"
}

function check_online() {
	ping -c 1 google.com &>/dev/null
}

# Check if the input is empty
function check_nonempty() {

	# Parse arguments
	local variable_name=$1

	# Check if the input is empty
	if [[ -z $(get_value_from_name variable_name) ]]; then
		# In order to use funcstack without warnings from shellcheck, we need to disable SC2154
		# shellcheck disable=SC2154
		echo "Error in ${funcstack[2]}: Invalid input for ${variable_name}, expected a non-empty string." >&2
		return 1
	else
		return 0
	fi
}

# Check if the input is an integer and print an error message with the name of the variable if not
function check_integer() {

	# Parse arguments
	local variable_name=$1

	# Check that inputs are non-empty
	check_nonempty variable_name || return 1

	# Make variables
	local variable_value
	variable_value=$(get_value_from_name variable_name)

	# Check if the input is an integer
	if [[ ! "${variable_value}" =~ ^-?[0-9]+$ ]]; then
		echo "Error in ${funcstack[2]}: Invalid input ${variable_name}=\"${variable_value}\", expected an integer." >&2
		return 1
	else
		return 0
	fi
}

# Check if the input is Boolean
function check_boolean() {

	# Parse arguments
	local variable_name=$1

	# Check that inputs are non-empty
	check_nonempty variable_name || return 1

	# Make variables
	local variable_value
	variable_value=$(get_value_from_name variable_name)

	# Check if the input is Boolean
	if [[ "${variable_value}" != true && "${variable_value}" != false ]]; then
		echo "Error in ${funcstack[2]}: Invalid input ${variable_name}=\"${variable_value}\", expected a boolean." >&2
		return 1
	else
		return 0
	fi
}

# Check if the input is a float
function check_float() {

	# Parse arguments
	local variable_name=$1

	# Check that inputs are non-empty
	check_nonempty variable_name || return 1

	# Make variables
	local variable_value
	variable_value=$(get_value_from_name variable_name)

	# Check if the input is a float
	if [[ ! ${variable_value} =~ ^-?[0-9]*\.?[0-9]+$ ]]; then
		echo "Error in ${funcstack[2]}: Invalid input ${variable_name}=\"${variable_value}\", expected a float." >&2
		return 1
	else
		return 0
	fi
}

# Check if the input is a filepath
function check_path() {

	# Parse arguments
	local variable_name=$1

	# Check that inputs are non-empty
	check_nonempty variable_name || return 1

	# Make variables
	local variable_value
	variable_value=$(get_value_from_name variable_name)

	# Check if the input is a valid path
	if [[ ! -f "${variable_value}" ]]; then
		echo "Error in ${funcstack[2]}: Invalid input ${variable_name}=\"${variable_value}\", expected a valid path." >&2
		return 1
	else
		return 0
	fi
}

# Check if hte input is a url
function check_url() {

	# Parse arguments
	local variable_name=$1

	# Check that inputs are non-empty
	check_nonempty variable_name || return 1

	# Make variables
	local variable_value
	variable_value=$(get_value_from_name variable_name)

	# Check if the input is a valid URL
	if [[ ! "${variable_value}" =~ ^https?://[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}(/.*)?$ ]]; then
		echo "Error in ${funcstack[2]}: Invalid input ${variable_name}=\"${variable_value}\", expected a valid URL." >&2
		return 1
	else
		return 0
	fi
}

# Check if the input is a valid emoji
function check_emoji() {

	# Parse arguments
	local variable_name=$1

	# Check that inputs are non-empty
	check_nonempty variable_name || return 1

	# Make variables
	local variable_value
	variable_value=$(get_value_from_name variable_name)

	# Check if the input is a valid emoji
	if [[ ! "${variable_value}" =~ [😀-🙏🌀-🗿] ]]; then
		echo "Error in ${funcstack[2]}: Invalid input ${variable_name}=\"${variable_value}\", expected a valid emoji." >&2
		return 1
	else
		return 0
	fi
}

# Function to log the time taken for a process
function timestamp_log_to_stderr() {

	if [[ "${QUIET}" == false ]]; then

		# Parse arguments
		local emoji=$1
		local message=$2

		# Make sure the inputs are valid
		check_emoji emoji || return 1
		check_nonempty message || return 1

		# Print the message to stderr
		echo "[$(gdate "+%H:%M:%S.%2N")] ${emoji} ${message}" >&2
	fi

	# Return successfully
	return 0
}

# Function that checks to see if a model exists and download it if not
function check_model_status() {
	# Parse arguments
	local repo_name=$1 file_name=$2

	# Check that inputs are valid
	check_nonempty repo_name || return 1
	check_nonempty file_name || return 1

	# Check if the model exists
	local model_path="/Users/${USER}/Library/Caches/llama.cpp/${repo_name//\//_}_${file_name}"
	if [[ ! -f "${model_path}" ]]; then
		# Make sure we are online
		check_online || {
			echo "Error: You are not connected to the internet, so models cannot be downloaded." >&2
			return 1
		}

		# Print a detailed timestamp, down to the decimal seconds
		timestamp_log_to_stderr "📥" "Downloading ${repo_name}/${file_name}..." >&2
		if [[ "${VERBOSE}" == true ]]; then
			# Print message about downloading model to stderr
			if ! llama-cli --hf-repo "${repo_name}" --hf-file "${file_name}" -p "hi" -n 0; then
				echo "Error in ${funcstack[3]}: Failed to download ${repo_name}/${file_name}." >&2
				return 1
			fi
		else
			if ! llama-cli --hf-repo "${repo_name}" --hf-file "${file_name}" --no-warmup -p "hi" -n 0 2>/dev/null; then
				echo "Error in ${funcstack[3]}: Failed to download ${repo_name}/${file_name}." >&2
				return 1
			fi
		fi
	fi

	# Return successfully
	return 0
}

# Write a function to convert tokens to characters
function tokens_to_characters() {

	# Parse arguments
	local tokens=$1

	# Check that inputs are valid
	check_integer tokens || return 1

	# Make variables
	local characters

	# Calculate the number of characters and divide by four
	characters=$(((tokens * CHARACTERS_PER_TOKEN) / TOKEN_ESTIMATION_CORRECTION_FACTOR))

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