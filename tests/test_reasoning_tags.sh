#!/usr/bin/env sh
# shellcheck enable=all

. ./src/llm_session_management.sh

sample='<think>
reasoning
</think>
answer'

result=$(printf '%s' "${sample}" | remove_reasoning_tags)

if [ "${result}" = "answer" ]; then
	echo "  ✅ Reasoning tags removed correctly"
else
	echo "  ❌ Failed to remove reasoning tags: ${result}" >&2
	exit 1
fi

VERBOSE=true
result_verbose=$(printf '%s' "${sample}" | remove_reasoning_tags)

if [ "${result_verbose}" = "${sample}" ]; then
	echo "  ✅ Reasoning tags preserved when verbose"
	exit 0
else
	echo "  ❌ Reasoning tags should have been preserved when verbose: ${result_verbose}" >&2
	exit 1
fi
