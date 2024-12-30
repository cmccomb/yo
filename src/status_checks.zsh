#!/usr/bin/env zsh
# shellcheck enable=all

########################################################################################################################
### CHECK STATUS #######################################################################################################
########################################################################################################################

# Function that checks to see if the system is online
function system_is_online() {
	ping -c 1 google.com &>/dev/null
}

# Function that checks to see if a model exists and download it if not
function model_is_available() {
	# Parse arguments
	local repo_name=$1 file_name=$2

	# Check that inputs are valid
	check_nonempty repo_name || return 1
	check_nonempty file_name || return 1

	# Check if the model exists
	if [[ ! -f "/Users/${USER}/Library/Caches/llama.cpp/${repo_name//\//_}_${file_name}" ]]; then
		# Make sure we are online
		system_is_online || {
			echo "Error: You are not connected to the internet, so models cannot be downloaded." >&2
			return 1
		}

		# Print a detailed timestamp, down to the decimal seconds
		timestamp_log_to_stderr "📥" "Downloading ${repo_name}/${file_name}..." >&2
		if [[ "${VERBOSE:-"false"}" == true ]]; then
			# Print message about downloading model to stderr
			if ! llama-cli --hf-repo "${repo_name}" --hf-file "${file_name}" -p "hi" -n 0; then
				echo "Error in ${funcstack[3]:-"Yo"}: Failed to download ${repo_name}/${file_name}." >&2
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
