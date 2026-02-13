#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
#import "OpenAIKeyManager.h"

#pragma mark - Supported Models (Current)

#define GPT4O_MINI @"gpt-4o-mini"
#define GPT4O      @"gpt-4o"
#define GPT35      @"gpt-3.5-turbo"

static NSString *model = GPT4O_MINI;
static float temperature = 0.9f;
static float frequency_penalty = 0.2f;
static NSString *kOPENAI_API_KEY = nil;

#pragma mark - Utility

NSString *readLine(void) {
    NSFileHandle *input = [NSFileHandle fileHandleWithStandardInput];
    NSData *data = [input availableData];
    NSString *string = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
    return [string stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
}

#pragma mark - Model Selection

static void selectModel(void) {
    NSLog(@"\nChoose a model:\n(1) gpt-4o-mini (recommended)\n(2) gpt-4o\n(3) gpt-3.5-turbo\n");

    NSString *choice = readLine();

    if ([choice isEqualToString:@"1"]) {
        model = GPT4O_MINI;
    } else if ([choice isEqualToString:@"2"]) {
        model = GPT4O;
    } else if ([choice isEqualToString:@"3"]) {
        model = GPT35;
    } else {
        model = GPT4O_MINI;
    }

    Prefs_setStringForKey(model, @"model");
    NSLog(@"\nModel set to: %@\n", model);
}

#pragma mark - Temperature

static void configureTemperature(void) {
    NSLog(@"\nEnter temperature (0.0 - 2.0): ");
    NSString *input = readLine();

    float tempValue = [input floatValue];
    if (tempValue >= 0.0 && tempValue <= 2.0) {
        temperature = tempValue;
    }

    Prefs_setObjectForKey(@(temperature), @"temperature");
    NSLog(@"\nTemperature set to: %.2f\n", temperature);
}

#pragma mark - Frequency Penalty

static void configureFrequency(void) {
    NSLog(@"\nEnter frequency penalty (0.0 - 2.0): ");
    NSString *input = readLine();

    float freqValue = [input floatValue];
    if (freqValue >= 0.0 && freqValue <= 2.0) {
        frequency_penalty = freqValue;
    }

    Prefs_setObjectForKey(@(frequency_penalty), @"frequency_penalty");
    NSLog(@"\nFrequency penalty set to: %.2f\n", frequency_penalty);
}

#pragma mark - Main

int main(int argc, const char * argv[]) {
    @autoreleasepool {

        OpenAIKeyManager *keyManager = [[OpenAIKeyManager alloc] init];
        kOPENAI_API_KEY = [keyManager getOpenAI_API_Key];

        if (!kOPENAI_API_KEY || ![kOPENAI_API_KEY containsString:@"sk-"]) {
            NSLog(@"Enter your OpenAI API key:");
            kOPENAI_API_KEY = [keyManager promptUserForKey];
            Prefs_setStringForKey(kOPENAI_API_KEY, @"OPENAI_API_KEY");
        }

        NSLog(@"\nAPI Key Loaded. Starting CLI Chat.\n");

        while (YES) {

            NSLog(@"\nOptions: (P)rompt  (M)odel  (T)emperature  (F)requency  (exit)\n");
            NSString *command = readLine();

            if ([command isEqualToString:@"exit"]) break;

            if ([command.lowercaseString isEqualToString:@"m"]) {
                selectModel();
                continue;
            }

            if ([command.lowercaseString isEqualToString:@"t"]) {
                configureTemperature();
                continue;
            }

            if ([command.lowercaseString isEqualToString:@"f"]) {
                configureFrequency();
                continue;
            }

            if (![command.lowercaseString isEqualToString:@"p"]) continue;

            NSLog(@"\nEnter prompt:");
            NSString *prompt = readLine();
            if ([prompt isEqualToString:@"exit"]) break;
            if (prompt.length == 0) continue;

            NSURL *url = [NSURL URLWithString:@"https://api.openai.com/v1/chat/completions"];
            NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:url];
            [request setHTTPMethod:@"POST"];
            [request addValue:[NSString stringWithFormat:@"Bearer %@", kOPENAI_API_KEY]
           forHTTPHeaderField:@"Authorization"];
            [request addValue:@"application/json"
           forHTTPHeaderField:@"Content-Type"];

            NSDictionary *parameters = @{
                @"model": model,
                @"messages": @[
                        @{@"role": @"user",
                          @"content": prompt}
                ],
                @"temperature": @(temperature),
                @"frequency_penalty": @(frequency_penalty),
                @"max_tokens": @2048
            };

            NSData *postData = [NSJSONSerialization dataWithJSONObject:parameters options:0 error:nil];
            [request setHTTPBody:postData];

            dispatch_semaphore_t sem = dispatch_semaphore_create(0);

            NSURLSessionDataTask *task =
            [[NSURLSession sharedSession] dataTaskWithRequest:request
                                            completionHandler:^(NSData *data,
                                                                NSURLResponse *response,
                                                                NSError *error) {

                if (error) {
                    NSLog(@"Error: %@", error.localizedDescription);
                } else {
                    NSDictionary *json =
                    [NSJSONSerialization JSONObjectWithData:data options:0 error:nil];

                    NSArray *choices = json[@"choices"];
                    if (choices.count > 0) {
                        NSString *reply =
                        choices[0][@"message"][@"content"];
                        NSLog(@"\n%@", reply);
                    } else {
                        NSLog(@"No response.");
                    }
                }

                dispatch_semaphore_signal(sem);
            }];

            [task resume];
            dispatch_semaphore_wait(sem, DISPATCH_TIME_FOREVER);
        }
    }

    return 0;
}

