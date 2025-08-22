#!/usr/bin/env sh
# shellcheck enable=all

. src/llm_session_management.sh

sample='<think>
reasoning
</think>
answer'

result=$(printf '%s' "$sample" | remove_reasoning_tags)

if [ "$result" = "answer" ]; then
    echo "  ✅ Reasoning tags removed correctly"
    exit 0
else
    echo "  ❌ Failed to remove reasoning tags: $result" >&2
    exit 1
fi
