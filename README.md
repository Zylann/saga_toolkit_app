Saga Toolkit
------------

SagaTK is a set of tools for hobbyist audio plays production, combined into a user interface made with Godot Engine.
This is very experimental and tailored for my own use so far, and might be useful to other hobbyists having the same workflow as me.

I started to write this tool because I often write stuff on my smartphone, in raw text (because f*** apps), but I wanted to provide a better look and feel to people I share my files with. I implement other stuff in it if I need them or just for fun.

It supersedes my previous work which was using Python: https://github.com/Zylann/SagaToolkit


Features
----------

### Script parser

The first, mainly developped tool is a script parser.
It parses the script of the audio play and extracts episode titles, scene names, character names and various notes. The application aims to deduce part of the project's data from the scripts themselves, which saves time.

The script has to be written in some specific form of Markdown which is tailored for my use on smartphone. The main specific format is how statements are written:

```
Episode name 
=============

Scene name
------------

/* This is a comment */

(forest ambiance)

CHARACTER 1 -- I am saying something

CHARACTER 2, moving towards character 1 -- I am answering to you

(A bird sings)

CHARACTER 1, surprised -- Hey, look at this bird! I like the sound he makes.

CHARACTER 2 -- I'd like to eat it.

// TODO Write the rest of the play

```

### HTML Exporter

Once the script has been parsed, it can also be exported into a read-only HTML file, which is targeted at actors. This way, we can convert from Markdown to a very readable format which only requires a browser to open, and can also have some fancy Javascript code to highlight the characters they have to play.

