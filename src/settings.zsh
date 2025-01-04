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
		general:
		  maximum_file_content_length: 300000
		  token_estimation_correction_factor: 1.2
		  characters_per_token: 4
		mode:
		  oneoff:
		    generation_length: 128
		    context_length: -1
		  interactive:
		    generation_length: 512
		    context_length: 4096
		  search_term_generation:
		    generation_length: 8
		    context_length: -1
		  compression:
		    generation_length: 128
		    chunk_length: 4096
		    trigger_length: 4096
		    context_length: -1
		model:
		  task:
		    repository: bartowski/Llama-3.2-1B-Instruct-GGUF
		    filename: Llama-3.2-1B-Instruct-Q4_K_M.gguf
		    temperature: 0.1
		  casual:
		    repository: bartowski/Qwen2.5-3B-Instruct-GGUF
		    filename: Qwen2.5-3B-Instruct-Q4_K_M.gguf
		    temperature: 0.2
		  balanced:
		    repository: bartowski/Qwen2.5-7B-Instruct-GGUF
		    filename: Qwen2.5-7B-Instruct-Q4_K_M.gguf
		    temperature: 0.2
		  serious:
		    repository: bartowski/Qwen2.5-Coder-14B-Instruct-GGUF
		    filename: Qwen2.5-Coder-14B-Instruct-IQ4_XS.gguf
		    temperature: 0.2
		search:
		  google_cse:
		    api_key: AIzaSyBBXNq-DX1ENgFAiGCzTawQtWmRMSbDljk
		    id: 003333935467370160898:f2ntsnftsjy
		    base_url: https://customsearch.googleapis.com/customsearch/v1

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
	yq -i ".${1} = \"${2}\"" ~/.yo.yaml > /dev/null
  echo "New value for ${1}: $(read_setting "${1}")"
}