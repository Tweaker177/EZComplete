#import <Foundation/Foundation.h>
#import <AVFoundation/AVFoundation.h>
#import "OpenAIKeyManager.h"

#define MODEL_GPT4O     @"gpt-4o"
#define MODEL_GPT4O_MINI @"gpt-4o-mini"
#define MODEL_GPT5      @"gpt-5"
#define MODEL_DALLE3    @"dall-e-3"
#define MODEL_GPT35     @"gpt-3.5-turbo"

// --- Global State ---
static NSString *model = @"gpt-4o-mini";
static float temperature = 0.7f;
static float frequencyPenalty = 0.0f; // New Feature
static NSString *systemMessage = @"You are a helpful assistant.";
static NSString *kOPENAI_API_KEY = nil;
static AVSpeechSynthesizer *synthesizer = nil;
/**
// --- Helper: Preferences Wrapper ---
static void Prefs_setString(NSString *value, NSString *key) {
    [[NSUserDefaults standardUserDefaults] setObject:value forKey:key];
    [[NSUserDefaults standardUserDefaults] synchronize];
}

static NSString* Prefs_getString(NSString *key) {
    return [[NSUserDefaults standardUserDefaults] stringForKey:key];
}

static void Prefs_setFloat(float value, NSString *key) {
    [[NSUserDefaults standardUserDefaults] setFloat:value forKey:key];
    [[NSUserDefaults standardUserDefaults] synchronize];
}
**/
static float Prefs_getFloat(NSString *key) {
    return [[NSUserDefaults standardUserDefaults] floatForKey:key];
}
 

// ---Helper: Hardened Logging (24-Hour Format) ---
void ezLog(NSString *format, ...) {
    va_list args;
    va_start(args, format);
    NSString *message = [[NSString alloc] initWithFormat:format arguments:args];
    va_end(args);

    // 1. Print to Console
    printf("%s\n", [message UTF8String]);

    // 2. Write to File (Crash-Proof)
    @try {
        NSDateFormatter *df = [[NSDateFormatter alloc] init];
        [df setDateFormat:@"yyyy-MM-dd-HHmm"];
        NSString *logName = [NSString stringWithFormat:@"ez-log-%@.txt", [df stringFromDate:[NSDate date]]];
        
        NSString *docDir = (getuid() == 0) ? @"/var/root/Documents" : @"/var/mobile/Documents";
        NSString *logPath = [docDir stringByAppendingPathComponent:logName];
        
        [[NSFileManager defaultManager] createDirectoryAtPath:docDir withIntermediateDirectories:YES attributes:nil error:nil];
        
        NSString *logEntry = [NSString stringWithFormat:@"[%@] %@\n", [NSDate date], message];
        
        // Use append mode
        NSFileHandle *handle = [NSFileHandle fileHandleForWritingAtPath:logPath];
        if (!handle) {
            [[NSFileManager defaultManager] createFileAtPath:logPath contents:nil attributes:nil];
            handle = [NSFileHandle fileHandleForWritingAtPath:logPath];
        }
        [handle seekToEndOfFile];
        [handle writeData:[logEntry dataUsingEncoding:NSUTF8StringEncoding]];
        [handle closeFile];
        
    } @catch (NSException *e) {
        printf("[Log Fail] %s\n", [e.reason UTF8String]);
    }
}

// --- Helper: Input ---
static NSString* getCleanInput(void) {
    char buffer[4096];
    if (fgets(buffer, sizeof(buffer), stdin) != NULL) {
        return [[NSString stringWithUTF8String:buffer] stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
    }
    return nil;
}

// --- Feature: Clipboard ---
static void safeCopyToClipboard(NSString *text) {
    if (!text || text.length == 0) return;
    @try {
        const char *pbPath = "/var/jb/usr/bin/pbcopy";
     
        if (access(pbPath, F_OK) == 0) {
            FILE *pb = popen(pbPath, "w");
            if (pb) {
                fwrite([text UTF8String], 1, strlen([text UTF8String]), pb);
                pclose(pb);
                ezLog(@"[System] Copied to clipboard.");
            }
        }
    } @catch (NSException *e) { ezLog(@"[Clipboard Error] %@", e.reason); }
}

// --- Feature: Audio (TTS) ---
// Ensure this global is declared at the top of your file
// static AVSpeechSynthesizer *synthesizer = nil;

static void speakText(NSString *text) {
    if (!text || text.length == 0) return;

    @try {
        // 1. Setup Audio Session (Crucial for repeated audio in CLI)
        AVAudioSession *session = [AVAudioSession sharedInstance];
        NSError *err = nil;
        
        // Use 'Playback' to ensure it continues even if screen dims/locks
        // 'MixWithOthers' ensures we don't kill Spotify/Apple Music if playing
        [session setCategory:AVAudioSessionCategoryPlayback
                 withOptions:AVAudioSessionCategoryOptionMixWithOthers
                       error:&err];
                       
        if (err) printf("[Audio Setup Error] %s\n", [[err localizedDescription] UTF8String]);

        // 2. Activate the Session specifically for this utterance
        [session setActive:YES error:&err];

        // 3. Initialize Synthesizer Once (Lazy Load)
        if (!synthesizer) {
            synthesizer = [[AVSpeechSynthesizer alloc] init];
        }

        // 4. Reset: If it's already talking, shut it up so it can say the new thing
        if ([synthesizer isSpeaking]) {
            [synthesizer stopSpeakingAtBoundary:AVSpeechBoundaryImmediate];
        }

        // 5. Create a FRESH Utterance every time (You were right about this)
        AVSpeechUtterance *utterance = [AVSpeechUtterance speechUtteranceWithString:text];
        utterance.rate = 0.55; // Slightly faster than default
        utterance.voice = [AVSpeechSynthesisVoice voiceWithLanguage:@"en-US"]; // Enforce English to prevent weird defaults

        // 6. Speak
        [synthesizer speakUtterance:utterance];

    } @catch (NSException *e) {
        printf("[Audio Exception] %s\n", [e.reason UTF8String]);
    }
}
// --- Feature: Image Saving ---
static void saveImageFromURL(NSString *urlString) {
    ezLog(@"[System] Downloading DALL-E image...");
    @try {
        NSURL *url = [NSURL URLWithString:urlString];
        NSData *data = [NSData dataWithContentsOfURL:url];
        if (data) {
            NSDateFormatter *df = [[NSDateFormatter alloc] init];
            [df setDateFormat:@"yyyyMMdd_HHmmss"];
            NSString *filename = [NSString stringWithFormat:@"DALLE_%@.png", [df stringFromDate:[NSDate date]]];
            NSString *docDir = (getuid() == 0) ? @"/var/root/Documents" : @"/var/mobile/Documents";
            NSString *filePath = [docDir stringByAppendingPathComponent:filename];
            
            [[NSFileManager defaultManager] createDirectoryAtPath:docDir withIntermediateDirectories:YES attributes:nil error:nil];
            
            if ([data writeToFile:filePath atomically:YES]) {
                ezLog(@"[Success] Saved to: %@", filePath);
                safeCopyToClipboard(filePath);
            } else {
                ezLog(@"[Error] Failed to write file.");
            }
        }
    } @catch (NSException *e) { ezLog(@"[Image Exception] %@", e.reason); }
}

// --- API Logic ---
static void performRequest(NSString *prompt, BOOL isImage) {
    @try {
        ezLog(@"[System] Sending Request...");
        
        NSString *endpoint = isImage ? @"https://api.openai.com/v1/images/generations" : @"https://api.openai.com/v1/chat/completions";
        NSMutableURLRequest *req = [NSMutableURLRequest requestWithURL:[NSURL URLWithString:endpoint]];
        [req setHTTPMethod:@"POST"];
        [req addValue:[NSString stringWithFormat:@"Bearer %@", kOPENAI_API_KEY] forHTTPHeaderField:@"Authorization"];
        [req addValue:@"application/json" forHTTPHeaderField:@"Content-Type"];
        [req setTimeoutInterval:60.0];
        
        NSDictionary *body;
        if (isImage) {
            body = @{@"model": @"dall-e-3", @"prompt": prompt, @"n": @1, @"size": @"1024x1024"};
        } else {
            body = @{
                @"model": model,
                @"messages": @[@{@"role": @"system", @"content": systemMessage}, @{@"role": @"user", @"content": prompt}],
                @"temperature": @(temperature),
                @"frequency_penalty": @(frequencyPenalty) // Included here
            };
        }
        
        [req setHTTPBody:[NSJSONSerialization dataWithJSONObject:body options:0 error:nil]];
        
        dispatch_semaphore_t sema = dispatch_semaphore_create(0);
        
        [[[NSURLSession sharedSession] dataTaskWithRequest:req completionHandler:^(NSData *data, NSURLResponse *res, NSError *err) {
            @try {
                if (err) {
                    ezLog(@"[Network Error] %@", err.localizedDescription);
                } else if (data) {
                    NSDictionary *json = [NSJSONSerialization JSONObjectWithData:data options:0 error:nil];
                    
                    if (json[@"error"]) {
                        ezLog(@"[API Error] %@", json[@"error"][@"message"]);
                    } else if (isImage) {
                        NSString *url = json[@"data"][0][@"url"];
                        if (url) saveImageFromURL(url);
                    } else {
                        NSString *content = json[@"choices"][0][@"message"][@"content"];
                        if (content) {
                            ezLog(@"\n[Assistant]: %@", content);
                            safeCopyToClipboard(content);
                            speakText(content);
                        }
                    }
                }
            } @catch (NSException *e) { ezLog(@"[Callback Exception] %@", e.reason); }
            dispatch_semaphore_signal(sema);
        }] resume];
        
        dispatch_semaphore_wait(sema, DISPATCH_TIME_FOREVER);
        
    } @catch (NSException *e) { ezLog(@"[Request Exception] %@", e.reason); }
}

int main(int argc, const char * argv[]) {
    @autoreleasepool {
        ezLog(@"=== EZComplete V5.1 (Full) ===");
        
        OpenAIKeyManager *km = [[OpenAIKeyManager alloc] init];
        kOPENAI_API_KEY = [km getOpenAI_API_Key];

        // Restore Preferences
        if (Prefs_getString(@"model")) model = Prefs_getString(@"model");
        if (Prefs_getString(@"system_message")) systemMessage = Prefs_getString(@"system_message");
        float savedTemp = Prefs_getFloat(@"temperature");
        if (savedTemp > 0.0) temperature = savedTemp;
        
        // Load Frequency Penalty (Default 0.0 if not set)
        if ([[NSUserDefaults standardUserDefaults] objectForKey:@"frequency_penalty"]) {
             frequencyPenalty = [[NSUserDefaults standardUserDefaults] floatForKey:@"frequency_penalty"];
        }

        while (YES) {
            printf("\n--- Model: %s | Temp: %.2f | FreqPen: %.2f ---\n", [model UTF8String], temperature, frequencyPenalty);
            printf("[P] Prompt | [M] Model | [T] Temp | [F] Freq Penalty | [C] Context | [Exit]\n> ");
            fflush(stdout);
            
            NSString *input = getCleanInput();
            if (!input || [[input uppercaseString] isEqualToString:@"EXIT"]) break;
            
            NSString *cmd = [input uppercaseString];
            
            if ([cmd isEqualToString:@"M"]) {
                printf("1. GPT-4o | 2. 4o-Mini | 3. GPT-5 | 4. DALL-E 3 | 5. 3.5-Turbo\n> ");
                fflush(stdout);
                int choice = [(getCleanInput() ?: @"0") intValue];
                
                if (choice == 1) model = MODEL_GPT4O;
                else if (choice == 2) model = MODEL_GPT4O_MINI;
                else if (choice == 3) model = MODEL_GPT5;
                else if (choice == 4) model = MODEL_DALLE3;
                else if (choice == 5) model = MODEL_GPT35;
                Prefs_setString(model, @"model");
            }
            else if ([cmd isEqualToString:@"T"]) {
                printf("Temp (0.0-2.0): ");
                fflush(stdout);
                NSString *tIn = getCleanInput();
                if (tIn) {
                    temperature = [tIn floatValue];
                    Prefs_setFloat(temperature, @"temperature");
                }
            }
            else if ([cmd isEqualToString:@"F"]) {
                printf("Frequency Penalty (-2.0 to 2.0): ");
                fflush(stdout);
                NSString *fIn = getCleanInput();
                if (fIn) {
                    frequencyPenalty = [fIn floatValue];
                    Prefs_setFloat(frequencyPenalty, @"frequency_penalty");
                }
            }
            else if ([cmd isEqualToString:@"C"]) {
                printf("Current Context: %s\nNew Context: ", [systemMessage UTF8String]);
                fflush(stdout);
                NSString *newC = getCleanInput();
                if (newC && newC.length > 0) {
                    systemMessage = [newC copy];
                    Prefs_setString(systemMessage, @"system_message");
                }
            }
            else if ([cmd isEqualToString:@"P"]) {
                printf("Prompt: ");
                fflush(stdout);
                NSString *p = getCleanInput();
                if (p && p.length > 0) {
                    BOOL isImg = [model isEqualToString:MODEL_DALLE3];
                    performRequest(p, isImg);
                }
            }
        }
        ezLog(@"=== Session Ended ===");
    }
    return 0;
}
