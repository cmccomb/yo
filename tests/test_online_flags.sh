#!/usr/bin/env sh
# shellcheck enable=all

. tests/utilities.sh

# Run setup
setup

# Test the --surf flag
answer_should_contain \
	"blue" \
	"--task-model --surf" \
	"what color is the sky"

# Test the --search flag
answer_should_contain \
	"more" \
	"--task-model --search \"mass of earth\" --search \"mass of moon\" " \
	"does the earth weigh more or less than the moon"

# Test the --website flag
#pid1=$(serve_text_on_port "the ball is under cup number 3" 8087)
#pid2=$(serve_text_on_port "the ball is really really under cup number 3" 8086)
#answer_should_contain \
#  "3|three" \
#  "--task-model --website \"http://localhost:8086\"" \
#  "what cup is the ball under"
#answer_should_contain \
#  "3|three" \
#  "--task-model --website \"http://localhost:8087\" --website \"http://localhost:8084\"" \
#  "what cup is the ball under"
#kill "${pid1}" "${pid2}"

# Run cleanup
cleanup
