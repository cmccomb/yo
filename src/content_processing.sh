#!/usr/bin/env sh
# shellcheck enable=all

# Extract file_info from a file or URL (supports text and PDF files)
extract_file_info() {

	# Parse arguments
	source=$1
	max_length=$2

	# Check that inputs are valid
	check_path source || return 1
	check_integer max_length || return 1

	# Make variables
	file_info=""

	case ${source} in
	*.pdf)
		file_info=$(pdftotext "${source}" - 2>/dev/null) || {
			echo "Error: Failed to extract text from PDF file ${source}." >&2
			return 1
		}
		;;
	*.png | *.jpg | *.jpeg | *.tiff | .tif | *.bmp | *.gif | *.webp)
		file_info=$(tesseract "${source}" - 2>/dev/null) || {
			echo "Error: Failed to extract text from image ${source}." >&2
			return 1
		}
		;;
	*)
		# Try to extract file info using pandoc
		if ! file_info=$(pandoc -t markdown "${source}" --quiet 2>/dev/null); then
			# If pandoc fails, try to use cat
			if ! file_info=$(cat "${source}" 2>/dev/null); then
				# If cat fails, return an error
				echo "Error: Failed to extract text from file ${source}." >&2
				return 1
			fi
		fi
		;;
	esac

	# Trim to max length if neeeded
	if [ "${#file_info}" -gt "${max_length}" ]; then
		file_info=$(echo "${file_info}" | cut -c1-"${max_length}")
	fi

	# Return file_info
	echo "${file_info}"

	# Return successfully
	return 0
}

### Extract file_info from a file or URL (supports text and PDF files)
extract_url_info() {

	# Parse arguments
	source=$1
	max_length=$2

	# Check that inputs are valid
	check_url source || return 1
	check_integer max_length || return 1

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
	if [ "${#file_info}" -gt "${max_length}" ]; then
		file_info=$(echo "${file_info}" | cut -c1-"${max_length}")
	fi

	# Return file_info
	echo "${file_info}"

	# Return successfully
	return 0
}

extract_facts() {

	# Parse arguments
	chunk=$1
	query=$2

	# Check that inputs are valid
	check_nonempty chunk || return 1

	# Create prompt
	prompt=$(
		cat <<-EOF
			=============== START OF TEXT===============
			${chunk}
			=============== END OF TEXT===============

			Based on the unstructured text given above, provide a concise list of facts and information that are useful for answering this user query:
			${query}

			Begin every fact on a new line and end with a period.
			Do not provide any additional markup or information.
		EOF
	)

	start_llama_session \
		"$(read_setting model.task.repository)" \
		"$(read_setting model.task.filename)" \
		"${prompt}" \
		"task" \
		"$(read_setting mode.compression.generation_length)" \
		-1 \
		"$(read_setting model.task.temperature)" ||
		{
			echo "Error: Failed to extract facts." >&2
			return 1
		}

	return 0
}

# Compress text
compress_text() {

	# Parse arguments
	text=$1
	remove_spaces=$2
	remove_punctuation=$3
	summarize=$4
	query=$5

	# Check that inputs are valid
	check_nonempty text || return 1
	check_boolean remove_spaces || return 1
	check_boolean remove_punctuation || return 1
	check_boolean summarize || return 1

	# Tokenize text
	approximate_length=$(estimate_number_of_tokens "${text}")

	# If verbatim, set compression trigger length to a huge number
	if [ "${VERBATIM:-"false"}" = true ]; then
    compression_trigger_length=1000000000
  else
		compression_trigger_length=$(read_setting mode.compression.trigger_length)
  fi


	# If length of tokenized text is greater than cutoff, do something
	if [ "${approximate_length}" -gt "${compression_trigger_length}" ] && [ "${summarize}" = true ]; then

		# Remove spaces if flag is set
		if [ "${remove_spaces}" = true ]; then
			text=$(echo "${text}" | tr -s "[:space:]")
		fi

		# Remove punctuation if flag is set
		if [ "${remove_punctuation}" = true ]; then
			text=$(echo "${text}" | tr -d "[:punct:]")
		fi

		# Make variables
		compressed=""
		counter=0

		# Compress text
		chunk_length_in_chars=$(tokens_to_characters "$(read_setting mode.compression.chunk_length)")

		# Estimate how the length of text divided by chunk_length_in_chars
		number_of_chunks=$(printf "%.0f" $(((${#text} / chunk_length_in_chars) + 1)))

		# While text isn't empty, peel off chunk_length_in_chars characters and process those. Then remove them from text.
		while [ -n "${text}" ]; do

			# Increment counter
			counter=$((counter + 1))

			# Update the user on what's happening
			timestamp_log_to_stderr "📦" "Reading chunk ${counter} of ${number_of_chunks}..." >&2
			chunk=$(printf "%s" "${text}" | head -c "${chunk_length_in_chars}")
      text=$(printf "%s" "${text}" | tail -c +$((chunk_length_in_chars + 1)))
			compressed="${compressed}$(extract_facts "${chunk}" "${query}" )" || {
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