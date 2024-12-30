#!/usr/bin/env zsh
# shellcheck enable=all
# Since this script is sourced into another script, many of the variables aren't used. For that reason, we disable SC2034
# to hide the warnings.
# shellcheck disable=SC2034

########################################################################################################################
### Set the repository and file names ##################################################################################
########################################################################################################################

# Define a function to help
function compose_repo_and_model_file_name() {

	# Parse arguments
	local username=$1 series=$2 size=$3 finetuning=$4 filetype=$5 quant=$6

	# Check that inputs are valid
	check_nonempty username || return 1
	check_nonempty series || return 1
	check_nonempty size || return 1
	check_nonempty finetuning || return 1
	check_nonempty filetype || return 1
	check_nonempty quant || return 1

	# Return the repository and model names
	echo "${username}/${series}-${size}-${finetuning}-$(echo "${filetype}" |
		tr '[:lower:]' '[:upper:]') ${series}-${size}-${finetuning}-${quant}.${filetype}"

	# Exit successfully
	return 0
}

# Set the repository and model names for the task model
read -r TASK_MODEL_REPO_NAME TASK_MODEL_FILE_NAME <<<"$(
	compose_repo_and_model_file_name \
		"${TASK_USERNAME:-"bartowski"}" \
		"${TASK_MODEL_SERIES:-"Llama3.1"}" \
		"${TASK_MODEL_SIZE:-"1B"}" \
		"${TASK_MODEL_FINETUNING_STYLE:-"Instruct"}" \
		"${TASK_MODEL_FILETYPE:-"GGUF"}" \
		"${TASK_MODEL_QUANT:-"Q4_K_M"}"
)" || {
	echo "Error: Failed to set the repository and model names for the task model." >&2
	return 1
}
readonly TASK_MODEL_REPO_NAME TASK_MODEL_FILE_NAME

# Set the repository and model names for the casual model
read -r CASUAL_MODEL_REPO_NAME CASUAL_MODEL_FILE_NAME <<<"$(
	compose_repo_and_model_file_name \
		"${CASUAL_GENERAL_USERNAME:-"bartowski"}" \
		"${CASUAL_MODEL_SERIES:-"Qwen2.5"}" \
		"${CASUAL_MODEL_SIZE:-"3B"}" \
		"${CASUAL_MODEL_FINETUNING_STYLE:-"Instruct"}" \
		"${CASUAL_MODEL_FILETYPE:-"GGUF"}" \
		"${CASUAL_MODEL_QUANT:-"Q4_K_M"}"
)" || {
	echo "Error: Failed to set the repository and model names for the casual model." >&2
	return 1
}
readonly CASUAL_MODEL_REPO_NAME CASUAL_MODEL_FILE_NAME

# Set the repository and model names for the balanced model
read -r BALANCED_MODEL_REPO_NAME BALANCED_MODEL_FILE_NAME <<<"$(
	compose_repo_and_model_file_name \
		"${BALANCED_GENERAL_USERNAME:-"bartowski"}" \
		"${BALANCED_MODEL_SERIES:-"Qwen2.5"}" \
		"${BALANCED_MODEL_SIZE:-"7B"}" \
		"${BALANCED_MODEL_FINETUNING_STYLE:-"Instruct"}" \
		"${BALANCED_MODEL_FILETYPE:-"GGUF"}" \
		"${BALANCED_MODEL_QUANT:-"Q4_K_M"}"
)" || {
	echo "Error: Failed to set the repository and model names for the balanced model." >&2
	return 1
}
readonly BALANCED_MODEL_REPO_NAME BALANCED_MODEL_FILE_NAME

# Set the repository and model names for the serious model
read -r SERIOUS_MODEL_REPO_NAME SERIOUS_MODEL_FILE_NAME <<<"$(
	compose_repo_and_model_file_name \
		"${SERIOUS_GENERAL_USERNAME:-"bartowski"}" \
		"${SERIOUS_MODEL_SERIES:-"Qwen2.5"}" \
		"${SERIOUS_MODEL_SIZE:-"14B"}" \
		"${SERIOUS_GENERAL_FINETUNING_STYLE:-"Instruct"}" \
		"${SERIOUS_GENERAL_MODEL_FILETYPE:-"GGUF"}" \
		"${SERIOUS_MODEL_QUANT:-"Q4_K_M"}"
)" || {
	echo "Error: Failed to set the repository and model names for the serious model." >&2
	return 1
}
readonly SERIOUS_MODEL_REPO_NAME SERIOUS_MODEL_FILE_NAME
