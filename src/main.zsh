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
	DIR+="/.yo-scripts"
fi

# Source the necessary files
source "${DIR}/help_and_version.sh"
source "${DIR}/settings.sh"
source "${DIR}/input_validation.sh"
source "${DIR}/logging.sh"
source "${DIR}/status_checks.sh"
source "${DIR}/installation_management.sh"
source "${DIR}/web_search.sh"
source "${DIR}/tokens.sh"
source "${DIR}/content_processing.sh"
source "${DIR}/prompt_generators.sh"
source "${DIR}/llm_session_management.sh"

# Write a settings file if there isn't one already
if [[ ! -f "${HOME}/.yo.yaml" ]]; then
	write_default_settings_file
fi

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

# Make verbose a global variable
VERBOSE=false
QUIET=false

# Update or uninstall based on the first argument
case $1 in
download)
	# Check if there is a subsequent argument. if so, download that model ("task", "casual", "balanced", "serious") using model_is_available
	if [[ -n $2 && ! $2 =~ ^- ]]; then
		case $2 in
		task)
			model_is_available "$(read_setting model.task.repository)" "$(read_setting model.task.filename)" && return 0
			;;
		casual)
			model_is_available "$(read_setting model.casual.repository)" "$(read_setting model.casual.filename)" && return 0
			;;
		balanced)
			model_is_available "$(read_setting model.balanced.repository)" "$(read_setting model.balanced.filename)" && return 0
			;;
		serious)
			model_is_available "$(read_setting model.serious.repository)" "$(read_setting model.serious.filename)" && return 0
			;;
		everything | all)
			model_is_available "$(read_setting model.task.repository)" "$(read_setting model.task.filename)" &&
				model_is_available "$(read_setting model.casual.repository)" "$(read_setting model.casual.filename)" &&
				model_is_available "$(read_setting model.balanced.repository)" "$(read_setting model.balanced.filename)" &&
				model_is_available "$(read_setting model.serious.repository)" "$(read_setting model.serious.filename)" && return 0
			;;
		*)
			echo "Error: Unknown model: $2" >&2
			return 1
			;;
		esac
	else
		echo "Error: download requires a model name (task, casual, balanced, serious), or use all to download all models." >&2
		return 1
	fi

	;;
update)
	timestamp_log_to_stderr "🔄" "Updating Yo..." >&2
	update_yo && return 0
	;;
uninstall)
	timestamp_log_to_stderr "🗑️" "Uninstalling Yo..." >&2
	uninstall_yo && return 0
	;;
settings)
	# If there is no following value, read the settings
	if [[ -z $2 ]]; then
		read_setting ""
		return 0
	else
		# If there is no third value, then read the setting
		if [[ -z $3 ]]; then
			if [[ "$2" == "reset" ]]; then
				write_default_settings_file
				return 0
			else
				read_setting "$2"
				return 0
			fi
		else
			write_setting "$2" "$3"
			return 0
		fi
	fi
	;;
*)
	:
	;;
esac

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
	repo_name="$(read_setting model.casual.repository)"
	file_name="$(read_setting model.casual.filename)"
	temp="$(read_setting model.casual.temperature)"
	mode="one-off"
	new_tokens="$(read_setting mode.oneoff.generation_length)"
	context_length="$(read_setting mode.oneoff.context_length)"
else
	model_name="serious"
	repo_name="$(read_setting model.serious.repository)"
	file_name="$(read_setting model.serious.filename)"
	temp="$(read_setting model.serious.temperature)"
	mode="interactive"
	new_tokens="$(read_setting mode.interactive.generation_length)"
	context_length="$(read_setting mode.interactive.context_length)"
fi

### Override the model if needed #######################################################################################
if [[ "${task_model_override}" == true ]]; then
	repo_name="$(read_setting model.task.repository)"
	file_name="$(read_setting model.task.filename)"
	temp="$(read_setting model.task.temperature)"
	timestamp_log_to_stderr "⚠️" "Overriding the ${model_name} model with the task model ${file_name}..." >&2
elif [[ "${casual_model_override}" == true && "${model_name}" != "casual" ]]; then
	repo_name="$(read_setting model.casual.repository)"
	file_name="$(read_setting model.casual.filename)"
	temp="$(read_setting model.casual.temperature)"
	timestamp_log_to_stderr "⚠️" "Overriding the ${model_name} model with the casual model ${file_name}..." >&2
elif [[ "${balanced_model_override}" == true ]]; then
	repo_name="$(read_setting model.balanced.repository)"
	file_name="$(read_setting model.balanced.filename)"
	temp="$(read_setting model.balanced.temperature)"
	timestamp_log_to_stderr "⚠️" "Overriding the ${model_name} model with the balanced model ${file_name}..." >&2
elif [[ "${serious_model_override}" == true && "${model_name}" != "serious" ]]; then
	repo_name="$(read_setting model.serious.repository)"
	file_name="$(read_setting model.serious.filename)"
	temp="$(read_setting model.serious.temperature)"
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
