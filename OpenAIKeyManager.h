//
//  OpenAIKeyManager.h
//  
//
//  Created by Brian A Nooning on 3/19/23.
//


#ifndef OpenAIKeyManager_h
#define OpenAIKeyManager_h

#endif

// OpenAIKeyManager_h

#import <UIKit/UIKit.h>
#import <Foundation/Foundation.h>
#include <stdlib.h>
#import <objc/runtime.h>

#define Prefs [[NSUserDefaults alloc] initWithSuiteName:@"com.i0stweak3r.ezcomplete"]
    
#define Prefs_setObjectForKey(objectToSet, key) [Prefs setObject:objectToSet forKey:key]
//Used for converting type if necessary,
//like Prefs_objectForKey:string [NSString stringWithFloat:string] floatValue];
#define Prefs_objectForKey(key) [Prefs objectForKey:key]   //returns any object in appropiate id form, so @"1" could be a float,integer, or char stored as NSNumber object
#define Prefs_getString(key) [Prefs stringForKey:key]   //returns string value for supplied key thats saved in defaults
#define Prefs_setStringForKey(string, key) [Prefs setObject:string forKey:key]  //set a string value for a specific key aka set KVP
#define Prefs_setIntegerForKey(integer, key) [Prefs setInteger:integer forKey:key]   //set integer to specific key, can be in integer form no need for NSNumber
#define Prefs_getInteger(key) [Prefs integerForKey:key]   //get integer from a key that holds an integer value

@interface OpenAIKeyManager : NSObject
//+ (instancetype) init;
- (NSString *) promptUserForKey;
- (NSString *) getOpenAI_API_Key;

- (NSString *) readKeyFromEnvironment;
- (NSString *) readKeyFromDefaults;
@end

/****
@interface APIKeyManager : NSObject
//+ (instancetype)init;
+ (NSString *)getKeyForAPI:(NSString*)API;  //using one of the below methods
//this method should return the API key for the API specified, for example openAI, google cloud, etc
// If no key is found it should promptUserForKey,and display an error message if
//getOpenAI_API_Key
+ (NSString *)readKeyForAPI:(NSString*)API fromDefaults:(NSUserDefaults*)defaults;
+ (NSString *)checkProcessEnvForKeyForAPI:(NSString*)API; //check the process.env file for the desired key
// Look for the API Key saved as a local environment variable
+ (NSString *)promptUserForKeyForAPI:(NSString*)API; //prompt user to enter their API_KEY used to access the API named in the API string
+ (void)saveKey:(NSString *)key ForAPI:(NSString*)API toDefaults:(NSString *)defaults; //OPENAI_API_KEY;
@end
***/
