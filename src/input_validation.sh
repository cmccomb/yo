#!/usr/bin/env sh
# shellcheck enable=all

# Check if the input is empty
check_nonempty() {

	# Parse arguments
	variable_name=$1

	# Make variables
	eval "variable_value=\${$1}"

	# Check if the input is empty
	if [ -z "${variable_value}" ]; then
		echo "Error in Yo: Invalid input for ${variable_name}, expected a non-empty string." >&2
		return 1
	else
		return 0
	fi
}

# Check if the input is an integer and print an error message with the name of the variable if not
check_integer() {

	# Parse arguments
	variable_name=$1

	# Check that inputs are non-empty
	check_nonempty variable_name || return 1

	# Make variables
	eval "variable_value=\${$1}"

	# Check if the input is an integer
	if ! echo "${variable_value}" | grep -Eq '^-?[0-9]+$'; then
		echo "Error in Yo: Invalid input ${variable_name}=\"${variable_value}\", expected an integer." >&2
		return 1
	else
		return 0
	fi
}

# Check if the input is Boolean
check_boolean() {

	# Parse arguments
	variable_name=$1

	# Check that inputs are non-empty
	check_nonempty variable_name || return 1

	# Make variables
	eval "variable_value=\${$1}"

	# Check if the input is Boolean
	if [ "${variable_value}" != true ] && [ "${variable_value}" != false ]; then
		echo "Error in Yo: Invalid input ${variable_name}=\"${variable_value}\", expected a boolean." >&2
		return 1
	else
		return 0
	fi
}

# Check if the input is a float
check_float() {

	# Parse arguments
	variable_name=$1

	# Check that inputs are non-empty
	check_nonempty variable_name || return 1

	# Make variables
	eval "variable_value=\${$1}"

	# Check if the input is a float
	if ! echo "${variable_value}" | grep -Eq '^-?[0-9]*\.?[0-9]+$'; then
		echo "Error in Yo: Invalid input ${variable_name}=\"${variable_value}\", expected a float." >&2
		return 1
	else
		return 0
	fi
}

# Check if the input is a filepath
check_path() {

	# Parse arguments
	variable_name=$1

	# Check that inputs are non-empty
	check_nonempty variable_name || return 1

	# Make variables
	eval "variable_value=\${$1}"

	# Check if the input is a valid path
	if [ ! -f "${variable_value}" ]; then
		echo "Error in Yo: Invalid input ${variable_name}=\"${variable_value}\", expected a valid path." >&2
		return 1
	else
		return 0
	fi
}

# Check if hte input is a url
check_url() {

	# Parse arguments
	variable_name=$1

	# Check that inputs are non-empty
	check_nonempty variable_name || return 1

	# Make variables
	eval "variable_value=\${$1}"

	# Check if the input is a valid URL
	if ! echo "${variable_value}" | grep -Eq '^https?://[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}(/.*)?$'; then
		echo "Error in Yo: Invalid input ${variable_name}=\"${variable_value}\", expected a valid URL." >&2
		return 1
	else
		return 0
	fi
}

# Check if the input is a valid emoji
check_emoji() {

	# Parse arguments
	variable_name=$1

	# Check that inputs are non-empty
	check_nonempty variable_name || return 1

	# Make variables
	eval "variable_value=\${$1}"

	# Check if the input is a valid emoji
	if ! echo "${variable_value}" | grep -Eq '[😀-🙏🌀-🗿]'; then
		echo "Error in Yo: Invalid input ${variable_name}=\"${variable_value}\", expected a valid emoji." >&2
		return 1
	else
		return 0
	fi
}

# Check if the input is a valid mode
check_mode() {

	# Parse arguments
	variable_name=$1

	# Check that inputs are non-empty
	check_nonempty variable_name || return 1

	# Make variables
	eval "variable_value=\${$1}"

	# Check if the input is a valid mode, meaning that it is one of "interactive", "one-off", or "task"
	if [ "${variable_value}" != "interactive" ] && [ "${variable_value}" != "one-off" ] && [ "${variable_value}" != "task" ]; then
		echo "Error in Yo: Invalid input ${variable_name}=\"${variable_value}\", expected one of \"interactive\", \"one-off\", or \"task\"." >&2
		return 1
	else
		return 0
	fi
}
