Saga Toolkit
------------

SagaTK is a set of tools for hobbyist audio plays production, combined into a user interface made with Godot Engine.
This is very experimental and tailored for my own use so far, and might be useful to other hobbyists having the same workflow as me.

I started to write this tool because I often write stuff on my smartphone, in raw text, because I like bare simplicity (and I don't like apps saving in formats only them can read), but I wanted to provide a better look and feel to people I share my files with. I implement other stuff in it if I need them or just for fun.

Features
----------

- Interface grouping together various tasks of production of a series
- Script editor using a custom kind of Markdown, with scenes index and characters highlighting
- Characters list automatically deduced from the script
- Visualization of all occurrences of a character within each episode
- Focus on minimalism: all data is stored in readable text files, and the script written identical without the app.
- Script is convertible to HTML for actors, with some extras (standard formatting, numbered lines, interactive characters highlighting)
- Actor management: which character they play, which lines they have to do, which episode did they record so far
- Estimated episode duration
- Tools for french users with QWERTY keyboards to type or recover accents
- Dark theme
- Should work on all desktop platforms (Windows, Linux, Mac OSX)
- And likely more features, as I add them when I need

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


Where do I get the app?
-------------------------

There is no official release yet. I am using it on a daily basis for an ongoing project, but it is still in development, as I consider it needs usability improvements. However, you can test it quite simply if you want to:

- Download this repository using the green button on the top left
- Download latest Godot Engine for your OS: https://downloads.tuxfamily.org/godotengine/3.2/beta2/
- Place Godot next to the app folder (not inside!)
- Run Godot: in the project manager, import the project by locating the `project.godot` file inside the project
- Open the project: a progress bar may show up the first time, and the Godot Editor will show up
- Finally, run the app by pressing the Play button on the top left.

If you find any problem, please report it in the issue tracker.
