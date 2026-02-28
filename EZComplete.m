#import <Foundation/Foundation.h>
#import <AVFoundation/AVFoundation.h>
#import "OpenAIKeyManager.h"

// --- Model Constants ---
#define MODEL_GPT4O       @"gpt-4o"
#define MODEL_GPT4O_MINI  @"gpt-4o-mini"
#define MODEL_GPT5        @"gpt-5"
#define MODEL_GPT35       @"gpt-3.5-turbo"
#define MODEL_DALLE3      @"dall-e-3"

// --- Global State ---
static NSString *model = @"gpt-4o-mini"; // Default to cheapest
static float temperature = 0.7f;
static float frequencyPenalty = 0.0f;
static NSString *systemMessage = @"You are a helpful assistant.";
static NSString *kOPENAI_API_KEY = nil;
static AVSpeechSynthesizer *synthesizer = nil;

// --- Helper: The "Straggler" (Get Float) ---
static float Prefs_getFloat(NSString *key) {
    return [[NSUserDefaults standardUserDefaults] floatForKey:key];
}

// --- Helper: Clean Input ---
static NSString* getCleanInput(void) {
    char buffer[4096];
    if (fgets(buffer, sizeof(buffer), stdin) != NULL) {
        NSString *raw = [NSString stringWithUTF8String:buffer];
        return [raw stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
    }
    return nil;
}

// --- Unified Logging (Daily) ---
static void logUI(NSString *format, ...) {
    va_list args;
    va_start(args, format);
    NSString *message = [[NSString alloc] initWithFormat:format arguments:args];
    va_end(args);

    printf("%s\n", [message UTF8String]);

    @try {
        NSDateFormatter *df = [[NSDateFormatter alloc] init];
        [df setDateFormat:@"yyyy-MM-dd"];
        NSString *dateStr = [df stringFromDate:[NSDate date]];
        
        NSString *docDir = (getuid() == 0) ? @"/var/root/Documents" : @"/var/mobile/Documents";
        NSString *logPath = [docDir stringByAppendingPathComponent:[NSString stringWithFormat:@"ez-log-%@.txt", dateStr]];
        
        if (![[NSFileManager defaultManager] fileExistsAtPath:docDir]) {
            [[NSFileManager defaultManager] createDirectoryAtPath:docDir withIntermediateDirectories:YES attributes:nil error:nil];
        }

        NSString *logEntry = [NSString stringWithFormat:@"[%@] %@\n", [NSDate date], message];
        
        if (![[NSFileManager defaultManager] fileExistsAtPath:logPath]) {
            [logEntry writeToFile:logPath atomically:YES encoding:NSUTF8StringEncoding error:nil];
        } else {
            NSFileHandle *handle = [NSFileHandle fileHandleForWritingAtPath:logPath];
            [handle seekToEndOfFile];
            [handle writeData:[logEntry dataUsingEncoding:NSUTF8StringEncoding]];
            [handle closeFile];
        }
    } @catch (NSException *e) {}
}

// --- Audio Fix ---
static void speakText(NSString *text) {
    if (!text || text.length == 0) return;
    @try {
        AVAudioSession *session = [AVAudioSession sharedInstance];
        // Ensure category is set for playback
        [session setCategory:AVAudioSessionCategoryPlayback withOptions:AVAudioSessionCategoryOptionMixWithOthers error:nil];
        [session setActive:YES error:nil];

        if (!synthesizer) synthesizer = [[AVSpeechSynthesizer alloc] init];
        
        if ([synthesizer isSpeaking]) {
            [synthesizer stopSpeakingAtBoundary:AVSpeechBoundaryImmediate];
        }

        AVSpeechUtterance *utterance = [AVSpeechUtterance speechUtteranceWithString:text];
        utterance.rate = 0.52;
        utterance.voice = [AVSpeechSynthesisVoice voiceWithLanguage:@"en-US"];
        
        [synthesizer speakUtterance:utterance];
        logUI(@"[System] Audio started.");
    } @catch (NSException *e) {
        logUI(@"[Audio Error] %@", e.reason);
    }
}

// --- Image Saving Logic (Restored) ---
static void downloadAndSaveImage(NSString *urlString) {
    @try {
        logUI(@"[System] Downloading image to Documents...");
        NSURL *url = [NSURL URLWithString:urlString];
        NSData *data = [NSData dataWithContentsOfURL:url];
        
        if (data) {
            NSDateFormatter *df = [[NSDateFormatter alloc] init];
            [df setDateFormat:@"yyyyMMdd_HHmmss"];
            NSString *filename = [NSString stringWithFormat:@"DALLE_%@.png", [df stringFromDate:[NSDate date]]];
            NSString *docDir = (getuid() == 0) ? @"/var/root/Documents" : @"/var/mobile/Documents";
            NSString *filePath = [docDir stringByAppendingPathComponent:filename];
            
            if ([data writeToFile:filePath atomically:YES]) {
                logUI(@"[Success] Image saved: %@", filePath);
            } else {
                logUI(@"[Error] Failed to save image file.");
            }
        }
    } @catch (NSException *e) {
        logUI(@"[Image Exception] %@", e.reason);
    }
}

// --- API Request ---
static void performRequest(NSString *prompt, BOOL isImage) {
    @try {
        logUI(@"[System] Sending Request...");
        
        NSURLSessionConfiguration *config = [NSURLSessionConfiguration defaultSessionConfiguration];
        config.timeoutIntervalForRequest = 45.0;
        NSURLSession *session = [NSURLSession sessionWithConfiguration:config];

        NSString *url = isImage ? @"https://api.openai.com/v1/images/generations" : @"https://api.openai.com/v1/chat/completions";
        NSMutableURLRequest *req = [NSMutableURLRequest requestWithURL:[NSURL URLWithString:url]];
        [req setHTTPMethod:@"POST"];
        [req addValue:[NSString stringWithFormat:@"Bearer %@", kOPENAI_API_KEY] forHTTPHeaderField:@"Authorization"];
        [req addValue:@"application/json" forHTTPHeaderField:@"Content-Type"];

        NSDictionary *body;
        if (isImage) {
            body = @{@"model":@"dall-e-3", @"prompt":prompt, @"n":@1, @"size":@"1024x1024"};
        } else {
            body = @{
                @"model": model,
                @"messages": @[@{@"role":@"system", @"content":systemMessage}, @{@"role":@"user", @"content":prompt}],
                @"temperature": @(temperature),
                @"frequency_penalty": @(frequencyPenalty)
            };
        }
        [req setHTTPBody:[NSJSONSerialization dataWithJSONObject:body options:0 error:nil]];

        dispatch_semaphore_t sema = dispatch_semaphore_create(0);
        [[session dataTaskWithRequest:req completionHandler:^(NSData *data, NSURLResponse *res, NSError *err) {
            @try {
                if (err) {
                    logUI(@"[Network Error] %@", err.localizedDescription);
                } else if (data) {
                    NSDictionary *json = [NSJSONSerialization JSONObjectWithData:data options:0 error:nil];
                    if (json[@"error"]) {
                        logUI(@"[API Error] %@", json[@"error"][@"message"]);
                    } else if (isImage) {
                        NSString *imgUrl = json[@"data"][0][@"url"];
                        if (imgUrl) downloadAndSaveImage(imgUrl);
                    } else {
                        NSString *content = json[@"choices"][0][@"message"][@"content"];
                        if (content) {
                            logUI(@"\n[Assistant]: %@", content);
                            speakText(content);
                            
                            // Rootless Clipboard
                            const char *pb = "/var/jb/usr/bin/pbcopy";
                            if (access(pb, F_OK) == 0) {
                                FILE *f = popen(pb, "w");
                                if (f) { fwrite([content UTF8String], 1, strlen([content UTF8String]), f); pclose(f); }
                            }
                        }
                    }
                }
            } @catch (NSException *e) { logUI(@"[Handler Crash] %@", e.reason); }
            dispatch_semaphore_signal(sema);
        }] resume];
        dispatch_semaphore_wait(sema, DISPATCH_TIME_FOREVER);
    } @catch (NSException *e) { logUI(@"[Request Crash] %@", e.reason); }
}

int main(int argc, const char * argv[]) {
    @autoreleasepool {
        logUI(@"=== EZComplete V6.5 (Budget Build) ===");
        
        OpenAIKeyManager *km = [[OpenAIKeyManager alloc] init];
        kOPENAI_API_KEY = [km getOpenAI_API_Key];

        // Load Preferences
        if (Prefs_getString(@"model")) model = Prefs_getString(@"model");
        if (Prefs_getString(@"system_message")) systemMessage = Prefs_getString(@"system_message");
        if (Prefs_getFloat(@"temperature") > 0) temperature = Prefs_getFloat(@"temperature");
        if (Prefs_getFloat(@"frequency_penalty") != 0) frequencyPenalty = Prefs_getFloat(@"frequency_penalty");

        while (YES) {
            printf("\n--- %s | T: %.2f | F: %.2f ---\n", [model UTF8String], temperature, frequencyPenalty);
            printf("[P] Prompt | [M] Model | [T] Temp | [F] Penalty | [C] Context | [Exit]\n> ");
            fflush(stdout);
            
            NSString *input = getCleanInput();
            if (!input || [[input uppercaseString] isEqualToString:@"EXIT"]) break;
            
            NSString *cmd = [input uppercaseString];
            
            if ([cmd isEqualToString:@"M"]) {
                printf("1. 4o | 2. 4o-Mini | 3. GPT-5 | 4. DALL-E 3 | 5. 3.5-Turbo\n> ");
                fflush(stdout);
                NSString *choice = getCleanInput();
                if ([choice isEqualToString:@"1"]) model = MODEL_GPT4O;
                else if ([choice isEqualToString:@"2"]) model = MODEL_GPT4O_MINI;
                else if ([choice isEqualToString:@"3"]) model = MODEL_GPT5;
                else if ([choice isEqualToString:@"4"]) model = MODEL_DALLE3;
                else if ([choice isEqualToString:@"5"]) model = MODEL_GPT35;
                
                Prefs_setString(model, @"model");
                logUI(@"[System] Model: %@", model);
            }
            else if ([cmd isEqualToString:@"T"]) {
                printf("New Temp (0.0-2.0): ");
                fflush(stdout);
                NSString *tIn = getCleanInput();
                if (tIn) {
                    temperature = [tIn floatValue];
                    Prefs_setFloat(temperature, @"temperature");
                }
            }
            else if ([cmd isEqualToString:@"F"]) {
                printf("New Freq Penalty: ");
                fflush(stdout);
                NSString *fIn = getCleanInput();
                if (fIn) {
                    frequencyPenalty = [fIn floatValue];
                    Prefs_setFloat(frequencyPenalty, @"frequency_penalty");
                }
            }
            else if ([cmd isEqualToString:@"C"]) {
                if(systemMessage != nil && systemMessage.length >0) {
                printf("Current system message: %@ \n", systemMessage);
                }
                printf("New Context: ");
                fflush(stdout);
                NSString *newC = getCleanInput();
                if (newC && newC.length > 0) {
                    systemMessage = newC;
                    Prefs_setString(systemMessage, @"system_message");
                }
            }
            else if ([cmd isEqualToString:@"P"]) {
                printf("Prompt: ");
                fflush(stdout);
                NSString *p = getCleanInput();
                if (p && p.length > 0) {
                    logUI(@"[User]: %@", p);
                    performRequest(p, [model isEqualToString:MODEL_DALLE3]);
                }
            }
        }
        logUI(@"=== End Session ===");
    }
    return 0;
}
