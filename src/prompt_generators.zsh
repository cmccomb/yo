#!/usr/bin/env zsh

########################################################################################################################
### SYSTEM PROMPT GENERATORS ############################################################################################
########################################################################################################################

# Generate base prompt
function generate_base_prompt() {
	cat <<-EOF
		You are playing the role of Yo, a highly-capable AI assistant living in the MacOS terminal. It is currently $(date).
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

########################################################################################################################
### STATIC PROMPT GENERATORS ###########################################################################################
########################################################################################################################

# Generate self context using help
function generate_self_context() {
	cat <<-EOF
		A help message explaining how to use your command line interface
		================= BEGINNING OF HELP MESSAGE =================
		$(show_help)
		===================== END OF HELP MESSAGE ====================
	EOF
}

########################################################################################################################
### OFFLINE PROMPT GENERATORS ##########################################################################################
########################################################################################################################

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

########################################################################################################################
### ONLINE PROMPT GENERATORS ###########################################################################################
########################################################################################################################

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
