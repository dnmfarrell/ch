ChatGPT Shell Script
---
Take your productivity to the next level with `ch`, the POSIX-compliant shell script/library:
- Access ChatGPT from your terminal, no more context switching to browser tabs.
- Save money: the typical monthly cost of ChatGPT API is much lower than the fixed fee for web access.¹
- Program ChatGPT with standard shell tools like pipes, redirects and grep. No more copy and paste!

### System Requirements
- An operating system with a POSIX-compatible shell. Tested on: Linux, MacOS, BSD, Android (via Termux).
- A valid OpenAI ChatGPT API key. Create one at OpenAI.
- The curl and jq utilities to be installed.
- An Internet connection.

### Usage
    ch [Option]
    
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

### Example
    $ ./ch n is it possible to '"delete"' lines of output in a terminal, or simulate it using ANSI escape sequences?
    Yes, it is possible to "delete" lines of output in a terminal or simulate it using ANSI escape sequences.
    
    Here's an example of how you can simulate deleting lines in a terminal using ANSI escape sequences in Python:
    ...

I also recorded a [video](https://www.youtube.com/watch?v=9aYUvLeM0yo) with more background on the rationale for
`ch` and example uses.

### Library
You can also "source" `ch` in your own shell scripts to use it as an API library. See `tests/run.sh` for an example.

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


¹ Depends on usage, in my case I went from spending $20 to less than $2 per month.
