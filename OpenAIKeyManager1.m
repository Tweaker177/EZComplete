#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
#import "OpenAIKeyManager.h"




static NSString *OPENAI_API_KEY;


@implementation OpenAIKeyManager


+(instancetype)init {
    if(self) {
        self = [super init];
    }
    return self;
}
//Main getter function, logic and order to try to find the Key
//Or if all else fails prompt the user for a key.
+ (NSString *)getOpenAI_API_Key {
    OPENAI_API_KEY = [self readKeyFromDefaults];
    
    if (!OPENAI_API_KEY) {
        OPENAI_API_KEY = [self readKeyFromEnvironment];
        if (!OPENAI_API_KEY) {
            OPENAI_API_KEY = [self promptUserForKey];
        Prefs_setStringForKey:(OPENAI_API_KEY, @"OPENAI_API_KEY");
        }
    }
    return key;
}
    // Code to read key from user defaults
+(NSString *)readKeyFromDefaults {
    if(!OPENAI_API_KEY) {
        OPENAI_API_KEY = Prefs_getString:(@"OPENAI_API_KEY");
    }
    
    if(OPENAI_API_KEY != nil) {
        NSLog(@"\nSuccess! Got OPENAI_API_KEY from defaults.");
        NSLog(@"\nValue for OPENAI_API_KEY = %@", OPENAI_API_KEY);
    }
   return OPENAI_API_KEY;
}


+(NSString *)promptUserForKey {
    // Code to prompt user for key goes here
    NSLog(@"Thanks for installing EZComplete.\nTo connect to OpenAI enter your API key: ");
    //Users should only have to enter their API Key the first time using program, then it will be stored in user defaults.
    char input[75];
    scanf("%s", &input);
    if(input[1] != nil) {
        OPENAI_API_KEY  = [NSString stringWithUTF8String:input];
        if(OPENAI_API_KEY != nil) {
           Prefs_setStringForKey:(OPENAI_API_KEY, @"OPENAI_API_KEY");
        }
        
        return OPENAI_API_KEY;
    }
    OPENAI_API_KEY = [input stringWithUTF8String:input];
    return OPENAI_API_KEY;
}

+ (NSString *)readKeyFromEnvironment {
        NSString *key = [[[NSProcessInfo processInfo] environment] objectForKey:@"OPENAI_API_KEY"];
        if (!key) {
            NSTask *task = [[NSTask alloc] init];
            [task setLaunchPath:@"/bin/bash"];
            [task setArguments:@[@"-l", @"-c", @"echo $OPENAI_API_KEY"]];

            NSPipe *pipe = [NSPipe pipe];
            [task setStandardOutput:pipe];

            [task launch];

            NSData *data = [[pipe fileHandleForReading] readDataToEndOfFile];
            NSString *output = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];

            key = [output stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
        }
        return key;
    }

/****
 
    +(void)saveKeyToDefaults:(NSString *)OPENAI_API_KEY {
            // Code to save key to a file goes here
        if(OPENAI_API_KEY != nil) {
            NSUserDefaults *validate = [NSUserDefaults standardUserDefaults];
             BOOL alreadySet = @"alreadySet";
            if([validate boolForKey:alreadySetOpenAIKey]) return;
            [validate setObject:OPENAI_API_KEY forKey:@"OPENAI_API_KEY"];
            NSLog(@"\nSaved to defaults: OPENAI_API_KEY = %@ ", OPENAI_API_KEY);
            [validate setBool:YES forKey:alreadySetOpenAIKey];
            NSLog(@"\nThis should be the only time you see this message.");
            return;
        }
        else {
            NSLog(@"Error: the OPENAI_API_KEY has a nil value. No point saving it.");
        }
        return;
    }


***/
@end



