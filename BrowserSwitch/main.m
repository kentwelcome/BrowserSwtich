//
//  main.m
//  BrowserSwitch
//
//  Created by Kent Huang on 2015/5/16.
//  Copyright (c) 2015年 Kent Huang. All rights reserved.
//

#import <Foundation/Foundation.h>

#import "BrowserSwitchDelegate.h"


void callbackPowerSource(void *context)
{
    NSLog(@"Power source change!");
}

int main(int argc, const char * argv[]) {
    @autoreleasepool {
        
        BrowserSwitchDelegate *bsDelegate = [[BrowserSwitchDelegate alloc] init];
        
        [bsDelegate performSelectorInBackground:@selector(run) withObject:nil];
        
        [[NSRunLoop mainRunLoop] run];
    }
    return 0;
}
