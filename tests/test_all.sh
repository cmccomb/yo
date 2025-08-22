#!/usr/bin/env sh
# shellcheck enable=all

sh tests/test_reasoning_tags.sh
sh tests/test_basic_queries.sh
sh tests/test_static_flags.sh
sh tests/test_local_flags.sh
sh tests/test_online_flags.sh
#sh tests/test_commands.sh
