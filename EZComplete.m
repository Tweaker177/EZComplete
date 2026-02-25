#import <Foundation/Foundation.h>
#import <AVFoundation/AVFoundation.h>
#import <spawn.h>
#import <sys/wait.h>
#import "OpenAIKeyManager.h"

extern char **environ;

#define MODEL_GPT4O     @"gpt-4o"
#define MODEL_GPT4O_MINI @"gpt-4o-mini"
#define MODEL_GPT5      @"gpt-5"
#define MODEL_DALLE3    @"dall-e-3"
#define MODEL_GPT35     @"gpt-3.5-turbo"

static NSString *model = @"gpt-4o-mini";
static float temperature = 0.7f;
static NSString *systemMessage = @"You are a helpful assistant.";
static NSString *kOPENAI_API_KEY = nil;

static NSString* getCleanInput(void) {
    char buffer[4096];
    if (fgets(buffer, sizeof(buffer), stdin) != NULL) {
        return [[NSString stringWithUTF8String:buffer] stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
    }
    return nil;
}

static void processOutput(NSString *text) {
    if (!text || text.length == 0) return;
    const char *pbPath = "/var/jb/usr/bin/pbcopy";
    if (access(pbPath, F_OK) != 0) pbPath = "/usr/bin/pbcopy";
    FILE *pb = popen(pbPath, "w");
    if (pb) {
        const char *rawText = [text UTF8String];
        fwrite(rawText, 1, strlen(rawText), pb);
        fflush(pb);
        pclose(pb);
        printf("\n[System] Result copied to clipboard.\n");
    }
    @try {
        AVSpeechUtterance *u = [AVSpeechUtterance speechUtteranceWithString:text];
        u.rate = 0.55;
        static AVSpeechSynthesizer *synth;
        if (!synth) synth = [[AVSpeechSynthesizer alloc] init];
        [synth speakUtterance:u];
    } @catch (NSException *e) {}
    printf("\n[Assistant]: %s\n", [text UTF8String]);
}

static void saveImageFromURL(NSString *urlString) {
    printf("\n[System] Downloading image...\n");
    NSData *data = [NSData dataWithContentsOfURL:[NSURL URLWithString:urlString]];
    if (data) {
        NSDateFormatter *df = [[NSDateFormatter alloc] init];
        [df setDateFormat:@"yyyyMMdd_HHmmss"];
        NSString *filename = [NSString stringWithFormat:@"DALLE_%@.png", [df stringFromDate:[NSDate date]]];
        NSString *docDir = (getuid() == 0) ? @"/var/root/Documents" : @"/var/mobile/Documents";
        NSString *filePath = [docDir stringByAppendingPathComponent:filename];
        [[NSFileManager defaultManager] createDirectoryAtPath:docDir withIntermediateDirectories:YES attributes:nil error:nil];
        if ([data writeToFile:filePath atomically:YES]) {
            printf("[Success] Image saved to: %s\n", [filePath UTF8String]);
            processOutput(filePath);
        }
    }
}

static void generateImage(NSString *prompt) {
    printf("\n[System] Generating DALL-E 3 image...\n");
    NSMutableURLRequest *req = [NSMutableURLRequest requestWithURL:[NSURL URLWithString:@"https://api.openai.com/v1/images/generations"]];
    [req setHTTPMethod:@"POST"];
    [req addValue:[NSString stringWithFormat:@"Bearer %@", kOPENAI_API_KEY] forHTTPHeaderField:@"Authorization"];
    [req addValue:@"application/json" forHTTPHeaderField:@"Content-Type"];
    NSDictionary *body = @{@"model": @"dall-e-3", @"prompt": prompt, @"n": @1, @"size": @"1024x1024"};
    [req setHTTPBody:[NSJSONSerialization dataWithJSONObject:body options:0 error:nil]];
    dispatch_semaphore_t sema = dispatch_semaphore_create(0);
    [[[NSURLSession sharedSession] dataTaskWithRequest:req completionHandler:^(NSData *data, NSURLResponse *res, NSError *err) {
        if (data) {
            NSDictionary *json = [NSJSONSerialization JSONObjectWithData:data options:0 error:nil];
            @try { saveImageFromURL(json[@"data"][0][@"url"]); } @catch (NSException *e) { printf("\n[Error] Image failed.\n"); }
        }
        dispatch_semaphore_signal(sema);
    }] resume];
    dispatch_semaphore_wait(sema, DISPATCH_TIME_FOREVER);
}

static void generateChat(NSString *prompt) {
    NSMutableURLRequest *req = [NSMutableURLRequest requestWithURL:[NSURL URLWithString:@"https://api.openai.com/v1/chat/completions"]];
    [req setHTTPMethod:@"POST"];
    [req addValue:[NSString stringWithFormat:@"Bearer %@", kOPENAI_API_KEY] forHTTPHeaderField:@"Authorization"];
    [req addValue:@"application/json" forHTTPHeaderField:@"Content-Type"];
    NSDictionary *body = @{@"model": model, @"messages": @[@{@"role": @"system", @"content": systemMessage}, @{@"role": @"user", @"content": prompt}], @"temperature": @(temperature)};
    [req setHTTPBody:[NSJSONSerialization dataWithJSONObject:body options:0 error:nil]];
    dispatch_semaphore_t sema = dispatch_semaphore_create(0);
    [[[NSURLSession sharedSession] dataTaskWithRequest:req completionHandler:^(NSData *data, NSURLResponse *res, NSError *err) {
        if (data) {
            NSDictionary *json = [NSJSONSerialization JSONObjectWithData:data options:0 error:nil];
            @try { processOutput(json[@"choices"][0][@"message"][@"content"]); } @catch (NSException *e) { printf("\n[Error] Chat failed.\n"); }
        }
        dispatch_semaphore_signal(sema);
    }] resume];
    dispatch_semaphore_wait(sema, DISPATCH_TIME_FOREVER);
}

int main(int argc, const char * argv[]) {
    @autoreleasepool {
        OpenAIKeyManager *km = [OpenAIKeyManager new];
        kOPENAI_API_KEY = [km getOpenAI_API_Key];
        if (Prefs_getString(@"model")) model = Prefs_getString(@"model");
        if (Prefs_getString(@"system_message")) systemMessage = Prefs_getString(@"system_message");
        if (Prefs_objectForKey(@"temperature")) temperature = [Prefs_objectForKey(@"temperature") floatValue];
        
        while (YES) {
            printf("\n--- EZComplete (V3.9) ---\nModel: %s | Temp: %.2f\n[P] Prompt | [M] Model | [T] Temp | [C] Context | [Exit]\n> ", [model UTF8String], temperature);
            fflush(stdout);
            NSString *input = getCleanInput();
            if (!input || [[input uppercaseString] isEqualToString:@"EXIT"]) break;
            
            if ([[input uppercaseString] isEqualToString:@"M"]) {
                printf("1. GPT-4o | 2. GPT-4o-Mini | 3. GPT-5 | 4. DALL-E 3 | 5. GPT-3.5-Turbo\n> ");
                fflush(stdout);
                int choice = [(getCleanInput() ?: @"0") intValue];
                if (choice == 1) model = MODEL_GPT4O;
                else if (choice == 2) model = MODEL_GPT4O_MINI;
                else if (choice == 3) model = MODEL_GPT5;
                else if (choice == 4) model = MODEL_DALLE3;
                else if (choice == 5) model = MODEL_GPT35;
                Prefs_setStringForKey(model, @"model");
            } else if ([[input uppercaseString] isEqualToString:@"T"]) {
                printf("Temp (0.0-2.0): ");
                fflush(stdout);
                NSString *tIn = getCleanInput(); // FIXED: Proper declaration
                temperature = [(tIn ?: @"0.7") floatValue];
                Prefs_setObjectForKey(@(temperature), @"temperature");
            } else if ([[input uppercaseString] isEqualToString:@"C"]) {
                printf("Context: ");
                fflush(stdout);
                NSString *newC = getCleanInput();
                if (newC.length > 0) { systemMessage = [newC copy]; Prefs_setStringForKey(systemMessage, @"system_message"); }
            } else if ([[input uppercaseString] isEqualToString:@"P"]) {
                printf("Prompt: ");
                fflush(stdout);
                NSString *p = getCleanInput();
                if (p.length > 0) {
                    if ([model isEqualToString:MODEL_DALLE3]) generateImage(p);
                    else generateChat(p);
                }
            }
        }
    }
    return 0;
}
