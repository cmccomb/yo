#!/usr/bin/env zsh
# shellcheck enable=all

########################################################################################################################
### LOGS ###############################################################################################################
########################################################################################################################

# Function to get the current epoch time in seconds and decimals
function get_epoch_in_seconds_and_decimals() {
	gdate +%s.%N
}

# Function to log the time taken for a process
function timestamp_log_to_stderr() {

	if [[ "${QUIET:-"false"}" == false ]]; then

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

# Function to log the time taken for a process
function start_log() {
	# Print a detailed timestamp
	timestamp_log_to_stderr "⏳" "Starting..." >&2

	# Save starting time to calculate elapsed time later one
	start_time=$(get_epoch_in_seconds_and_decimals) || {
		echo "Error: Failed to get the start time." >&2
		return 1
	}

	# Return start time
	echo "${start_time}"

	# Return successfully
	return 0

}

# Function to log the time taken for a process
function end_log() {
	# Parse arguments
	local start_time=$1

	# Make sure the inputs are valid
	check_float start_time || return 1

	# Remove a line if the terminal is set
	[[ -n "${TERM}" ]] && tput cuu1 && tput el

	# Print a detailed timestamp
	end_time=$(get_epoch_in_seconds_and_decimals) || {
		echo "Error: Failed to get the end time." >&2
		return 1
	}
	timestamp_log_to_stderr "⌛️" "Elapsed time: $(printf "%.2f" $((end_time - start_time))) seconds." >&2
}
