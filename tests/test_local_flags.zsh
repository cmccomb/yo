#!/usr/bin/env zsh
# shellcheck enable=all

source tests/utilities.zsh

# Run setup
setup

# Test the --clipboard flag
echo 'the ball is under cup number 3' | pbcopy
answer_should_contain "3" "--task-model --clipboard what cup is the ball under"

# Test the --directory flag
answer_should_contain "$(pwd)" "--task-model --directory what directory am I in"

# Test the --file flag with a text file
echo "the ball is under cup number 3" >"secret.txt"
echo "the ball is really really under cup number 3" >"secret2.txt"
answer_should_contain "3" "--task-model --file secret.txt what cup is the ball under"
answer_should_contain "3" "--task-model --file secret.txt --file secret2.txt what cup is the ball under"
rm "secret.txt" "secret2.txt"

# Test the --system flag
answer_should_contain "$(sysctl -n hw.ncpu)" "--task-model --system how many cores do i have"

# Run cleanup
cleanup
