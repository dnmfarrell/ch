#!/bin/sh
TAP_TEST_COUNT=0
TAP_FAIL_COUNT=0

tap_pass() {
	TAP_TEST_COUNT=$((TAP_TEST_COUNT + 1))
	printf "ok %d %s\n" "$TAP_TEST_COUNT" "$1"
}

tap_fail() {
	TAP_TEST_COUNT=$((TAP_TEST_COUNT + 1))
	TAP_FAIL_COUNT=$((TAP_FAIL_COUNT + 1))
	printf "not ok %d %s\n" "$TAP_TEST_COUNT" "$1"
}

tap_end() {
	printf "1..%d\n" "$TAP_TEST_COUNT"
	exit $((TAP_FAIL_COUNT > 0)) # C semantics
}

tap_ok() {
	if [ "$1" -eq 0 ]; then
		tap_pass "$2"
	else
		tap_fail "$2"
	fi
}

tap_cmp() {
	if [ "$1" = "$2" ]; then
		tap_pass "$3"
	else
		tap_str=$(printf "%s - expected '%s' but got '%s'" "$3" "$2" "$1")
		tap_fail "$tap_str"
	fi
}
