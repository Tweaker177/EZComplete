# EZComplete
A working, highly customizable GPT client for use on any command line interface. There are small differences though depending of if building for MacOS or iOS.  This repo was the MacOS then I goofed and updated iOS here. (my bad)  

Models include GPT4, GPT4o Mini, GPT 5, Dalle 3, and GPT 3.5.   It works on rootless jailbroken iOS devices from iOS 15+.

I'm currently using the AVFoundation framework for Text to Speech completions, with a default voice, nothing fancy.  I'll soon be using a higher quality API, but for now Apple works, and its free.  I have packages built and installed on various iOS devices and jailbreaks, but the most recent code chamges have been to the rootless iOS builds. As there is a decent amount of code that's different on Mac, including the makefile, I'm thinking of adding a separate repo just for the Mac / OSX version. 


Oh yeah, this is written entirely in Objective C++, no python, no node.js, that would be too easy, they have libraries with convenience functions.

Recently added support for image generation as well. When picking your model you can select "DALLE 3" and enter image prompts like any other prompt.  Once the image is generated and downloaded it is saved automatically to the Documents folder.

You'll need an OpenAI API key for the requests to be processed.  If you dont have one you can get one at https://beta.openai.com

Any issues, or suggestions for improvements feel free to open a Pull Request or create an issue..  





[![i0S_tweak3r's GitHub stats](https://github-readme-stats.vercel.app/api?username=tweaker177)](https://github.com/tweaker177/github-readme-stats)











