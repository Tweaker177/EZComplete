#import "OpenAIKeyManager.h"
//#import "NSTask.h"
#import <Foundation/Foundation.h>
#import <objc/runtime.h>
#import "NSTask.h"

@implementation OpenAIKeyManager

- (NSString *)getOpenAI_API_Key {
    NSString *key = [self readKeyFromDefaults];
    if (!key) {
        key = [self readKeyFromEnvironment];
        if (!key) {
            key = [self promptUserForKey];
        }
    }
    if((key!=nil && ![key isEqualToString:@""]) && ([key containsString:@"sk"]))
    {
    Prefs_setStringForKey(key, @"OPENAI_API_KEY");  //sets the fetched or user supplied key to user defaults for easy retrieval in future useage
    }
    
    return key;
}

- (NSString *)readKeyFromDefaults {
    NSString *theKeyFromDefaults = Prefs_getString(@"OPENAI_API_KEY");
    if(theKeyFromDefaults.length >0 && [theKeyFromDefaults containsString:@"sk"]) {
        NSLog(@"\nGot your key from defaults.  It is: %@\n", theKeyFromDefaults);
        
    }
    return theKeyFromDefaults;
   
}

- (NSString *)promptUserForKey {
        NSString *theKey = nil;
           
        NSLog(@"Thanks for installing EZComplete.\nTo connect to OpenAI We need a valid API Key.\n");
        NSLog(@"ALternately, and more securely, you can simply set up your key\n as an environment variable and try again.\n\n");
        NSLog(@"We never access your key directly, and it only leaves your device to communicate directly with the API endpoint.\n");
            //Users should only have to enter their API Key the first time using program, then it will be stored in user defaults.
            //If they have stored it as reccomnmended they won't ever need to enter it
        char userInput[75];
        
        NSLog(@"Please set up your environment variable to include the API key, or\n Enter your key now: ");
        scanf("%s", userInput);
          NSString *tmpString = [[NSString stringWithUTF8String:userInput] copy];
    if ((userInput[1] != '\0') && [tmpString containsString:@"sk"]) {
        theKey = tmpString;
        //[[NSString stringWithUTF8String:userInput] copy];
            NSLog(@"\nSuccess! Thanks for setting up your key.\n We never access it directly; it gets stored to your local environment.\n\n");
            Prefs_setObjectForKey(theKey,@"OPENAI_API_KEY");
            return theKey;
        }
        NSString *APIURL = @"https://beta.openai.com";
    if(((theKey.length<12) || !Prefs_getString(@"OPENAI_API_KEY")) || ![Prefs_getString(@"OPENAI_API_KEY") containsString:@"sk"]) {
            theKey = nil;
            NSLog(@"Error fetching key. Please enter valid API key from %@", APIURL);
            NSLog(@"\nALternately, and more securely, you can simply set up your key\n as an environment variable and try again.\n\n");
            NSLog(@"\nThis program keeps your key stored locally and never passes it anywhere besides directly to the API endpoint.\n");
        }
            
        if ((theKey != nil) && (Prefs_getString(@"OPENAI_API_KEY") != nil) && (theKey.length > 12)) {
            NSLog(@"Success! Got the key= %@\n You wqn't need to enter it again..hopefully\nunless you get a new one and don't update your environment variable.\n\n", theKey);
            return theKey;
            
        }
        else {
            NSLog(@"Try again to enter your API key:\n)");
            char userInput[75];
            scanf("%s", userInput);
            if(userInput[1] != '\0')  {
                NSLog(@"Success! Got your API key from user input.\nNow I can use my own bot all day and night forever! (jk - I swear. :)\n");
                theKey  = [NSString stringWithUTF8String:userInput];
                Prefs_setStringForKey(theKey,@"OPENAI_API_KEY");
                return theKey;
            }
            
            return theKey; //it shoud be already returned but i don't feel like mentally compiling at the moment lol
        } //end of else enter key again
    }
    
- (NSString *)readKeyFromEnvironment {
    NSString *key = [[[NSProcessInfo processInfo] environment] objectForKey:@"OPENAI_API_KEY"];
       if (!key || ![key containsString:@"sk"]) {
        NSTask *task = [[NSTask alloc] init];
        [task setLaunchPath:@"/usr/bin/bash"];
        [task setArguments:@[@"-l", @"-c", @"echo $OPENAI_API_KEY"]];
        
        NSPipe *pipe = [NSPipe pipe];
        [task setStandardOutput:pipe];
        
        [task launch];
        
        NSData *data = [[pipe fileHandleForReading] readDataToEndOfFile];
        NSString *output = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
        
        key = [output stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
        if((key.length >9) && [key containsString:@"sk"]) {
            NSLog(@"\nGot your API KEY from environment-it IS: %@", key);
            Prefs_setStringForKey(key, @"OPENAI_API_KEY");
            return key;
        }
        else {
            key = [self promptUserForKey];
            return key;
        }
        
      }
    return key;
    }

@end
