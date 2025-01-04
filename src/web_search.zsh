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
	url="$(read_setting search.google_cse.base_url)?key=$(read_setting search.google_cse.api_key)&cx=$$(read_setting search.google_cse.id)&q=${terms// /+}"

	# Perform search and extract relevant information
	response=$(curl -s "${url}") || {
		echo "Error: Failed to perform web search." >&2
		return 1
	}

	#  Clean response using grep
	response=$(echo "${response}" | grep -E "^\s*\"title\"|^\s*\"snippet\"") || {
		echo "Error: Failed to extract relevant information from search results." >&2
		return 1
	}

	# Return response
	echo "${response}"
	return 0
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
			"$(read_setting model.task.repository)" \
			"$(read_setting model.task.filename)" \
			"${prompt}" \
			"task" \
			"$(read_setting mode.search_term_generation.generation_length)" \
			"$(read_setting mode.search_term_generation.context_length)" \
			"$(read_setting model.task.temperature)"
	) || {
		echo "Error: Failed to extract search terms." >&2
		return 1
	}

	# Only take the first line
	terms=$(echo "${terms}" | head -n 1)

	# Remove [end of text] marker if needed
	terms="${terms//\[end of text\]/}"

	# Return results and trim whitespace
	echo "${terms## }"

	# Return successfully
	return 0
}
