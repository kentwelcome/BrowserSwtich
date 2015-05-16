//
//  BrowserSwitchDelegate.h
//  BrowserSwitch
//
//  Created by Kent Huang on 2015/5/16.
//  Copyright (c) 2015年 Kent Huang. All rights reserved.
//

#ifndef BrowserSwitch_BrowserSwitchDelegate_h
#define BrowserSwitch_BrowserSwitchDelegate_h

#import <Foundation/Foundation.h>
#import <IOKit/IOKitLib.h>
#import <IOKit/ps/IOPSKeys.h>
#import <IOKit/ps/IOPowerSources.h>
#import <ApplicationServices/ApplicationServices.h>

#define SAFARI  @"com.apple.Safari"
#define CHROME  @"com.google.chrome"

#define SUGGEST_AC_MODE_HANDLE      CHROME
#define SUGGEST_BATTERY_MODE_HANDLE SAFARI
#define SUPPORT_BROWSER             @[SAFARI,CHROME]


#define GETCFRVAL(theDict, key, value) ( value = CFDictionaryGetValue(theDict, key) )


@interface BrowserSwitchDelegate : NSObject {
    NSMutableArray *supportHandlers;
    NSArray     *urlschemerefs;
    NSArray     *httpHandlers;
    NSString    *originalHandler;
    NSString    *acModeHandler;
    NSString    *batteryModeHandler;
    BOOL        isAc;
}

- (BOOL)setAcModeHandler:(NSString*) handler;
- (BOOL)setBatteryModeHandler:(NSString*) handler;

- (BOOL)isSupportHandler:(NSString*) handler;
- (NSArray*)fetchAllHttpHandlers;
- (NSString*)getDefaultHandler;

- (BOOL)setDefaultHttpHandler:(NSString*) newHandler;
- (BOOL)checkAcPowerStatus:(CFDictionaryRef) pSource;
- (void)getPowerSourceInfo;
- (BOOL)registerPowerSourceNotification;
- (void)setup;
- (void)run;

@end

void powerStatusChangedCallback(void *context);
void shutdownDaemonEvent(int sig);
#endif
