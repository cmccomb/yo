#!/usr/bin/env zsh
# shellcheck enable=all

########################################################################################################################
### CONTENT EXTRACTION #################################################################################################
########################################################################################################################

### Extract file_info from a file or URL (supports text and PDF files) #################################################
function extract_file_info() {

	# Parse arguments
	local source=$1 max_length=$2

	# Check that inputs are valid
	check_path source || return 1
	check_integer max_length || return 1

	# Make variables
	local file_info=""

	case ${source} in
	*.pdf)
		command -v pdftotext >/dev/null 2>&1 || {
			echo "Error: pdftotext not installed. Install it using your package manager (e.g., brew install poppler)." >&2
			return 1
		}
		file_info=$(pdftotext "${source}" - 2>/dev/null) || {
			echo "Error: Failed to extract text from PDF file ${source}." >&2
			return 1
		}
		;;
	*.txt | *)
		file_info=$(cat "${source}") || {
			echo "Error: Failed to extract text from file ${source}." >&2
			return 1
		}
		;;
	esac

	# Trim to max length if needed
	[[ -n "${max_length}" && "${max_length}" -gt 0 ]] && file_info=${file_info:0:${max_length}}

	# Return file_info
	echo "${file_info}"

	# Return successfully
	return 0
}

### Extract file_info from a file or URL (supports text and PDF files) #################################################
function extract_url_info() {

	# Parse arguments
	local source=$1 max_length=$2

	# Check that inputs are valid
	check_url source || return 1
	check_integer max_length || return 1

	# Make variables
	local file_info response

	# Fetch file_info from URL
	if ! response=$(curl -s "${source}"); then
		echo "Error: Failed to fetch information from ${source}." >&2
		return 1
	fi

	# Convert HTML to plain text
	if ! file_info=$(echo "${response}" | pandoc -f html -t plain --quiet); then
		echo "Error: Failed to convert HTML to plain text from ${source}." >&2
		return 1
	fi

	# Trim to max length if needed
	if [[ -n "${max_length}" && "${max_length}" -gt 0 ]]; then
		file_info=${file_info:0:${max_length}}
	fi

	# Return file_info
	echo "${file_info}"

	# Return successfully
	return 0
}

function extract_facts() {

	# Parse arguments
	local chunk=$1

	# Check that inputs are valid
	check_nonempty chunk || return 1

	# Create prompt
	local prompt
	prompt=$(
		cat <<-EOF
			=============== START OF TEXT===============
			${chunk}
			=============== END OF TEXT===============

			Based on the unstructured text given above, provide a concise list of facts and information.
			Begin every fact on a new line and end with a period.
			Do not provide any additional markup or information
		EOF
	)

	start_llama_session \
		"${TASK_MODEL_REPO_NAME:-"bartowski/Llama-3.2-1B-Instruct-GGUF"}" \
		"${TASK_MODEL_FILE_NAME:-"Llama-3.2-1B-Instruct-Q4_K_M.gguf"}" \
		"${prompt}" \
		"task" \
		"${COMPRESSION_GENERATION_LENGTH:-"128"}" \
		-1 \
		0.2 || {
		echo "Error: Failed to extract facts." >&2
		return 1
	}

	return 0
}

### Start by establishing some prompt generators #######################################################################

# Compress text
function compress_text() {

	# Parse arguments
	local text=$1
	local remove_spaces=$2
	local remove_punctuation=$3
	local summarize=$4

	# Check that inputs are valid
	check_nonempty text || return 1
	check_boolean remove_spaces || return 1
	check_boolean remove_punctuation || return 1
	check_boolean summarize || return 1

	# Remove spaces if flag is set
	if [[ "${remove_spaces}" == true ]]; then
		text=$(echo "${text}" | tr -s "[:space:]")
	fi

	# Remove punctuation if flag is set
	if [[ "${remove_punctuation}" == true ]]; then
		text=$(echo "${text}" | tr -d "[:punct:]")
	fi

	# Tokenize text
	local approximate_length
	approximate_length=$(estimate_number_of_tokens "${text}")

	# If length of tokenized text is greater than cutoff, do something
	if [[ "${approximate_length}" -gt "${COMPRESSION_TRIGGER_LENGTH:-"1024"}" && "${summarize}" == true ]]; then

		# Make variables
		local compressed="" chunk_length_in_chars number_of_chunks counter=0

		# Compress text
		chunk_length_in_chars=$(tokens_to_characters "${COMPRESSION_CHUNK_LENGTH:-"4096"}")

		# Estimate how the length of text divided by chunk_length_in_chars
		number_of_chunks=$(printf "%.0f" $(((${#text} / chunk_length_in_chars) + 1)))

		# While text isn't empty, peel off chunk_length_in_chars characters and process those. Then remove them from text.
		while [[ -n "${text}" ]]; do

			# Increment counter
			((counter += 1))

			# Update the user on what's happening
			timestamp_log_to_stderr "📦" "Reading chunk ${counter} of ${number_of_chunks}..." >&2

			chunk="${text:0:${chunk_length_in_chars}}"
			text="${text:${chunk_length_in_chars}}"
			compressed+=$(extract_facts "${chunk}") || {
				echo "Error: Failed to compress text." >&2
				return 1
			}
		done

		# Echo number of tokens
		echo "${compressed}"
	else
		echo "${text}"
	fi

}
