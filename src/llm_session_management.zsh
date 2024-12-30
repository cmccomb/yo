#!/usr/bin/env zsh
# Disable SC2207 because we need to split the filenames into an array and I like using tr
# shellcheck disable=SC2207

########################################################################################################################
### LLMs AND PROMPTS ###################################################################################################
########################################################################################################################

### Generate a prompt for one-off or interactive sessions ##############################################################
function generate_prompt() {

	# Parse arguments
	local mode=$1 query=$2
	local filenames=$3 search_terms=$4 website_urls=$5
	local surf_and_add_results=$6 add_usage_info=$7 add_system_info=$8 add_directory_info=$9 add_clipboard_info=${10}

	# Split filenames into an array of files
	filenames=($(echo "${filenames}" | tr '\n' ' '))
	search_terms=($(echo "${search_terms}" | tr ' ' '+' | tr '\n' ' '))
	website_urls=($(echo "${website_urls}" | tr '\n' ' '))

	# Check that inputs are valid
	check_nonempty mode || return 1
	check_boolean surf_and_add_results || return 1
	check_boolean add_usage_info || return 1
	check_boolean add_system_info || return 1
	check_boolean add_directory_info || return 1
	check_boolean add_clipboard_info || return 1

	# Make the base prompt
	local prompt
	prompt=$(generate_base_prompt)"\n\n" || {
		echo "Error: Failed to generate base prompt." >&2
		return 1
	}

	# Add system information if requested
	if [[ "${add_system_info}" == true ]]; then
		timestamp_log_to_stderr "💻" "Querying system info..." >&2
		prompt+=$(generate_system_info_context)"\n\n" || {
			echo "Error: Failed to generate system information context." >&2
			return 1
		}
	fi

	# Add directory information if requested
	if [[ "${add_directory_info}" == true ]]; then
		timestamp_log_to_stderr "📂" "Scraping the local directory..." >&2
		prompt+=$(generate_directory_info_context)"\n\n" || {
			echo "Error: Failed to generate directory information context." >&2
			return 1
		}
	fi

	# Add clipboard information if requested
	if [[ "${add_clipboard_info}" == true ]]; then
		timestamp_log_to_stderr "📋" "Checking out the clipboard..." >&2
		prompt+=$(generate_clipboard_info_context)"\n\n" || {
			echo "Error: Failed to generate clipboard information context." >&2
			return 1
		}
	fi

	# Add file file_info if available
	if [[ -n "${filenames[*]}" ]]; then
		for filename in "${filenames[@]}"; do
			timestamp_log_to_stderr "📚" "Reviewing \"${filename}\"..." >&2
			prompt+=$(generate_file_context "${filename}")"\n\n" || {
				echo "Error: Failed to generate file information context for ${filename}." >&2
				return 1
			}
		done
	fi

	# Add website information if available
	if [[ -n "${website_urls[*]}" ]]; then
		for website_url in "${website_urls[@]}"; do
			timestamp_log_to_stderr "🔗" "Reviewing \"${website_url}\"..." >&2
			prompt+=$(generate_website_context "${website_url}")"\n\n" || {
				echo "Error: Failed to generate website information context for ${website_url}." >&2
				return 1
			}
		done
	fi

	# Add search information if available
	if [[ -n "${search_terms[*]}" ]]; then
		for termset in "${search_terms[@]}"; do
			timestamp_log_to_stderr "🔎" "Searching for \"${termset//+/ }\"..." >&2
			prompt+=$(generate_search_context "${termset}")"\n\n" || {
				echo "Error: Failed to generate search information context for ${termset}." >&2
				return 1
			}
		done
	fi

	# Add search information if available
	if [[ "${surf_and_add_results}" == true ]]; then
		timestamp_log_to_stderr "🌐" "Deciding what to search for..." >&2
		local llm_generated_search_terms
		llm_generated_search_terms=$(generate_search_terms "${query}")
		timestamp_log_to_stderr "🌐" "Searching for \"${llm_generated_search_terms}\"..." >&2
		prompt+=$(generate_search_context "${llm_generated_search_terms}")"\n\n" || {
			echo "Error: Failed to generate search information context." >&2
			return 1
		}
	fi

	# Add self context if available
	if [[ "${add_usage_info}" == true ]]; then
		timestamp_log_to_stderr "📖️" "Reviewing the Yo help message..." >&2
		prompt+=$(generate_self_context)"\n\n" || {
			echo "Error: Failed to generate self information context." >&2
			return 1
		}
	fi

	# If any content was added, add an instruction about relying on the content
	if [[ 
		"${add_system_info}" == true ||
		"${add_directory_info}" == true ||
		"${add_clipboard_info}" == true ||
		-n "${filename}" ||
		-n "${website_url}" ||
		-n "${search_terms}" ||
		"${surf_and_add_results}" == true ]] \
		; then
		prompt+="Use the information above to help you answer the user's question.\n\n"
	fi

	# Add query and instructions based on interactive ####################################################################
	case ${mode} in
	interactive)
		prompt+=$(generate_interactive_instructions) || {
			echo "Error: Failed to generate interactive instructions." >&2
			return 1
		}
		;;
	one-off)
		prompt+=$(generate_oneoff_instructions "${query}") || {
			echo "Error: Failed to generate one-off instructions." >&2
			return 1
		}
		;;
	task) ;;
	*)
		echo "Error: Invalid mode: ${mode}" >&2
		return 1
		;;
	esac

	# Return prompt
	echo "${prompt}"

	# Return successfully
	return 0
}

### Start a llama-cli session ##########################################################################################
function start_llama_session() {

	# Parse arguments
	local repo_name=$1 file_name=$2 prompt=$3 mode=$4
	local number_of_tokens_to_generate=$5 context_length=$6 temp=$7

	# Check that inputs are valid
	check_nonempty repo_name || return 1
	check_nonempty file_name || return 1
	check_nonempty prompt || return 1
	check_nonempty mode || return 1
	check_integer number_of_tokens_to_generate || return 1
	check_integer context_length || return 1
	check_float temp || return 1

	# Check if the model exists and download it if not
	model_is_available "${repo_name}" "${file_name}" || {
		echo "Error: Failed to check status of ${repo_name}/${file_name}." >&2
		return 1
	}

	# If context size is -1, estimate it
	if [[ "${context_length}" == -1 ]]; then
		context_length=$(($(estimate_number_of_tokens "${prompt}") + number_of_tokens_to_generate)) || {
			echo "Error: Failed to estimate context length." >&2
			return 1
		}
	fi

	# Configure llama-cli arguments
	local args=(
		--threads "$(sysctl -n hw.logicalcpu_max || sysctl -n hw.ncpu || echo 1)"
		--hf-repo "${repo_name}"
		--hf-file "${file_name}"
		--prompt "${prompt}"
		--predict "${number_of_tokens_to_generate}"
		--temp "${temp}"
		--ctx-size "${context_length}"
		--seed 42
		--prio 3
		--mirostat 2
		--flash-attn
		--no-warmup
	)

	# Switch case statement for mode variable to take on values of "interactive" or "one-off" or "task"
	case ${mode} in
	interactive)
		timestamp_log_to_stderr "💭" "Getting ready for our conversation..." >&2
		args+=(--conversation)
		;;
	one-off)
		timestamp_log_to_stderr "💭" "Thinking about the question..." >&2
		args+=(--reverse-prompt "${YO}")
		;;
	task)
		args+=(--repeat-penalty 3)
		;;
	*)
		echo "Error: Invalid mode: ${mode}" >&2
		return 1
		;;
	esac

	# Display prompt
	if [[ "${VERBOSE:-"false"}" == true && "${mode}" != "task" ]]; then
		args+=(--verbose-prompt)
	else
		args+=(--no-display-prompt)
	fi

	# Start session
	if [[ "${VERBOSE}" == true ]]; then
		if ! llama-cli "${args[@]}"; then
			echo "Error: llama-cli command failed while attempting to call ${repo_name}/${file_name}." >&2
			return 1
		fi
	else
		if ! llama-cli "${args[@]}" 2>/dev/null; then
			echo "Error: llama-cli command failed while attempting to call ${repo_name}/${file_name}." >&2
			return 1
		fi
	fi

	# Return successfully
	return 0
}
