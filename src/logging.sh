#!/usr/bin/env sh
# shellcheck enable=all

# Function to get the current epoch time in seconds and decimals
get_epoch_time_in_seconds() {
	perl -MTime::HiRes=time -e 'printf "%.9f\n", time'
}

# Function to get the current epoch time in seconds and decimals
get_formatted_time() {
	perl \
		-MTime::HiRes=time \
		-e 'use POSIX strftime; printf "%s.%02d\n", strftime("%H:%M:%S", localtime), (time-int(time))*100'
}

# Function to log the time taken for a process
timestamp_log_to_stderr() {

	if [ "${QUIET:-"false"}" = false ]; then

		# Parse arguments
		emoji=$1
		message=$2

		# Make sure the inputs are valid
		check_nonempty emoji || return 1
		check_nonempty message || return 1

		# Get the current time
		time=$(get_formatted_time) || {
			echo "Error: Failed to get the current time." >&2
			return 1
		}

		# Print the message to stderr
		echo "[${time}] ${emoji} ${message}" >&2
	fi

	# Return successfully
	return 0
}

# Function to log the time taken for a process
start_log() {
	# Print a detailed timestamp
	timestamp_log_to_stderr "⏳" "Starting..." >&2

	# Save starting time to calculate elapsed time later one
	start_time=$(get_epoch_time_in_seconds) || {
		echo "Error: Failed to get the start time." >&2
		return 1
	}

	# Return start time
	echo "${start_time}"

	# Return successfully
	return 0

}

# Function to log the time taken for a process
end_log() {
	# Parse arguments
	start_time=$1

	# Make sure the inputs are valid
	check_float start_time || return 1

	# Remove a line if the terminal is set
	[ -n "${TERM}" ] && tput cuu1 && tput el

	# Print a detailed timestamp
	end_time=$(get_epoch_time_in_seconds) || {
		echo "Error: Failed to get the end time." >&2
		return 1
	}
	elapsed_time=$(echo "${end_time} - ${start_time}" | bc)
	timestamp_log_to_stderr "⌛️" "Elapsed time: $(printf "%.2f" "${elapsed_time}") seconds." >&2
}
