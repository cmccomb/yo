#!/usr/bin/env zsh
# shellcheck enable=all

# Set up the test environment
function setup() {

	# Warm up yo
	src/main.sh download task
	src/main.sh say hi -tm &>/dev/null

	# Send a message of the form
	local script_with_line="${funcfiletrace[1]:-"Yo"}"
	printf "\n===========================================================================================================\n"
	printf "\033[1mRunning tests in %s\033[0m\n" "${script_with_line%%:*}"
	printf "===========================================================================================================\n\n"

	# Set up counters
	PASSES=0
	FAILS=0
}

function answer_should_contain() {
	# Parse arguments
	local expected=$1
	local arguments=$2
	local query=$3

	# Print test description
	echo "  Testing query: 'yo ${arguments} ${query}' (answer must match \"${expected}\")"

	# Measure start time
	local start_time
	start_time=$(perl -MTime::HiRes=time -e 'printf "%.9f\n", time')

	# Make variables
	local output
  output=$(eval "src/main.sh ${arguments} ${query} --verbose" 2>&1)

	# Measure end time
	local end_time
	end_time=$(perl -MTime::HiRes=time -e 'printf "%.9f\n", time')

	# Calculate elapsed time
	local elapsed_time
	elapsed_time=$(printf "%.2f" $((end_time - start_time)))

	if [[ "${output}" =~ ${expected} ]]; then
		echo "    ✅ Test passed in ${elapsed_time}s with answer: ${output}"
		((PASSES += 1))
		return 0
	else
		echo "    ❌ Test failed in ${elapsed_time}s with answer: ${output}"
		((FAILS += 1))
		return 1
	fi
}

# Write text to a file
function serve_text_on_port() {
	# Parse arguments
	local text=$1
	local port=$2

	# Start a web server
	while true; do
		echo -e "HTTP/1.1 200 OK\r\nContent-Length: ${#text}\r\n\r\n${text}" | nc -l "${port}"
	done &

	# Return the PID of the web server
	echo $!
}

# Write text to a file
function write_text_to_tmp() {
	# Parse arguments
	local text=$1

	# Save the text to random filename in /tmp
	echo "${text}" >"${file:=$(mktemp)}"

	# Return the file path
	echo "${file}"
}

# Clean up the test environment
function cleanup() {
	if [[ "${FAILS}" -gt 0 ]]; then
		printf "  ⚠️ \033[1mTests complete. \033[32m%s passed\033[0m, \033[31m%s failed.\033[0m\033[0m\n" "${PASSES}" "${FAILS}"
		exit 1
	else
		printf "  🎉 \033[1mTests complete. \033[32m%s passed\033[0m, \033[31m%s failed.\033[0m\033[0m\n" "${PASSES}" "${FAILS}"
		exit 0
	fi
}
