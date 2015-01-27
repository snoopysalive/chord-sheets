# Chord Sheet Creator

The Chord Sheet Creator is a quick-and-dirty Ruby-tool generating simple chord sheets
(as PDF) for musicians.

I've written this tool for creating lead sheets for the members of my band in a digital 
way as my handwritten ones are kind of unreadable and (which is true for every handwritten 
document) hard to maintain when changes occur.

It's a tool for my own private usage but I've decided to share it with you. Maybe
there are some fellows outside facing the same problem who don't want to dive into learning
highly-sofisticated tools like LiliPond which seem way too large for my purposes.

## Beta Status

This script is in beta status. It was written under Mac OS X using Ruby 2.1.2 and I haven't 
tested it on neither Linux nor Windows. 

It's just a quick-and-dirty solution for my primary goals. There's poor OO and no error handling. Of course, I'll try to improve these lacks.

## Prerequiries

Install the following gems:

    $ gem install pdfkit
    $ gem install wkhtmltopdf-binary

## Usage

1. Create a YAML-file
2. Compile it to PDF via `$ ruby cs-creator.rb input-file.yml > output-file.pdf`
3. You're done!

## Syntax

Check out the example file **example/example.yaml**. The file consists of three main keys: `title`, `config` and `song`.

* `title` just has a string as value. It's the name of the song
* `config` consists of three sub-keys:
  * `line_length`: int-value setting the count of bars per line
  * `bar_width`: int-value setting the width of each bar in px
  * `time_signature`: a string of the form `<int>/<int>` (e.g. "3/4") defining the song's time signature
* `song` consists of a variable amount of sub-keys containing the chord information
  * Every primary sub-key is a string defining the name of a part of the song
  * Secondary sub-keys are the names of the chords to be played and have to be written in array-syntax (e.g. `- 'E': 2`). There value is an integer defining the amount of bars to be related to the chord name
  * Secondary sub-keys can be arrays, too. These sub-arrays then have to contain the chord information and every sub-array causes a "line break"
  * The secondary sub-key `':'` defines a repetition. If it's integer-value is different from `1` that number is displayed on top of the repetition-sign specifing how often this part of the song is to be repeated

## Have fun!

At least I hope you'll have. ;-)