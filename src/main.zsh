#!/usr/bin/env zsh
# shellcheck enable=all

########################################################################################################################
########################################################################################################################
######'                     `########'                ╭─────────────────────────────────────────╮                 `#####
####'    db    db  .d88b.     `####'                  │  Your AI Assistant in the Command Line  │                  `####
####     `8b  d8' .8P  Y8.     ####                   ╰─────────────────────────────────────────╯                   ####
####      `8bd8'  88    88     ####     If you are here, you are probably trying to fix or change something. If     ####
####        88    88    88     ####     you are here to fix something,  I am sorry it broke in the first place!     ####
####        88    `8b  d8'     ####     But either way, I hope that the documentation is helpful and I wish you     ####
####.       YP     `Y88P'     .####.     the best of luck. If you need help, please email: ccmcc2012@gmail.com     .####
######.                     .########.                                                                           .######
########################################################################################################################
########################################################################################################################

########################################################################################################################
### SOURCE EXTERNAL SCRIPTS ############################################################################################
########################################################################################################################

# Get the directory where this file is saved
DIR=$(dirname -- "$0")

# Check DIR to see if it ends with src
if [[ ${DIR} == *"src" ]]; then
	:
elif [[ ${DIR} == *"bin" ]]; then
	DIR+="/../share/yo"
fi

# Source the necessary files
source "${DIR}/help_and_version.zsh"
source "${DIR}/settings.zsh"
source "${DIR}/input_validation.zsh"
source "${DIR}/logging.zsh"
source "${DIR}/status_checks.zsh"
source "${DIR}/installation_management.zsh"
source "${DIR}/set_model_names.zsh"
source "${DIR}/web_search.zsh"
source "${DIR}/tokens.zsh"
source "${DIR}/content_processing.zsh"
source "${DIR}/prompt_generators.zsh"
source "${DIR}/llm_session_management.zsh"

########################################################################################################################
### MAIN FUNCTION ######################################################################################################
########################################################################################################################

### Parse arguments ####################################################################################################

# Define variables
query=""
file_path_list=""
website_url_list=""
search_term_list=""
surf_and_add_results=false
add_directory_info=false add_system_info=false add_clipboard_info=false add_usage_info=false
task_model_override=false casual_model_override=false balanced_model_override=false serious_model_override=false
image_path=""

# Make verbose a global variable
VERBOSE=false
QUIET=false

# Start parsing arguments
while [[ $# -gt 0 ]]; do
	case $1 in

	# Early exit with help message
	-h | --help)
		show_help
		return 0
		;;

	# Early exit with version information
	-V | --version)
		show_version
		return 0
		;;

	# Read in a file
	-f | --file)
		if [[ -n $2 && ! $2 =~ ^- ]]; then
			file_path_list+="$2\n"
			shift
		else
			echo "Error: --file requires a file." >&2
			return 1
		fi
		;;

	# Read in a file
	-i | --image)
		if [[ -n $2 && ! $2 =~ ^- ]]; then
			image_path=$2
			shift
		else
			echo "Error: --image requires a file." >&2
			return 1
		fi
		;;

	# Read in a file
	-w | --website)
		system_is_online || {
			echo "Error: You are not connected to the internet, so the --website flag is unavailable." >&2
			return 1
		}
		if [[ -n $2 && ! $2 =~ ^- ]]; then
			website_url_list+="$2\n"
			shift
		else
			echo "Error: --website requires a url." >&2
			return 1
		fi
		;;

	# Do some searching
	-s | --search)
		system_is_online || {
			echo "Error: You are not connected to the internet, so the --search flag is unavailable." >&2
			return 1
		}
		if [[ -n $2 && $2 =~ ^".*"$ ]]; then
			search_term_list+="$2\n"
			shift
		else
			echo "Error: --search requires quoted terms." >&2
			return 1
		fi
		;;

	# Make the output verbose
	-v | --verbose) VERBOSE=true ;;

	# Make the output quiet
	-q | --quiet) QUIET=true ;;

	# Surf the web with LLM-defined search terms
	-S | --surf)
		system_is_online || {
			echo "Error: You are not connected to the internet, so the --surf flag is unavailable." >&2
			return 1
		}

		surf_and_add_results=true
		;;

	# Update system
	-U | --update)
		timestamp_log_to_stderr "🔄" "Updating Yo..." >&2
		update_yo && return 0
		;;

	# Uninstall system
	-X | --uninstall)
		timestamp_log_to_stderr "🗑️" "Uninstalling Yo..." >&2
		uninstall_yo && return 0
		;;

	# Add system information to the context
	-y | --system) add_system_info=true ;;

	# Add directory information to the context
	-d | --directory) add_directory_info=true ;;

	# Add clipboard information to the context
	-c | --clipboard) add_clipboard_info=true ;;

	# Add the usage information to the context
	-u | --usage) add_usage_info=true ;;

	# Use the task model
	-tm | --task-model) task_model_override=true ;;

	# Use the casual model
	-cm | --casual-model) casual_model_override=true ;;

	# Use the balanced model
	-bm | --balanced-model) balanced_model_override=true ;;

	# Use the serious model
	-sm | --serious-model) serious_model_override=true ;;

	# If its something that looks like a flag but isn't one of the above, show an error
	-*)
		echo "Error: Unknown flag: $1" >&2
		return 1
		;;

	# If its not a flag, add it to the general query
	*) query+="$1 " ;;
	esac
	shift
done

### Print the starting time ############################################################################################
start_time=$(start_log)

### Configure the model based on whether its a one-off or interactive session ##########################################
if [[ -n "${query}" ]]; then
	model_name="casual"
	repo_name="${CASUAL_MODEL_REPO_NAME:-"bartowski/Qwen2.5-3B-Instruct-GGUF"}"
	file_name="${CASUAL_MODEL_FILE_NAME:-"Qwen2.5-3B-Instruct-Q4_K_M.gguf"}"
	temp="${CASUAL_MODEL_TEMP:-"0.2"}"
	mode="one-off"
	new_tokens="${ONEOFF_GENERATION_LENGTH:-"128"}"
	context_length="${ONEOFF_CONTEXT_LENGTH:-"-1"}"
else
	model_name="serious"
	repo_name="${SERIOUS_MODEL_REPO_NAME:-"bartowski/Qwen2.5-14B-Instruct-GGUF"}"
	file_name="${SERIOUS_MODEL_FILE_NAME:-"Qwen2.5-14B-Instruct-IQ4_XS.gguf"}"
	temp=${SERIOUS_MODEL_TEMP:-"0.2"}
	mode="interactive"
	new_tokens="${INTERACTIVE_GENERATION_LENGTH:-"512"}"
	context_length="${INTERACTIVE_CONTEXT_LENGTH:-"0"}"
fi

### Override the model if needed #######################################################################################
if [[ "${task_model_override}" == true ]]; then
	repo_name="${TASK_MODEL_REPO_NAME:-"bartowski/Llama-3.2-1B-Instruct-GGUF"}"
	file_name="${TASK_MODEL_FILE_NAME:-"Llama-3.2-1B-Instruct-Q4_K_M.gguf"}"
	temp="${TASK_MODEL_TEMP:-"0.2"}"
	timestamp_log_to_stderr "⚠️" "Overriding the ${model_name} model with the task model ${file_name}..." >&2
elif [[ "${casual_model_override}" == true && "${model_name}" != "casual" ]]; then
	repo_name="${CASUAL_MODEL_REPO_NAME:-"bartowski/Qwen2.5-3B-Instruct-GGUF"}"
	file_name="${CASUAL_MODEL_FILE_NAME:-"Qwen2.5-3B-Instruct-Q4_K_M.gguf"}"
	temp="${CASUAL_MODEL_TEMP:-"0.2"}"
	timestamp_log_to_stderr "⚠️" "Overriding the ${model_name} model with the casual model ${file_name}..." >&2
elif [[ "${balanced_model_override}" == true ]]; then
	repo_name="${BALANCED_MODEL_REPO_NAME:-"bartowski/Qwen2.5-7B-Instruct-GGUF"}"
	file_name="${BALANCED_MODEL_FILE_NAME:-"Qwen2.5-7B-Instruct-Q4_K_M.gguf"}"
	temp="${BALANCED_MODEL_TEMP:-"0.2"}"
	timestamp_log_to_stderr "⚠️" "Overriding the ${model_name} model with the balanced model ${file_name}..." >&2
elif [[ "${serious_model_override}" == true && "${model_name}" != "serious" ]]; then
	repo_name="${SERIOUS_MODEL_REPO_NAME:-"bartowski/Qwen2.5-14B-Instruct-GGUF"}"
	file_name="${SERIOUS_MODEL_FILE_NAME:-"Qwen2.5-14B-Instruct-IQ4_XS.gguf"}"
	temp="${SERIOUS_MODEL_TEMP:-"0.2"}"
	timestamp_log_to_stderr "⚠️" "Overriding the ${model_name} model with the serious model ${file_name}..." >&2
fi

### Generate the prompt ################################################################################################
prompt=$(
	generate_prompt \
		"${mode}" \
		"${query}" \
		"${file_path_list}" \
		"${search_term_list}" \
		"${website_url_list}" \
		"${image_path}" \
		"${surf_and_add_results}" \
		"${add_usage_info}" \
		"${add_system_info}" \
		"${add_directory_info}" \
		"${add_clipboard_info}"
) || {
	echo "Error: Failed to generate prompt." >&2
	return 1
}

### Kick off the LLM ###################################################################################################
start_llama_session \
	"${repo_name}" \
	"${file_name}" \
	"${prompt}" \
	"${mode}" \
	"${new_tokens}" \
	"${context_length}" \
	"${temp}"

### Print the elapsed time #############################################################################################
end_log "${start_time}"

### Show that verbose and quiet are used ###############################################################################
: "${VERBOSE} ${QUIET}"

### Return success #####################################################################################################
return 0
