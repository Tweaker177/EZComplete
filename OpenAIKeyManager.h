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


#define Prefs [NSUserDefaults standardUserDefaults]
    
#define Prefs_setObject(object,key) [Prefs setObject:object forKey:key]
//Used for converting type if necessary,
//like Prefs_objectForKey:string [NSString stringWithFloat:string] floatValue];
#define Prefs_getObject(key) [Prefs objectForKey:key]   //returns any object in appropiate id form, so @"1" could be a float,integer, or char stored as NSNumber object
#define Prefs_getString(key) [Prefs stringForKey:key]   //returns string value for supplied key thats saved in defaults
#define Prefs_setString(string, key) [Prefs setObject:string forKey:key]  //set a string value for a specific key aka set KVP
#define Prefs_setInteger(integer, key) [Prefs setInteger:integer forKey:key]   //set integer to specific key
#define Prefs_getInteger(key) [Prefs integerForKey:key]   //get integer from a key that holds an integer value
#define Prefs_setFloat(float,key) [Prefs setFloat:float forKey: key]

//#define Prefs_getFloat(key) [Prefs floatForKey:key]   // returns a float from a key that holds a float value

@interface OpenAIKeyManager : NSObject
- (NSString *) promptUserForKey;
- (NSString *) getOpenAI_API_Key;
- (NSString *) readKeyFromEnvironment;
- (NSString *) readKeyFromDefaults;
@end
