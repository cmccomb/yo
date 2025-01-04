#!/usr/bin/env zsh
# shellcheck enable=all
# Since this script is sourced into another script, many of the variables aren't used. For that reason, we disable SC2034
# to hide the warnings.
# shellcheck disable=SC2034

########################################################################################################################
### CONSTANTS AND SETTINGS #############################################################################################
########################################################################################################################

# Write settings file
function write_default_settings_file() {
	cat <<-EOF >~/.yo.yaml
		# General settings
		general:
		  maximum_file_content_length: 300000      # Maximum length of file content to process
		  token_estimation_correction_factor: 1.2  # Factor to multiply the token count by as a factor of safety
		  characters_per_token: 4                  # Average number of characters per token

		# Mode specific settings
		mode:
		  oneoff:                   # One-off mode occurs when you provide a single query
		    generation_length: 128  # Maximum length of the generated text
		    context_length: -1      # Context length to allow the model, -1 means to shrink to fit
		  interactive:              # Interactive mode occurs when you open a conversation
		    generation_length: 512  # Maximum length of the generated text
		    context_length: 4096    #  Context length to allow the model, -1 means to shrink to fit
		  search_term_generation:   # Search term generation mode occurs in the backgroudn during the --surf flag
		    generation_length: 8    # Maximum length of the generated text
		    context_length: -1      # Context length to allow the model, -1 means to shrink to fit
		  compression:              # Compression mode occurs when you provide a large amount of text
		    generation_length: 128  # Maximum length of the generated text
		    chunk_length: 4096      # Length of the chunks to compress
		    trigger_length: 4096    # Length of the text that triggers compression
		    context_length: -1      # Context length to allow the model, -1 means to shrink to fit
		    # Model settings
		model:
		  task:                                                    # The task model is invoked for search term generation and compression
		    repository: bartowski/Llama-3.2-1B-Instruct-GGUF       # The HuggingFace repository where the model is stored
		    filename: Llama-3.2-1B-Instruct-Q4_K_M.gguf            # The filename of the model in the repository
		    temperature: 0.1                                       # The temperature to use for this model
		  casual:                                                  # The casual model is invoked for oneoff requests
		    repository: bartowski/Qwen2.5-3B-Instruct-GGUF         # The HuggingFace repository where the model is stored
		    filename: Qwen2.5-3B-Instruct-Q4_K_M.gguf              # The filename of the model in the repository
		    temperature: 0.2                                       # The temperature to use for this model
		  balanced:                                                # The balanced model is never invoked by default
		    repository: bartowski/Qwen2.5-7B-Instruct-GGUF         # The HuggingFace repository where the model is stored
		    filename: Qwen2.5-7B-Instruct-Q4_K_M.gguf              # The filename of the model in the repository
		    temperature: 0.2                                       # The temperature to use for this model
		  serious:                                                 # The serious model is invoked for interactive conversations
		    repository: bartowski/Qwen2.5-Coder-14B-Instruct-GGUF  # The HuggingFace repository where the model is stored
		    filename: Qwen2.5-Coder-14B-Instruct-IQ4_XS.           # The filename of the model in the repository
		    temperature: 0.2                                       # The temperature to use for this model
		# Search settings
		search:
		  google_cse:
		    api_key: AIzaSyBBXNq-DX1ENgFAiGCzTawQtWmRMSbDljk               # Google Custom Search API key
		    id: 003333935467370160898:f2ntsnftsjy                          # Google Custom Search Engine ID
		    base_url: https://customsearch.googleapis.com/customsearch/v1  # Google Custom Search base URL
	EOF
}

# Read a value from the settings file
function read_setting() {
	yq -e ".${1}" ~/.yo.yaml || {
		echo "Error: Failed to read setting ${1}." >&2
		return 1
	}
}

# Write a value to the settings file
function write_setting() {
	old_value=$(read_setting "${1}") || return 1
	echo "Old value for ${1}: ${old_value}"
	yq -i ".${1} = \"${2}\"" ~/.yo.yaml >/dev/null
	echo "New value for ${1}: $(read_setting "${1}")"
}
