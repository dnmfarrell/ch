#!/bin/sh
CH_ANS=0
CH_DIR="./tests/.run-$(date '+%Y%m%d%H%M%S').$$"
CH_URL='0:8111'
CH_REQ="$CH_DIR/.request.http"

. "./tests/tap.sh" || (printf "failed to source tap.sh\n" && exit 1)
. "./ch" || (printf "failed to source ch\n" && exit 1)

ch_bootstrap
tap_ok "$?" "ch_bootstrap"
ch_dep_check "nc" # for mock server response

nc -l -p 8111 -q 1 >"$CH_REQ" <./tests/response.http &
CH_MAX=25
CH_MKY=max_completion_tokens
CH_MOD="foo-25"
CH_TEM=0.8
CH_TOP=0.1
res=$(ch_new "lorem ipsum")
wait
tap_cmp "$res" "foo bar baz" "ch_new"
max=$(tail -n 1 "$CH_REQ" | jq -r .max_completion_tokens)
mod=$(tail -n 1 "$CH_REQ" | jq -r .model)
tem=$(tail -n 1 "$CH_REQ" | jq -r .temperature)
top=$(tail -n 1 "$CH_REQ" | jq -r .top_p)
tap_cmp "$max" "$CH_MAX" "CH_MAX"
tap_cmp "$mod" "$CH_MOD" "CH_MOD"
tap_cmp "$tem" "$CH_TEM" "CH_TEM"
tap_cmp "$top" "$CH_TOP" "CH_TOP"

res=$(ch_puts)
tap_cmp "$res" "lorem ipsum
foo bar baz" "ch_puts"

nc -l -p 8111 -q 1 >/dev/null <./tests/response.http &
res=$(ch_reply "ipso facto")
wait
tap_cmp "$res" "foo bar baz" "ch_reply"

res=$(ch_list)
tap_cmp "$res" $(ls "$CH_DIR"/*) "ch_list"

res=$(ch_puts)
tap_cmp "$res" "lorem ipsum
foo bar baz
ipso facto
foo bar baz" "ch_puts"

rm -rf "$CH_DIR"
tap_end
