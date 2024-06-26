#!/bin/sh
CH_AUT=0
CH_ANS=0
CH_DIR="./tests/.run-$(date '+%Y%m%d%H%M%S').$$"
CH_URL='0:8111'

. "./tests/tap.sh" || (printf "failed to source tap.sh\n" && exit 1)
. "./ch" || (printf "failed to source ch\n" && exit 1)

ch_bootstrap
tap_ok "$?" "ch_bootstrap"
ch_dep_check "nc" # for mock server response

nc -l -p 8111 -q 1 >/dev/null <./tests/response.http &
res=$(ch_new "lorem ipsum")
wait
tap_cmp "$res" "foo bar baz" "ch_new"

res=$(ch_puts)
tap_cmp "$res" "lorem ipsum
foo bar baz" "ch_puts"

nc -l -p 8111 -q 1 >/dev/null <./tests/response.http &
res=$(ch_title_gen "lorem ipsum")
wait
tap_cmp "$res" "foo bar baz" "ch_title_gen"

nc -l -p 8111 -q 1 >/dev/null <./tests/response.http &
res=$(ch_reply "ipso facto")
wait
tap_cmp "$res" "foo bar baz" "ch_reply"

res=$(ch_list)
tap_cmp "$res" "$CH_DIR/foo bar baz" "ch_list"

res=$(ch_puts)
tap_cmp "$res" "lorem ipsum
foo bar baz
ipso facto
foo bar baz" "ch_puts"

nc -l -p 8111 -q 1 >/dev/null <./tests/response.http &
CH_PRE=./tests/preamble.txt
res=$(
	ch_new "lorem ipsum" >/dev/null
	ch_puts
)
wait
tap_cmp "$res" "this is the preamble text.
lorem ipsum
foo bar baz" "CH_PRE"

rm -rf "$CH_DIR"
tap_end
