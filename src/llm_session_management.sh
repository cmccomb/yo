#!/usr/bin/env sh
# shellcheck enable=all

# Generate a prompt for one-off or interactive sessions
# Parameters:
#   $1: The mode (interactive, one-off, or task)
#   $2: The query
#   $3: The filenames to include in the context
#   $4: The search terms to include in the context
#   $5: The website URLs to include in the context
#   $6: Whether to surf and add results (true/false)
#   $7: Whether to add usage information (true/false)
#   $8: Whether to add system information (true/false)
#   $9: Whether to add directory information (true/false)
#   $10: Whether to add clipboard information (true/false)
#   $11: Whether to add screenshot information (true/false)
#   $12: The text input list to include in the context
# Returns:
#   The generated prompt
generate_prompt() {

	# Parse arguments
	mode=$1
	query=$2
	filenames=$3
	search_terms=$4
	website_urls=$5
	surf_and_add_results=$6
	add_usage_info=$7
	add_system_info=$8
	add_directory_info=$9
	add_clipboard_info=${10}
	add_screenshot_info=${11}
	text_input_list=${12}

	# Check that inputs are valid
	check_mode mode || return 1
	check_boolean surf_and_add_results || return 1
	check_boolean add_usage_info || return 1
	check_boolean add_system_info || return 1
	check_boolean add_directory_info || return 1
	check_boolean add_clipboard_info || return 1

	# Make the base prompt
	prompt=$(generate_base_prompt)"\n\n" || {
		echo "Error: Failed to generate base prompt." >&2
		return 1
	}
	base_prompt_length="${#prompt}"

	# Add system information if requested
	if [ "${add_system_info}" = true ]; then
		timestamp_log_to_stderr "💻" "Querying system info..." >&2
		prompt="${prompt} $(generate_system_info_context)\n\n" || {
			echo "Error: Failed to generate system information context." >&2
			return 1
		}
	fi

	# Add directory information if requested
	if [ "${add_directory_info}" = true ]; then
		timestamp_log_to_stderr "📂" "Scraping the directory..." >&2
		prompt="${prompt} $(generate_directory_info_context)\n\n" || {
			echo "Error: Failed to generate directory information context." >&2
			return 1
		}
	fi

	# Add clipboard information if requested
	if [ "${add_clipboard_info}" = true ]; then
		timestamp_log_to_stderr "📋" "Checking out the clipboard..." >&2
		prompt="${prompt} $(generate_clipboard_info_context "${query}")\n\n" || {
			echo "Error: Failed to generate clipboard information context." >&2
			return 1
		}
	fi

	# Add screenshot information if requested
	if [ "${add_screenshot_info}" = true ]; then
		timestamp_log_to_stderr "📸" "Taking a screenshot..." >&2
		echo "Error: Failed to take a screenshot." >&2
		prompt="${prompt}$(generate_screenshot_context)\n\n" || {
			echo "Error: Failed to generate screenshot information context." >&2
			return 1
		}
	fi

	# Add file file_info if available
	if [ -n "${filenames}" ]; then
		while [ -n "${filenames}" ]; do
			filename=$(echo "${filenames}" | head -n 1)
			filenames=$(echo "${filenames}" | tail -n +2)
			timestamp_log_to_stderr "📚" "Reviewing \"${filename}\"..." >&2
			prompt="${prompt}$(generate_file_context "${filename}" "${query}")\n\n" || {
				echo "Error: Failed to generate context from ${filename}." >&2
				return 1
			}
		done
	fi

	# Add website information if available
	if [ -n "${text_input_list}" ]; then
		while [ -n "${text_input_list}" ]; do
			text_input=$(echo "${text_input_list}" | head -n 1)
			text_input_list=$(echo "${text_input_list}" | tail -n +2)
			timestamp_log_to_stderr "🔗" "Reviewing \"$(echo "${text_input}" | cut -c1-30)\"..." >&2
			prompt="${prompt} $(generate_text_context "${text_input}" "${query}")\n\n" || {
				echo "Error: Failed to generate website information context for ${text_input}." >&2
				return 1
			}
		done
	fi

	# Add website information if available
	if [ -n "${website_urls}" ]; then
		while [ -n "${website_urls}" ]; do
			website_url=$(echo "${website_urls}" | head -n 1)
			website_urls=$(echo "${website_urls}" | tail -n +2)
			timestamp_log_to_stderr "🔗" "Reviewing \"${website_url}\"..." >&2
			prompt="${prompt} $(generate_website_context "${website_url}" "${query}")\n\n" || {
				echo "Error: Failed to generate website information context for ${website_url}." >&2
				return 1
			}
		done
	fi

	# Add search information if available
	if [ -n "${search_terms}" ]; then
		while [ -n "${search_terms}" ]; do
			termset=$(echo "${search_terms}" | head -n 1)
			search_terms=$(echo "${search_terms}" | tail -n +2)
			timestamp_log_to_stderr "🔎" "Searching for \"${termlist}\"..." >&2
			prompt="${prompt} $(generate_search_context "${termset}" "${query}")\n\n" || {
				echo "Error: Failed to generate search information context for ${termset}." >&2
				return 1
			}
		done
	fi

	# Add search information if available
	if [ "${surf_and_add_results}" = true ]; then
		timestamp_log_to_stderr "🌐" "Deciding what to search for..." >&2
		llm_generated_search_terms=$(generate_search_terms "${query}")
		timestamp_log_to_stderr "🌐" "Searching for \"${llm_generated_search_terms}\"..." >&2
		prompt="${prompt} $(generate_search_context "${llm_generated_search_terms}" "${query}")\n\n" || {
			echo "Error: Failed to generate search information context." >&2
			return 1
		}
	fi

	# Add self context if available
	if [ "${add_usage_info}" = true ]; then
		timestamp_log_to_stderr "📖️" "Reviewing the Yo help message..." >&2
		prompt="${prompt} $(generate_self_context)\n\n" || {
			echo "Error: Failed to generate self information context." >&2
			return 1
		}
	fi

	# If prompt is longer than base prompt, add an instruction about relying on the content
	if [ "${#prompt}" -gt "${base_prompt_length}" ]; then
		prompt="${prompt} Use the information above to help you answer the user's question.\n\n"
	fi

	# Add query and instructions based on interactive ####################################################################
	case ${mode} in
	interactive)
		prompt="${prompt} $(generate_interactive_instructions)\n\n" || {
			echo "Error: Failed to generate interactive instructions." >&2
			return 1
		}
		;;
	one-off)
		prompt="${prompt} $(generate_oneoff_instructions "${query}")\n\n" || {
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

	# Escape double quotes, single quotes, newlines, and backticks
	prompt=$(echo "${prompt}" | sed -e 's/"/\\"/g' -e "s/'/\\'/g" -e 's/$/\\n/g' -e 's/`/\\`/g')

	# Return successfully
	echo "${prompt}"

	# Return successfully
	return 0
}

# Start a llama-cli session
# Parameters:
#   $1: The repository name
#   $2: The file name
#   $3: The prompt
#   $4: The mode (interactive, one-off, or task)
#   $5: The number of tokens to generate
#   $6: The context length
#   $7: The temperature
start_llama_session() {

	# Parse arguments
	repo_name=$1
	file_name=$2
	prompt=$3
	mode=$4
	number_of_tokens_to_generate=$5
	context_length=$6
	temp=$7

	# Check that inputs are valid
	check_nonempty repo_name || return 1
	check_nonempty file_name || return 1
	check_nonempty prompt || return 1
	check_mode mode || return 1
	check_integer number_of_tokens_to_generate || return 1
	check_integer context_length || return 1
	check_float temp || return 1

	# Check if the model exists and download it if not
	model_is_available "${repo_name}" "${file_name}" || return 1

	# If VERBATIM is true, set context length to -1
	if [ "${VERBATIM:-"false"}" = true ]; then
		context_length=-1
	fi

	# If context size is -1, count token length
	if [ "${context_length}" = -1 ]; then
		context_length=$(($(count_number_of_tokens "${repo_name}" "${file_name}" "${prompt}") + number_of_tokens_to_generate)) || {
			echo "Error: Failed to estimate context length." >&2
			return 1
		}
	fi

	# Configure llama-cli arguments
	args="--threads $(sysctl -n hw.logicalcpu_max || sysctl -n hw.ncpu || echo 1)"
	args="${args} --hf-repo ${repo_name}"
	args="${args} --hf-file ${file_name}"
	args="${args} --predict ${number_of_tokens_to_generate}"
	args="${args} --temp ${temp}"
	args="${args} --ctx-size ${context_length}"
	args="${args} --seed 42"
	args="${args} --prio 3"
	args="${args} --mirostat 2"
	args="${args} --flash-attn"
	args="${args} --no-warmup"

	# Switch case statement for mode variable to take on values of "interactive" or "one-off" or "task"
	case ${mode} in
	interactive)
		timestamp_log_to_stderr "💭" "Getting ready for our conversation..." >&2
		args="${args} --conversation"
		;;
	one-off)
		timestamp_log_to_stderr "💭" "Thinking about the question..." >&2
		args="${args} --reverse-prompt ${YO:-"✌️"}"
		args="${args} --no-conversation"
		;;
	task)
		args="${args} --no-conversation"
		;;
	*)
		echo "Error: Invalid mode: ${mode}" >&2
		return 1
		;;
	esac

	# Display prompt
	if [ "${VERBOSE:-"false"}" = true ] && [ "${mode}" != "task" ]; then
		args="${args} --verbose-prompt"
	else
		args="${args} --no-display-prompt"
	fi

	if [ "${VERBOSE}" = true ]; then
		echo "LLAMA CLI ARGS: llama-cli ${args}" >&2
	fi

	args="${args} --prompt \"${prompt}\""

	# Start session
	if [ "${VERBOSE}" = true ]; then
		if ! eval "llama-cli ${args}"; then
			echo "Error: llama-cli command failed while attempting to call ${repo_name}/${file_name}." >&2
			return 1
		fi
	else
		if ! eval "llama-cli ${args} 2>/dev/null"; then
			echo "Error: llama-cli command failed while attempting to call ${repo_name}/${file_name}." >&2
			return 1
		fi
	fi

	# Return successfully
	return 0
}
