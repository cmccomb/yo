#!/usr/bin/env zsh
# shellcheck enable=all

########################################################################################################################
### SEARCH #############################################################################################################
########################################################################################################################

### Perform a web search with user-provided terms ######################################################################
function perform_search() {

	# Parse arguments
	local terms=$1

	# Check that inputs are valid
	check_nonempty terms || return 1

	# Make variables
	local url response

	# Example API call
	url="${GOOGLE_CSE_BASE_URL:-""}?key=${GOOGLE_CSE_API_KEY:-""}&cx=${GOOGLE_CSE_ID:-""}&q=${terms// /+}"

	# Perform search and extract relevant information
	if ! response=$(curl -s "${url}" | grep -E "^\s*\"title\"|^\s*\"snippet\""); then
		echo "Error: Failed to perform web search." >&2
		return 1
	else
		# Return response
		echo "${response}"
		return 0
	fi
}

### Extract optimized search terms using a small model #################################################################
function generate_search_terms() {

	# Parse arguments
	local query=$1

	# Check that inputs are valid
	check_nonempty query || return 1

	# Make variables
	local prompt terms

	# Generate prompt
	prompt=$(
		cat <<-EOF
			Your task is to create an appropriate web search query for a given user query.
			Draw search terms directly from the query itself whenever possible. Do not infer additional information.

			Here is an example:
			User Query: how large is the capital of france ${YO:-"✌️"}
			Search Terms: french capital size population area

			Here is another example:
			User Query: what is the furthest planet from the sun ${YO}
			Search Terms: solar system furthest planet distance

			Here is the real user query.
			User Query: ${query}
			Search Terms:
		EOF
	)

	# Generate response
	terms=$(
		start_llama_session \
			"${TASK_MODEL_REPO_NAME:-"bartowski/Llama-3.2-1B-Instruct-GGUF"}" \
			"${TASK_MODEL_FILE_NAME:-"Llama-3.2-1B-Instruct-Q4_K_M.gguf"}" \
			"${prompt}" \
			"task" \
			"${SEARCH_TERM_GENERATION_LENGTH:-"8"}" \
			"${SEARCH_TERM_CONTEXT_LENGTH:-"-1"}" \
			"${TASK_MODEL_TEMP:-"0.2"}"
	) || {
		echo "Error: Failed to extract search terms." >&2
		return 1
	}

	# Only take the first line
	terms=$(echo "${terms}" | head -n 1)

	# Remove [end of text] marker if needed
	terms="${terms//\[end of text\]/}"

	# Return results
	echo "${terms## }"

	# Return successfully
	return 0
}
