//
//  DebugMode.h
//  NepTunes
//
//  Created by Adam Różyński on 26/09/2016.
//  Copyright © 2016 micropixels. All rights reserved.
//

#ifndef DebugMode_h
#define DebugMode_h

#define DebugMode(format, ...)        if ([[SettingsController sharedSettings] debugMode]) {NSLog(format, ##__VA_ARGS__);};


#endif /* DebugMode_h */
