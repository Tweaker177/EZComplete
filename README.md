# EZComplete
A working, highly customizable GPT-3 client for use on any command line interface on MacOS, including inside VSCode as a CoPilot alternative, or just a helpful assistant that only bothers you when you ask it for help. It also works on jailbroken iOS devices from iOS 11-17.

I'm currently using the AVFoundation framework for Text to Speech completions, with a default voice, nothing fancy.  I'll soon be using a higher quality API, but for now Apple works, and its free.  I have packages built and installed on various iOS devices and jailbreaks, but the most recent code chamges have been to the Mac/ OSX builds. As there is a decent amount of code that's different on Mac, including the makefile, I'm thinking of adding a separate repo just for the Mac / OSX version. 

I'll be adding all the local updates I've made,
over the past couple months very soon.  
This version is extra verbose,
since I used NSLog statements
for debugging and kept some of the extras for now. Oh yeah, this is written entirely in Objective C++, no python, no node.js, that would be too easy, they have libraries with convenience functions.
Recently added preliminary support for image generation as well. When picking your model you can select "DALLE" and enter image prompts, number of images to generate, etc.  I'm going to add a releases section soon with versions for each supported platform.

You'll need an OpenAI API key for the requests to be processed.  If you dont have one you can get one at https://beta.openai.com

Any issues, or suggestions for improvements feel free to open a Pull Request or create an issue..  


Video of package on ios 15.7.4 palera1n rootless jailbreak.
https://youtu.be/kUXO9v8uJZc


[![i0S_tweak3r's GitHub stats](https://github-readme-stats.vercel.app/api?username=tweaker177)](https://github.com/tweaker177/github-readme-stats)











