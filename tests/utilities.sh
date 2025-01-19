#!/usr/bin/env sh
# shellcheck enable=all

# Set up the test environment
setup() {

	# Name of test block
	title=$1

	# Warm up yo
	src/main.sh download task
	src/main.sh say hi -tm >/dev/null 2>&1

	# Send a message of the form
	printf "\n===========================================================================================================\n"
	printf "\033[1mRunning tests in %s\033[0m\n" "${title%%:*}"
	printf "===========================================================================================================\n\n"

	# Set up counters
	PASSES=0
	FAILS=0
}

get_epoch_time_in_seconds() {
	perl -MTime::HiRes=time -e 'printf "%.9f\n", time'
}

answer_should_contain() {
	# Parse arguments
	expected=$1
	arguments=$2
	query=$3

	# Print test description
	echo "  Testing query: 'yo ${arguments} ${query}' (answer must match \"${expected}\")"

	# Measure start time
	start_time=$(perl -MTime::HiRes=time -e 'printf "%.9f\n", time')

	# Make variables
	output=$(eval "src/main.sh ${arguments} ${query} --quiet" 2>&1)

	# Measure end time
	end_time=$(perl -MTime::HiRes=time -e 'printf "%.9f\n", time')

	# Calculate elapsed time
	elapsed_time=$(printf "%.2f" "$(echo "${end_time} - ${start_time}" | bc)")

	# Replace - with \- in expected
	expected=$(echo "${expected}" | sed 's/-/\\-/g')

	if echo "${output}" | grep -qE "${expected}"; then
		echo "    ✅ Test passed in ${elapsed_time}s with answer: ${output}"
		PASSES=$((PASSES + 1))
		return 0
	else
		echo "    ❌ Test failed in ${elapsed_time}s with answer: ${output}"
		FAILS=$((FAILS + 1))
		return 1
	fi
}

# Write text to a file
serve_text_on_port() {
	# Parse arguments
	text=$1
	port=$2

	# Start a web server
	while true; do
		printf "HTTP/1.1 200 OK\r\nContent-Length: %s\r\n\r\n%s" "${#text}" "${text}" | nc -l "${port}"
	done &

	# Return the PID of the web server
	echo $!
}

# Write text to a file
write_text_to_tmp() {
	# Parse arguments
	text=$1

	# Save the text to random filename in /tmp
	echo "${text}" >"${file:=$(mktemp)}"

	# Return the file path
	echo "${file}"
}

# Clean up the test environment
cleanup() {
	if [ "${FAILS}" -gt 0 ]; then
		printf "  ⚠️ \033[1mTests complete. \033[32m%s passed\033[0m, \033[31m%s failed.\033[0m\033[0m\n" "${PASSES}" "${FAILS}"
		exit 1
	else
		printf "  🎉 \033[1mTests complete. \033[32m%s passed\033[0m, \033[31m%s failed.\033[0m\033[0m\n" "${PASSES}" "${FAILS}"
		exit 0
	fi
}
