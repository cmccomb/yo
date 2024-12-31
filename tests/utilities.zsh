#!/usr/bin/env zsh
# shellcheck enable=all

function setup() {
	# Make sure zsh exists, and install if not
	if ! command -v yo &>/dev/null; then
		echo "Yo is not installed. Installing..."
		curl -s https://cmccomb.com/yo/install -o /tmp/yo_install.sh || {
			echo "Error: Failed to download the install script." >&2
			return 1
		}
		sudo zsh /tmp/yo_install.sh || {
			echo "Error: Failed to run the install script." >&2
			return 1
		}
	fi

	# Warm up yo
	yo say hi -tm &>/dev/null

	# Send a message of the form
	local script_with_line="${funcfiletrace[1]:-"Yo"}"
	printf "\n===========================================================================================================\n"
	printf "\033[1mRunning tests in %s\033[0m\n" "${script_with_line%%:*}"
	printf "===========================================================================================================\n\n"

	# Set up counters
	PASSES=0
	FAILS=0
}

function cleanup() {
	if [[ "${FAILS}" -gt 0 ]]; then
		printf "  ⚠️ \033[1mTests complete. \033[32m%s passed\033[0m, \033[31m%s failed.\033[0m\033[0m\n" "${PASSES}" "${FAILS}"
		exit 1
	else
		printf "  🎉 \033[1mTests complete. \033[32m%s passed\033[0m, \033[31m%s failed.\033[0m\033[0m\n" "${PASSES}" "${FAILS}"
		exit 0
	fi
}

function answer_should_contain() {
	# Parse arguments
	local expected=$1
	local query="${*:2}"

	# Print test description
	echo "  Testing query: 'yo ${query}' (answer must contain \"${expected}\")"

	# Measure start time
	local start_time
	start_time=$(gdate +%s.%N)

	# Make variables
	local output
	output=$(eval "yo ${query} --quiet")

	# Measure end time
	local end_time
	end_time=$(gdate +%s.%N)

	# Calculate elapsed time
	local elapsed_time
	elapsed_time=$(printf "%.2f" $((end_time - start_time)))

	if [[ "${output}" == *"${expected}"* ]]; then
		echo "    ✅ Test passed in ${elapsed_time}s with answer: ${output}"
		((PASSES += 1))
		return 0
	else
		echo "    ❌ Test failed in ${elapsed_time}s with answer: ${output}"
		((FAILS += 1))
		return 1
	fi
}
