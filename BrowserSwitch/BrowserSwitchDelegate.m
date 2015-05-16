//
//  BrowserSwitchDelegate.m
//  BrowserSwitch
//
//  Created by Kent Huang on 2015/5/16.
//  Copyright (c) 2015年 Kent Huang. All rights reserved.
//

#import "BrowserSwitchDelegate.h"

@implementation BrowserSwitchDelegate

- (instancetype)init
{
    if (self = [super init]) {
        // Init delegate
        supportHandlers = [NSMutableArray arrayWithArray:SUPPORT_BROWSER];
        urlschemerefs = [[NSArray alloc] initWithObjects:@"http", nil];
        
        originalHandler = [self getDefaultHandler];
        if ([self isSupportHandler:originalHandler] == NO) {
            [supportHandlers addObject:originalHandler];
        }
        
        if ([self setAcModeHandler:SUGGEST_AC_MODE_HANDLE] == NO) {
            [self setAcModeHandler:originalHandler];
        }
        if ([self setBatteryModeHandler:SUGGEST_BATTERY_MODE_HANDLE] == NO) {
            [self setBatteryModeHandler:originalHandler];
        }
        
        httpHandlers = [self fetchAllHttpHandlers];
        [self getPowerSourceInfo];
    }
    
    return self;
}

- (void)finalize
{
    // Rostore to original setting
    [self setDefaultHttpHandler:originalHandler];
    [super finalize];
}
- (BOOL)isSupportHandler:(NSString *)handler
{
    for (NSString *app in supportHandlers) {
        if ([app isEqualToString:handler]) {
            return YES;
        }
    }
    return NO;
}

- (NSArray *)fetchAllHttpHandlers
{
    NSArray *handlerList = nil;
    
    handlerList = (__bridge NSArray*)LSCopyAllHandlersForURLScheme((__bridge CFStringRef)[urlschemerefs objectAtIndex:0]);
    
    for (int i = 0; i < [handlerList count]; i++) {
        NSString* handler = [handlerList objectAtIndex:i];
        if ([self isSupportHandler:handler]) {
            NSLog(@"Support Application Handler: %@",handler);
        }
    }
    
    return handlerList;
}

- (NSString *)getDefaultHandler
{
    return (__bridge NSString*)(LSCopyDefaultHandlerForURLScheme((__bridge CFStringRef)([urlschemerefs objectAtIndex:0])));
}

- (BOOL)setDefaultHttpHandler:(NSString *)newHandler
{
    OSStatus rc;
    if ([self isSupportHandler:newHandler] == NO) {
        return NO;
    }
    
    for (NSString *urlschemeref in urlschemerefs) {
        rc = LSSetDefaultHandlerForURLScheme((__bridge CFStringRef)urlschemeref,(__bridge CFStringRef)newHandler);
        NSLog(@"Set %@ handler = %@, rc = %d",urlschemeref, newHandler, rc);
     }
    
    return YES;
}

- (BOOL)registerPowerSourceNotification
{
    CFRunLoopSourceRef powerSourceRLS = NULL;
    powerSourceRLS = IOPSNotificationCreateRunLoopSource(powerStatusChangedCallback, (__bridge void *)(self));
    if (NULL == powerSourceRLS) {
        NSLog(@"Err: Can't register Power Source Notification");
        return NO;
    }
    CFRunLoopAddSource([[NSRunLoop mainRunLoop] getCFRunLoop],powerSourceRLS,kCFRunLoopDefaultMode);
    CFRelease(powerSourceRLS);
    
    return YES;
}

- (void)getPowerSourceInfo
{
    CFTypeRef   blob = NULL;
    CFArrayRef  sources = NULL;
    
    blob = IOPSCopyPowerSourcesInfo();
    if (NULL == blob) {
        goto END;
    }
    
    sources = IOPSCopyPowerSourcesList(blob);
    if (NULL == sources){
        goto END;
    }
    
    if (CFArrayGetCount(sources) == 0) {
        goto END;	// Could not retrieve battery information.  System may not have a battery.
    }
    
    CFDictionaryRef pSource = IOPSGetPowerSourceDescription(blob, CFArrayGetValueAtIndex(sources, 0));
    if ([self checkAcPowerStatus:pSource] == YES) {
        NSLog(@"AC Power Mode");
        [self setDefaultHttpHandler:acModeHandler];
    }
    else {
        NSLog(@"Battery Power Mode");
        [self setDefaultHttpHandler:batteryModeHandler];
    }
    
END:
    if (blob) {
        CFRelease(blob);
        blob = NULL;
    }
    if (sources) {
        CFRelease(sources);
        sources = NULL;
    }
}

- (BOOL)checkAcPowerStatus:(CFDictionaryRef)pSource
{
    NSDictionary *dict = (__bridge NSDictionary*)pSource;
    NSString *state = nil;
    id val = nil;
    
    val = [dict objectForKey:@kIOPSPowerSourceStateKey];
    if (val) {
        state = val;
    }
    else {
        state = @"-";
    }
    
    if ([state rangeOfString:(NSString *)CFSTR(kIOPSACPowerValue)].location == NSNotFound) {
        isAc = NO;
    }
    else {
        isAc = YES;
    }
    return isAc;
}

#pragma mark - Configure interface
- (BOOL)setAcModeHandler:(NSString *)handler
{
    if ([self isSupportHandler:handler] == NO) {
        return NO;
    }
    
    acModeHandler = handler;
    
    return YES;
}

- (BOOL)setBatteryModeHandler:(NSString *)handler
{
    if ([self isSupportHandler:handler] == NO) {
        return NO;
    }
    
    batteryModeHandler = handler;
    
    return YES;
}
#pragma mark - Run flow
- (void)run
{
    [self setup];
}

- (void)setup
{
    signal(SIGTERM, shutdownDaemonEvent);
    signal(SIGINT, shutdownDaemonEvent);
    
    [self registerPowerSourceNotification];
}

#pragma mark - C style callback function
void powerStatusChangedCallback(void *context)
{
    BrowserSwitchDelegate *s = (__bridge BrowserSwitchDelegate*) context;
    [s getPowerSourceInfo];
}

void shutdownDaemonEvent(int sig)
{
    NSLog(@"Shutdown daemon...");
    exit(0);
}

@end