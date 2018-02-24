# Kotes.sh

Kotes.sh is bash port of simple notes keeping aplication. If you want to use it you should backup your notes, cause it can be buggy.

### Usage

#### $ ./kotes.sh -t note -f notes
will open file containing all notes with #note in file notes.

### $ ./kotes.sh -t note 
will do the same for default note file (~/allnotes.txt)

If you would like to use default file create it in your home dir.

### Installing

For TAB tag autocomplition and usege like:
#### $ kotes -t note 

You can:

link files:

#### $ link kotes.sh /usr/bin/kotes
#### $ link kotes_ac.sh /etc/bash_completion.d/kotes

or just copy them.

## Acknowledgments

Idea for script comes from:
[Botes app](https://github.com/FRex/botes)
