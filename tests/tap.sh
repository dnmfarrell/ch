#!/bin/sh
TAP_TEST_COUNT=0
TAP_FAIL_COUNT=0

tap_pass() {
	TAP_TEST_COUNT=$((TAP_TEST_COUNT + 1))
	echo "ok $TAP_TEST_COUNT $1"
}

tap_fail() {
	TAP_TEST_COUNT=$((TAP_TEST_COUNT + 1))
	TAP_FAIL_COUNT=$((TAP_FAIL_COUNT + 1))
	echo "not ok $TAP_TEST_COUNT $1"
}

tap_end() {
	echo "1..$TAP_TEST_COUNT"
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
		tap_fail "$3 - expected '$2' but got '$1'"
	fi
}
