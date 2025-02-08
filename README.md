ChatGPT Shell Script
---
`ch` is a POSIX-compliant shell script/library:
- Access LLMs like ChatGPT from your terminal, no more context switching to browser tabs.
- Integrate ChatGPT requests with standard shell tools like pipes, redirects and grep.
- Source `ch` in your own shell scripts to use it as a library. See `tests/run.sh` for an example.

### System Requirements
1. An operating system with a POSIX-compatible shell. Tested on: Linux, MacOS, BSD, Android (via Termux).
2. A valid LLM API key. Create one at OpenAI, Perplexity ...
3. The utilities curl and jq to be installed.

### Usage
    ch [Option]
    
    Options
      a|again            in case of error, send current chat again
      c|current <ID>     switch the current chat to a differerent ID
      h|help             print this help
      i|id               print the current chat ID
      p|print            print out the current chat
      l|list             list all chat IDs
      n|new <prompt>     start a new chat
      r|reply <reply>    reply to the current chat
      s|source           print out the current chat raw json source
    
      Arguments in <angle brackets> are read from STDIN if not present.

### Example
    $ ./ch n is it possible to '"delete"' lines of output in a terminal, or simulate it using ANSI escape sequences?
    Yes, it is possible to "delete" lines of output in a terminal or simulate it using ANSI escape sequences.
    
    Here's an example of how you can simulate deleting lines in a terminal using ANSI escape sequences in Python:
    ...
    $ ./ch r show me how to do it with bash shell code
    ...

All chats are stored in their own JSON line file under CH_TMP. The basename of each file is its unique chat ID. The `list` command lists all these files:

    $ ./ch l
    /tmp/chgpt/20250122204649.307857
    /tmp/chgpt/20250205094326.769195
    /tmp/chgpt/20250207145459.836016
    /tmp/chgpt/20250208105540.843291

Because chats are files, they can be read, grepped, piped and generally manipulated with standard shell tools. 

The file `$CH_TMP/.cur` is a history of all chat IDs, one per line. When a chat is created, its ID is appended to .cur. The last ID in .cur is the current chat. It can be changed with the `current` command:

    $ ./ch c 20250122204649.307857

But chat IDs are kind of opaque, so I often grep chats to find the one I want to switch back to:

    $ grep -li 'prolog variable' $(./ch l) | xargs basename | ./ch c
    $ ch p
    Is prolog variable unification scoped by disjunctive branches within the same goal?
    In Prolog, variable unification is indeed scoped by disjunctive branches within the same goal.
    ...

### Environment Variables
Manipulate these to tune the behavior of `ch`. Default values are shown (in parens).

    CH_ANS  # bold replies? (yes for tty)
    CH_CON  # connect timeout (5 secs)
    CH_CUR  # filepointer to the current conversation (CH_DIR/.cur)
    CH_DIR  # save chats here ($TMPDIR/chgpt)
    CH_FRM  # response format (text)
    CH_KEY  # openai key (OPENAI_API_KEY)
    CH_LOG  # error log name (CH_DIR/.err)
    CH_MOD  # model name (gpt-3.5-turbo)
    CH_PRE  # filename containing preamble to include in new chats
    CH_RES  # response timeout (30 secs)
    CH_TEM  # chat temperature (1)
    CH_TIT  # chat ID
    CH_TOP  # top_p nucleus sampling (1)
    CH_URL  # openai API URL (https://api.openai.com/v1/chat/completions)

### Perplexity LLMs
`ch` works with any compatible chat completion API that has the same interface as ChatGPT. All you have to do is
override the appropriate environment variables. I created a shell script called `ppx` which wraps `ch` with
the values to call a Perplexity online LLM instead of ChatGPT:

    #!/bin/sh
    export CH_DIR="/tmp/ppxty"                                 # save to alt dir
    export CH_KEY="$PPLXTY_API_KEY"                            # ppx API key
    export CH_MOD="sonar-small-online"                         # ppx model name
    export CH_URL="https://api.perplexity.ai/chat/completions" # ppx API URL
    ch "$@"

### MIT License

Copyright (c) 2023 David Farrell

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
SOFTWARE.
