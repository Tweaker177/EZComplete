# EZComplete
A working GPT 3 client for use on any command line interface on jailbroken iOS devices.  (Scope is small, I know, going to add OSX soon, and work on an application 
to give it a proper UI.  What makes this different from every other CLI or GPT client out there?  Well, first, I've had a working version of this before it 
was a trend to make CLI versions.  It's my curse, if I have a neat idea other people make it popular.  I was talking about chaining LLM's long before plugins were
announced, but no access to GPT 4 or plugins, so I'm just gonna make do (pun intended).  

Makefile and a couple other files need configured to make a rootless build. I have one build for Rootless, but it's an older version.  This version is super verbose,
because after adding a lot of customization options, it stopped working, and I was debugging for about a week, and just kept some of the debugging NSLog statements
for future debugging... Oh yeah, this is written entirely in Objective C, no python, no node.js, that would be too easy, they have libraries with convenience functions.

Actually it's my goal to eventually have every possible use case within reason built in, and the majority of the framework translated into Objective C, so code can be
condensed and as simple looking as python bots.  I'm not sure if it's required, but wouldn't be a bad idea to install python on your device, version 3.5 or higher.
Also, you'll need an OpenAI API key.  I've used almost all of my free tokens testing.  

Any issues, feel free to Pull Request or create an issue..  This is a preliminary 
beta that lets you pick a model before each prompt, as well as set temperature/ creativeness, frequency penality, and more, so each prompt can be to the config of your
choosing amongst the original completion models.   I'm going to add the edits, and chat syntax very soon to make 3.5 turbo and 4 available choices.  (They aren't
compatible with the original completions format, at least according to the docs.)
