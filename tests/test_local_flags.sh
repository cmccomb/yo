#!/usr/bin/env sh
# shellcheck enable=all

. tests/utilities.sh

# Run setup
setup

# Test the --clipboard flag
echo 'the ball is under cup number 3' | pbcopy
answer_should_contain \
	"3|three" \
	"--task-model --clipboard" \
	"what cup is the ball under"

# Test the --directory flag
answer_should_contain \
	"$(basename "$(pwd)")" \
	"--task-model --directory" \
	"what directory am I in"

# Test the --file flag
file1=$(write_text_to_tmp "the ball is under cup number 3")
file2=$(write_text_to_tmp "the ball is really really under cup number 3")
answer_should_contain \
	"3|three" \
	"--task-model --file ${file1}" \
	"what cup is the ball under"
answer_should_contain \
	"3|three" \
	"--task-model --file ${file1} --file ${file2}" \
	"what cup is the ball under"

# Test the --system flag
answer_should_contain \
	"$(sysctl -n hw.ncpu)" \
	"--task-model --system" \
	"how many cores do i have"

# Text the --text flag
answer_should_contain \
  "3|three" \
  "--task-model --text 'the ball is under cup number 3'" \
  "what cup is the ball under"
answer_should_contain \
  "3|three" \
  "--task-model --text 'the ball is under cup number 3' --text 'the ball is really really under cup number 3'" \
  "what cup is the ball under"

# Run cleanup
cleanup
