OCRemix Downloader
==================

Downloads a range of OCRemixes off the ocremix.org site and remembers the last one downloaded

Usage
-----

ocremix.rb [-f firstsong] [-t endsong] [-n] [-v] [-p NUMBER]

Examples:
  ocremix.rb -v -n -p 2 -f 00100 -t 02000	 Will download OCR00100 to OCR02000 providing verbose info using 2 concurrent processes and prepend OCR numbers to filenames.