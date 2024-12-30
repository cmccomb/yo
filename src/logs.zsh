#!/usr/bin/env zsh

########################################################################################################################
### LOGS ###############################################################################################################
########################################################################################################################

# Function to get the current epoch time in seconds and decimals
function get_epoch_in_seconds_and_decimals() {
	gdate +%s.%N
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
