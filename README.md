# EZComplete
A working, highly customizable GPT-3 client for use on any command line interface on jailbroken iOS devices.  (Scope is small, I know, going to add OSX soon, and work on an application 
to give it a proper UI.) 

Makefile and a couple other files need configured to make a rootless build. This version is extra verbose,
since I used NSLog statements
for debugging and kept some of the extras for now. Oh yeah, this is written entirely in Objective C, no python, no node.js, that would be too easy, they have libraries with convenience functions.


You'll need an OpenAI API key for the requests to be processed.  If you dont have one you can get one at https://beta.openai.com

Any issues, or suggestions for improvements feel free to open a Pull Request or create an issue..  

This is a preliminary beta that lets you pick a model before each prompt, as well as set temperature/ creativeness, frequency penality, and more, so each prompt can be to the config of your
choosing amongst the original completion models.   I'm going to add the edits, and chat formats very soon to make 3.5 turbo and 4 available choices.  (They aren't
compatible with the original completions format, at least according to the docs.)
