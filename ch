#!/bin/sh
ANS="${CH_ANS:-}"                      # bold replies? (default for tty)
AUT="${CH_AUT:-}"                      # autogen title (default for tty)
CON="${CH_CON:-5}"                     # connect timeout
CUR="${CH_CUR:-.cur}"                  # symlink to current chat file
DIR="${CH_DIR:-${TMPDIR:-/tmp}/chgpt}" # save chats here
FRM="${CH_FRM:-text}"                  # Response format: (text,json_object)
KEY="${CH_KEY:-$OPENAI_API_KEY}"
LOG="${CH_LOG:-.err}" # error log name
MOD="${CH_MOD:-gpt-3.5-turbo}"
PRE="${CH_PRE:-}"   # prelude to include in new chats
RES="${CH_RES:-30}" # response timeout
TEM="${CH_TEM:-1}"  # chat temperature
TIT="${CH_TIT:-}"   # chat title
TOP="${CH_TOP:-1}"  # top_p nucleus sampling

chat_list() {
	for f in "$DIR"/*; do
		printf "%s\n" "$f"
	done
}

chat_new() {
	input_get "$1"
	[ -z "$TIT" ] && title_new
	if [ -r "$PRE" ]; then
		cat "$PRE" >"$DIR/$TIT"
	fi
	msg_new "$INP"
	msg_save "$OUT"
	cur_set "$TIT"
	chat_retry
	[ "$AUT" = "1" ] && [ -n "$CUR" ] && CH_CUR="$CUR" "$0" g &
}

chat_puts() {
	cur_get
	while IFS= read -r line; do
		msg_puts "$line"
	done <"$DIR/$TIT"
}

chat_reply() {
	cur_get
	input_get "$1"
	msg_new "$INP"
	msg_save "$OUT"
	chat_retry
}

chat_retry() {
	cur_get
	msg=$(while read -r line; do
		printf "%s\n" "$s$line"
		s=,
	done <"$DIR/$TIT")
	chat_send "$msg" || exit 1
	msg_puts "$OUT"
	msg_save "$OUT"
}

chat_send() {
	res=$(curl -s 'https://api.openai.com/v1/chat/completions' \
		-m "$RES" --connect-timeout "$CON" \
		-w '%{http_code}' \
		-H "Content-Type: application/json" \
		-H "Authorization: Bearer $KEY" \
		-d '{"model": "'"$MOD"'",
             "messages":['"$1"'],
             "temperature":'"$TEM"',
             "response_format": {"type":"'"$FRM"'"},
             "top_p":'"$TOP"'}')
	exi=$?
	if [ "$exi" -eq 28 ]; then
		err_log "request timeout, try again with 'ch a' or increase the timeout"
	elif [ "$exi" -ne 0 ]; then
		err_log "request failed, curl exited with code: '$exi'"
	else
		code=$(printf "%s\n" "$res" | tail -n 1)
		body=$(printf "%s\n" "$res" | sed '$d')
		if [ "$code" -eq 200 ]; then
			OUT=$(printf "%s\n" "$body" | jq -c '.choices | .[] | .message')
			return 0
		fi
		err=$(printf "%s\n" "$body" | jq -r '.error | to_entries | map("\(.key):\(.value)") | join(", ")')
		err_log "openai code:$code, $err"
	fi
	return 1
}

cur_get() {
	[ -z "$CUR" ] && err_exit "Current filename not set"
	[ -e "$DIR/$CUR" ] || err_exit "Current filename '$DIR/$CUR' not found"
	if ! OUT=$(tail -n 1 "$DIR/$CUR"); then
		err_exit "Error reading chat from current filename"
	fi
	[ -e "$DIR/$OUT" ] || err_exit "Chat filename '$DIR/$OUT' not found"
	TIT="${OUT##*/}"
}

cur_set() {
	input_get "$1"
	[ -z "$CUR" ] && return 0
	[ -e "$DIR/$1" ] || err_exit "Target current filename not found"
	echo "$INP" >>"$DIR/$CUR"
}

dep_check() {
	command -v "$1" >/dev/null && return 0
	printf "Didn't find the utility '%s' on this system\n" "$1"
	exit 1
}

err_log() {
	[ -z "$LOG" ] && return 0
	printf "%s\t%s\n" "$TIT" "$1" | tee -a "$DIR/$LOG" | cut -f 2 >&2
}

err_exit() {
	printf "%s\n" "$1" >&2
	exit 1
}

escape_set() {
	[ "$ANS" != "1" ] && return 0
	BOL=$(tput bold 2>/dev/null)
	NOM=$(tput sgr0 2>/dev/null)
}

help() {
	printf 'ch [Option]

Options
  a|again            in case of error, send current chat again
  c|current <title>  switch the current chat to a differerent title
  g|gen              generate title for current chat
  h|help             print this help
  p|print            print out the current chat
  l|list             list all chat titles
  n|new <prompt>     start a new chat
  r|reply <reply>    reply to the current chat
  t|title            print the current chat title

  Arguments in <angle brackets> are read from STDIN if not present.
'
}

input_get() {
	if [ -n "$1" ]; then
		INP="$1"
	elif ! [ -t 0 ]; then
		while read -r line; do
			INP="$INP$sep$line"
			sep="\n"
		done
	fi
	[ -z "$INP" ] && err_exit "didn't find any input"
}

msg_new() {
	con=$(printf "%s\n" "$1" | sed 's/"/\\\"/g')
	OUT='{"role":"user","content":"'"$con"'"}'
}

msg_puts() {
	cont=$(printf "%s\n" "$1" | jq -r .content)
	role=$(printf "%s\n" "$1" | jq -r .role)
	if [ "$role" = "assistant" ]; then
		cont="$BOL$cont$NOM"
	fi
	echo "$cont"
}

msg_save() {
	[ -z "$TIT" ] && err_exit "No title set"
	printf "%s\n" "$1" >>"$DIR/$TIT"
}

title_gen() {
	cur_get
	msg=$(head -n 1 "$DIR/$TIT" | jq -r .content)
	msg_new "Create a title to be used as a linux filename for this text: $msg"
	chat_send "$OUT" 2>/dev/null || exit 1
	title=$(printf "%s\n" "$OUT" | jq -r .content)
	mv "$DIR/$TIT" "$DIR/$title"
	cur_set "$title"
}

title_new() {
	TIT="$(date '+%Y%m%d%H%M%S').$$"
}

title_puts() {
	cur_get
	printf "%s\n" "${OUT##*/}"
}

bootstrap() {
	dep_check "jq"
	dep_check "curl"
	[ -z "$KEY" ] && err_exit "No api key found (did you set OPENAI_API_KEY?)"
	if [ -t 1 ]; then # if tty default to ANSI escape and autogen title
		if [ -z "$ANS" ]; then
			ANS=1
		fi
		if [ -z "$AUT" ]; then
			AUT=1
		fi
	fi
	escape_set
	trap 'printf "$NOM"' EXIT
	mkdir -p "$DIR" || err_exit "Failed to create dir: '$DIR'"
}

main() {
	[ "$#" -eq 0 ] && help && exit 0
	bootstrap
	a="$1"
	shift
	case "$a" in
	"a" | "again") chat_retry ;;      # in case of error, send current chat again
	"c" | "current") cur_set "$1" ;;  # set current chat to a file in $DIR
	"g" | "gen") title_gen ;;         # generate title for current chat
	"h" | "help") help ;;             # print help
	"p" | "print") chat_puts ;;       # print out the current chat
	"l" | "list") chat_list ;;        # list all chats in $DIR
	"n" | "new") chat_new "$*" ;;     # start a new chat
	"r" | "reply") chat_reply "$*" ;; # add another message to the current chat
	"t" | "title") title_puts ;;      # print the current chat's title
	*) help ;;
	esac
}

[ "${0##*/}" = "ch" ] && main "$@"
true
