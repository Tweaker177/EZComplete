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
#define Prefs_setIntegerForKey(integer, key) [Prefs setInteger:integer forKey:key]   //set integer to specific key
#define Prefs_getInteger(key) [Prefs integerForKey:key]   //get integer from a key that holds an integer value

@interface OpenAIKeyManager : NSObject
- (NSString *) promptUserForKey;
- (NSString *) getOpenAI_API_Key;
- (NSString *) readKeyFromEnvironment;
- (NSString *) readKeyFromDefaults;
@end
