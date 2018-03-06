OCRemix Downloader
==================

Downloads a range of OCRemixes off the ocremix.org site and remembers the last one downloaded

Requirements
---
Ruby 1.8+<br />
Peach

Installation
---
Run `bundle install` in the project's root directory to retrieve the dependencies

Usage
-----

Usage: ocremix.org [options] [destination]
(If no destination is set, download into the current working directory)

    -f, --from [START]               Start song to download
    -t, --to END                     Last song to download
    -v, --[no-]verbose               Output debug info
    -p, --processes [COUNT]          Amount of concurrent processes to use
    -n                               Prepend OCR number to filename
    -h, --help                       Prints help

Examples:

`ocremix.rb -vnp 2 -f 00100 -t 02000`	 Will download OCR00100 to OCR02000 providing verbose info using 2 concurrent processes and prepend OCR numbers to filenames.