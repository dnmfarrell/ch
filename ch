#!/bin/sh
CH_ANS="${CH_ANS:-}"                      # bold replies? (default for tty)
CH_CON="${CH_CON:-5}"                     # connect timeout
CH_CUR="${CH_CUR:-.cur}"                  # symlink to current chat file
CH_DIR="${CH_DIR:-${TMPDIR:-/tmp}/chgpt}" # save chats here
CH_KEY="${CH_KEY:-$OPENAI_API_KEY}"
CH_LOG="${CH_LOG:-.err}" # error log name
CH_MAX="${CH_MAX:-}"     # max tokens
CH_MOD="${CH_MOD:-gpt-4o}"
CH_RES="${CH_RES:-30}" # response timeout
CH_RJQ="${CH_RJQ:-.choices | .[] | .message}"
CH_ROB="${CH_ROB:-{\}}"  # optional json request obj
CH_ROL="${CH_ROL:-user}" # role name to use
CH_TEM="${CH_TEM:-}"     # chat temperature
CH_TIT="${CH_TIT:-}"     # chat ID
CH_TOP="${CH_TOP:-}"     # top_p nucleus sampling
CH_URL="${CH_URL:-https://api.openai.com/v1/chat/completions}"
CH_HEA="${CH_HEA:-Authorization: Bearer $CH_KEY}" # http auth header
CH_HES="${CH_HES:-}"                              # optional http headers

[ -n "$CH_VER" ] && set -x

ch_list() {
	for ch_f in "$CH_DIR"/*; do
		printf "%s\n" "$ch_f"
	done
}

ch_new() {
	ch_input_get "$1"
	[ -z "$CH_TIT" ] && ch_id_new
	ch_msg_new "$CH_INP"
	ch_msg_save "$CH_OUT"
	ch_cur_set "$CH_TIT"
	ch_retry
}

ch_puts() {
	ch_cur_get
	while IFS= read -r ch_line; do
		ch_msg_puts "$ch_line"
	done <"$CH_DIR/$CH_TIT"
}

ch_reply() {
	ch_cur_get
	ch_input_get "$1"
	ch_msg_new "$CH_INP"
	ch_msg_save "$CH_OUT"
	ch_retry
}

ch_retry() {
	ch_cur_get
	ch_msg=$(while read -r ch_line; do
		printf "%s\n" "$ch_s$ch_line"
		ch_s=,
	done <"$CH_DIR/$CH_TIT")
	ch_send "$ch_msg" || exit 1
	ch_msg_puts "$CH_OUT"
	ch_msg_save "$CH_OUT"
}

ch_send() {
	ch_params='"model":"'"$CH_MOD"'","messages":['"$1"']'
	[ -n "$CH_MAX" ] && ch_params="$ch_params",'"max_tokens":'"$CH_MAX"
	[ -n "$CH_TEM" ] && ch_params="$ch_params",'"temperature":'"$CH_TEM"
	[ -n "$CH_TOP" ] && ch_params="$ch_params",'"top_p":'"$CH_TOP"
	ch_req_json=$(printf "{%s} %s" "$ch_params" "$CH_ROB" | jq -cs '.[0]+.[1]')

	ch_headers="Content-Type: application/json\n$CH_HEA\n"
	[ -n "$CH_HES" ] && ch_headers="$ch_headers$CH_HES\n"

	ch_res=$(printf "%b" "$ch_headers" | curl -s "$CH_URL" \
		-H '@-' \
		-m "$CH_RES" --connect-timeout "$CH_CON" \
		-w '\n%{http_code}' \
		-d "$ch_req_json")
	ch_exi=$?
	if [ "$ch_exi" -eq 28 ]; then
		ch_err_log "request timeout, try again with 'ch a' or increase the timeout"
	elif [ "$ch_exi" -ne 0 ]; then
		ch_err_log "request failed, curl exited with code: '$ch_exi'"
	else
		ch_code=$(printf "%s\n" "$ch_res" | tail -n 1)
		ch_body=$(printf "%s\n" "$ch_res" | sed '$d')
		if [ "$ch_code" -eq 200 ]; then
			CH_OUT=$(printf "%s\n" "$ch_body" | jq -c "$CH_RJQ")
			return 0
		fi
		ch_err=$(printf "%s\n" "$ch_body" | jq -r '.error | to_entries | map("\(.key):\(.value)") | join(", ")')
		ch_err_log "openai code:$ch_code, $ch_err"
	fi
	return 1
}

ch_cur_get() {
	[ -z "$CH_CUR" ] && ch_err_exit "Current filename not set"
	[ -e "$CH_DIR/$CH_CUR" ] || ch_err_exit "Current filename '$CH_DIR/$CH_CUR' not found"
	if ! CH_OUT=$(tail -n 1 "$CH_DIR/$CH_CUR"); then
		ch_err_exit "Error reading chat from current filename"
	fi
	[ -e "$CH_DIR/$CH_OUT" ] || ch_err_exit "Chat filename '$CH_DIR/$CH_OUT' not found"
	CH_TIT="${CH_OUT##*/}"
}

ch_cur_set() {
	ch_input_get "$1"
	CH_INP=$(basename "$CH_INP")
	[ -e "$CH_DIR/$CH_INP" ] || ch_err_exit "Target current filename not found"
	[ -z "$CH_CUR" ] && return 0
	printf "%s\n" "$CH_INP" >>"$CH_DIR/$CH_CUR"
}

ch_dep_check() {
	command -v "$1" >/dev/null && return 0
	printf "Didn't find the utility '%s' on this system\n" "$1"
	exit 1
}

ch_err_log() {
	[ -z "$CH_LOG" ] && return 0
	printf "%s\t%s\n" "$CH_TIT" "$1" | tee -a "$CH_DIR/$CH_LOG" | cut -f 2 >&2
}

ch_err_exit() {
	printf "%s\n" "$1" >&2
	exit 1
}

ch_escape_set() {
	[ "$CH_ANS" != "1" ] && return 0
	CH_BOL=$(tput bold 2>/dev/null)
	CH_NOM=$(tput sgr0 2>/dev/null)
}

ch_help() {
	printf 'ch [Option]

Options
  a|again            in case of error, send current chat again
  c|current <ID>  	 switch the current chat to a differerent ID
  h|help             print this help
  p|print            print out the current chat
  i|id            	 print the current chat ID
  l|list             list all chat IDs
  n|new <prompt>     start a new chat
  r|reply <reply>    reply to the current chat
	s|source           print out the current chat raw json source

  Arguments in <angle brackets> are read from STDIN if not present.
'
}

ch_input_get() {
	if [ -n "$1" ]; then
		CH_INP="$1"
	elif ! [ -t 0 ]; then
		while read -r ch_line; do
			CH_INP="$CH_INP$ch_sep$ch_line"
			ch_sep="\n"
		done
	fi
	[ -z "$CH_INP" ] && ch_err_exit "didn't find any input"
}

ch_msg_new() {
	ch_con=$(printf "%s\n" "$1" | sed 's/"/\\\"/g')
	CH_OUT='{"role":"'"$CH_ROL"'","content":"'"$ch_con"'"}'
}

ch_msg_puts() {
	ch_cont=$(printf "%s\n" "$1" | jq -r .content)
	ch_role=$(printf "%s\n" "$1" | jq -r .role)
	if [ "$ch_role" = "assistant" ]; then
		ch_cont="$CH_BOL$ch_cont$CH_NOM"
	fi
	printf "%s\n" "$ch_cont"
}

ch_msg_save() {
	[ -z "$CH_TIT" ] && ch_err_exit "No ID set"
	printf "%s\n" "$1" >>"$CH_DIR/$CH_TIT"
}

ch_source() {
	ch_cur_get
	cat "$CH_DIR/$CH_TIT"
}

ch_id_new() {
	CH_TIT="$(date '+%Y%m%d%H%M%S').$$"
}

ch_id_puts() {
	ch_cur_get
	printf "%s\n" "${CH_OUT##*/}"
}

ch_bootstrap() {
	ch_dep_check "jq"
	ch_dep_check "curl"
	[ -z "$CH_KEY" ] && ch_err_exit "No api key found (set CH_KEY or OPENAI_API_KEY)"
	if [ -t 1 ]; then # if tty default to ANSI escape
		if [ -z "$CH_ANS" ]; then
			CH_ANS=1
		fi
	fi
	ch_escape_set
	trap 'printf "$CH_NOM"' INT TERM EXIT
	mkdir -p "$CH_DIR" || ch_err_exit "Failed to create dir: '$CH_DIR'"
}

ch_main() {
	[ "$#" -eq 0 ] && ch_help && exit 0
	ch_bootstrap
	ch_a="$1"
	shift
	case "$ch_a" in
	"a" | "again") ch_retry ;;          # in case of error, send current chat again
	"c" | "current") ch_cur_set "$1" ;; # set current chat to a file in $CH_DIR
	"h" | "help") ch_help ;;            # print help
	"i" | "id") ch_id_puts ;;           # print the current chat's ID
	"p" | "print") ch_puts ;;           # print out the current chat
	"l" | "list") ch_list ;;            # list all chats in $CH_DIR
	"n" | "new") ch_new "$*" ;;         # start a new chat
	"r" | "reply") ch_reply "$*" ;;     # add another message to the current chat
	"s" | "source") ch_source ;;        # print out the source file
	*) ch_help ;;
	esac
}

[ "${0##*/}" = "ch" ] && ch_main "$@"
true
