#!/usr/bin/env zsh

########################################################################################################################
### LLMs AND PROMPTS ###################################################################################################
########################################################################################################################

# Generate base prompt
function generate_base_prompt() {
	cat <<-EOF
		    You are playing the role of Yo, a highly-capable AI assistant living in the MacOS terminal. It is currently $(date).
	EOF
}

# Generate system information
function generate_system_info_context() {

	# Make variables
	local model cores ram free_storage

	# Get system information
	model=$(system_profiler SPHardwareDataType | grep "Model Name" | awk -F": " '{print $2}') || {
		echo "Error: Failed to get computer model information." >&2
		return 1
	}
	cores=$(sysctl -n hw.ncpu) || {
		echo "Error: Failed to get number of cores." >&2
		return 1
	}
	ram=$(sysctl -n hw.memsize | awk '{x=$1/1024/1024/1024; print x}') || {
		echo "Error: Failed to get RAM size." >&2
		return 1
	}
	free_storage=$(df -h / | tail -1 | awk '{split($4, a, "G"); print a[1]}') || {
		echo "Error: Failed to get free storage." >&2
		return 1
	}

	# Return system information
	cat <<-EOF
		    ===================== BEGINNING OF SYSTEM INFORMATION =====================
		    You are on a ${model} with ${cores} cores, ${ram}GB RAM, and ${free_storage}GB free disk space.
		    ======================== END OF  SYSTEM INFORMATION =======================
	EOF
}

# Generate directory information
function generate_directory_info_context() {

	# Make variables
	local file_list file_previews

	# Generate file list and previews
	file_list=$(ls -lahpSR | head -n 50)
	file_previews=$(
		find . -maxdepth 1 -type f -exec file --mime {} + |
			grep 'text/' |
			cut -d: -f1 |
			xargs du -h |
			sort -rh |
			head -n 5 |
			awk '{print $2}' |
			xargs -I {} sh -c 'echo "\n\nFile: {}"; echo ---\\n$(head -n 10 "{}")\\n---'
	)

	cat <<-EOF
		    ================= BEGINNING OF CURRENT DIRECTORY CONTENTS =================
		    You were invoked from the $(pwd) directory.

		    Here are the contents (truncated at 50, sorted by file size):
		    ${file_list}

		    Here is a preview of the contents of the largest readable files:
		    ${file_previews}
		    ==================== END OF CURRENT DIRECTORY CONTENTS ====================
	EOF

}

# Generate clipboard information
function generate_clipboard_info_context() {

	# Make variables
	local clipboard_info
	clipboard_info=$(pbpaste) || {
		echo "Error: Failed to get clipboard information." >&2
		return 1
	}

	# Compress if needed
	clipboard_info=$(compress_text "${clipboard_info}" true true true) || {
		echo "Error: Failed to compress clipboard information." >&2
		return 1
	}

	cat <<-EOF
		    Here are the contents from the clipboard:
		    ================= BEGINNING OF CURRENT CLIPBOARD CONTENTS =================
		    ${clipboard_info}
		    ==================== END OF CURRENT CLIPBOARD CONTENTS ====================
	EOF
}

# Generate file contents context
function generate_file_context() {

	# Parse arguments
	local filename=$1

	# Check that inputs are valid
	check_path filename || return 1

	# Make variables
	local file_info=""

	# Check that inputs are valid
	file_info=$(extract_file_info "${filename}" "${MAX_FILE_CONTENT_LENGTH}") || {
		echo "Error: Failed to extract information from file ${filename}." >&2
		return 1
	}

	# Compress if needed
	file_info=$(compress_text "${file_info}" true true true) ||
		{
			echo "Error: Failed to compress file information." >&2
			return 1
		}

	# Return file information
	cat <<-EOF
		    Relevant information from ${filename}:
		    ================= BEGINNING OF FILE CONTENTS =================
		    ${file_info}
		    ===================== END OF FILE CONTENTS ===================
	EOF
}

# Generate website contents
function generate_website_context() {

	# Parse arguments
	local url=$1

	# Check that inputs are valid
	check_url url || return 1

	# Make variables
	website_info=""

	# Check that inputs are valid
	website_info=$(extract_url_info "${url}" "${MAX_FILE_CONTENT_LENGTH}") || {
		echo "Error: Failed to extract information from URL ${url}." >&2
		return 1
	}

	# Compress the info
	website_info=$(compress_text "${website_info}" true true true) || {
		echo "Error: Failed to compress website information." >&2
		return 1
	}

	# Return file information
	cat <<-EOF
		    Relevant information from ${url}:
		    ================= BEGINNING OF WEBSITE CONTENTS =================
		    ${website_info}
		    ===================== END OF WEBSITE CONTENTS ===================
	EOF
}

# Generate search context
function generate_search_context() {

	# Parse arguments
	local search_terms=$1

	# Check that inputs are valid
	check_nonempty search_terms || return 1

	# Perform the search
	search_info=$(perform_search "${search_terms}") || {
		echo "Error: Failed to perform search for ${search_terms}." >&2
		return 1
	}

	search_info=$(compress_text "${search_info}" true true true) || {
		echo "Error: Failed to compress search information." >&2
		return 1
	}

	# Return search information
	cat <<-EOF
		    Relevant information from web search using ${search_terms}:
		    ================= BEGINNING OF SEARCH RESULTS =================
		    ${search_info}
		    ===================== END OF SEARCH RESULTS ====================
	EOF
}

# Generate self context using help
function generate_self_context() {
	cat <<-EOF
		        A help message explaining how to use your command line interface
		        ================= BEGINNING OF HELP MESSAGE =================
		        $(show_help)
		        ===================== END OF HELP MESSAGE ====================
	EOF
}

# Generate prompt for one-off sessions
function generate_oneoff_instructions() {

	# Parse arguments
	local query=$1

	# Check that inputs are valid
	check_nonempty query || return 1

	cat <<-EOF
		    Your task is to directly answer the user's question. Your answer will be concise, helpful, and immediately usable. End your answer with the symbol ${YO}.

		    Here is an example:
		    User Query:how large is the capital of france ${YO}
		    Your Super-Short Answer:41 square miles (105 square km) ${YO}

		    Here is another example:
		    User Query:what is the furthest planet from the sun ${YO}
		    Search Terms:Neptune is the furthest planet from the Sun. ${YO}

		    Here is the real user query.
		    User Query:${query} ${YO}
		    Your Super-Short Answer:
	EOF
}

# Generate interactive instructions
function generate_interactive_instructions() {
	cat <<-EOF
		    Your task is to assist the user in an interactive session, responding concisely and accurately.
	EOF
}

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
		llm_generated_search_terms=$(extract_search_terms "${query}")
		timestamp_log_to_stderr "🌐" "Searching for \"${llm_generated_search_terms}\"..." >&2
		prompt+=$(generate_search_context "${llm_generated_search_terms}" "${search_info}")"\n\n" || {
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
	check_model_status "${repo_name}" "${file_name}" || {
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
	task) ;;
	*)
		echo "Error: Invalid mode: ${mode}" >&2
		return 1
		;;
	esac

	# Display prompt
	if [[ "${VERBOSE}" == true && "${mode}" != "task" ]]; then
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
