#!/usr/bin/env zsh
# shellcheck enable=all

########################################################################################################################
### INPUT CHECKING #####################################################################################################
########################################################################################################################

function get_value_from_name() {
	eval echo "\${${variable_name}}"
}

# Check if the input is empty
function check_nonempty() {

	# Parse arguments
	local variable_name=$1

	# Make variables
	local variable_value
	variable_value=$(get_value_from_name variable_name)

	# Check if the input is empty
	if [[ -z "${variable_value}" ]]; then
		echo "Error in ${funcstack[2]:-"Yo"}: Invalid input for ${variable_name}, expected a non-empty string." >&2
		return 1
	else
		return 0
	fi
}

# Check if the input is an integer and print an error message with the name of the variable if not
function check_integer() {

	# Parse arguments
	local variable_name=$1

	# Check that inputs are non-empty
	check_nonempty variable_name || return 1

	# Make variables
	local variable_value
	variable_value=$(get_value_from_name variable_name)

	# Check if the input is an integer
	if [[ ! "${variable_value}" =~ ^-?[0-9]+$ ]]; then
		echo "Error in ${funcstack[2]}: Invalid input ${variable_name}=\"${variable_value}\", expected an integer." >&2
		return 1
	else
		return 0
	fi
}

# Check if the input is Boolean
function check_boolean() {

	# Parse arguments
	local variable_name=$1

	# Check that inputs are non-empty
	check_nonempty variable_name || return 1

	# Make variables
	local variable_value
	variable_value=$(get_value_from_name variable_name)

	# Check if the input is Boolean
	if [[ "${variable_value}" != true && "${variable_value}" != false ]]; then
		echo "Error in ${funcstack[2]}: Invalid input ${variable_name}=\"${variable_value}\", expected a boolean." >&2
		return 1
	else
		return 0
	fi
}

# Check if the input is a float
function check_float() {

	# Parse arguments
	local variable_name=$1

	# Check that inputs are non-empty
	check_nonempty variable_name || return 1

	# Make variables
	local variable_value
	variable_value=$(get_value_from_name variable_name)

	# Check if the input is a float
	if [[ ! ${variable_value} =~ ^-?[0-9]*\.?[0-9]+$ ]]; then
		echo "Error in ${funcstack[2]}: Invalid input ${variable_name}=\"${variable_value}\", expected a float." >&2
		return 1
	else
		return 0
	fi
}

# Check if the input is a filepath
function check_path() {

	# Parse arguments
	local variable_name=$1

	# Check that inputs are non-empty
	check_nonempty variable_name || return 1

	# Make variables
	local variable_value
	variable_value=$(get_value_from_name variable_name)

	# Check if the input is a valid path
	if [[ ! -f "${variable_value}" ]]; then
		echo "Error in ${funcstack[2]}: Invalid input ${variable_name}=\"${variable_value}\", expected a valid path." >&2
		return 1
	else
		return 0
	fi
}

# Check if hte input is a url
function check_url() {

	# Parse arguments
	local variable_name=$1

	# Check that inputs are non-empty
	check_nonempty variable_name || return 1

	# Make variables
	local variable_value
	variable_value=$(get_value_from_name variable_name)

	# Check if the input is a valid URL
	if [[ ! "${variable_value}" =~ ^https?://[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}(/.*)?$ ]]; then
		echo "Error in ${funcstack[2]}: Invalid input ${variable_name}=\"${variable_value}\", expected a valid URL." >&2
		return 1
	else
		return 0
	fi
}

# Check if the input is a valid emoji
function check_emoji() {

	# Parse arguments
	local variable_name=$1

	# Check that inputs are non-empty
	check_nonempty variable_name || return 1

	# Make variables
	local variable_value
	variable_value=$(get_value_from_name variable_name)

	# Check if the input is a valid emoji
	if [[ ! "${variable_value}" =~ [😀-🙏🌀-🗿] ]]; then
		echo "Error in ${funcstack[2]}: Invalid input ${variable_name}=\"${variable_value}\", expected a valid emoji." >&2
		return 1
	else
		return 0
	fi
}

# Check if the input is a valid mode
function check_mode() {

	# Parse arguments
	local variable_name=$1

	# Check that inputs are non-empty
	check_nonempty variable_name || return 1

	# Make variables
	local variable_value
	variable_value=$(get_value_from_name variable_name)

	# Check if the input is a valid mode, meaning that it is one of "interactive", "one-off", or "task"
	if [[ "${variable_value}" != "interactive" && "${variable_value}" != "one-off" && "${variable_value}" != "task" ]]; then
		echo "Error in ${funcstack[2]}: Invalid input ${variable_name}=\"${variable_value}\", expected one of \"interactive\", \"one-off\", or \"task\"." >&2
		return 1
	else
		return 0
	fi
}
