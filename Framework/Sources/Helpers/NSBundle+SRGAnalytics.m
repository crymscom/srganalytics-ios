//
//  Copyright (c) SRG SSR. All rights reserved.
//
//  License information is available from the LICENSE file.
//

#import "NSBundle+SRGAnalytics.h"

#import "SRGAnalyticsTracker.h"

#import <UIKit/UIKit.h>

@implementation NSBundle (SRGAnalytics)

+ (instancetype)srg_analyticsBundle
{
    static NSBundle *s_bundle;
    static dispatch_once_t s_onceToken;
    dispatch_once(&s_onceToken, ^{
        NSString *bundlePath = [[NSBundle bundleForClass:[SRGAnalyticsTracker class]].bundlePath stringByAppendingPathComponent:@"SRGAnalytics.bundle"];
        s_bundle = [NSBundle bundleWithPath:bundlePath];
        NSAssert(s_bundle, @"Please add SRGAnalytics.bundle to your project resources");
    });
    return s_bundle;
}

+ (BOOL)srg_isProductionVersion
{
    // Check SIMULATOR_DEVICE_NAME for iOS 9 and above, device name below
    if ([NSProcessInfo processInfo].environment[@"SIMULATOR_DEVICE_NAME"]
            || [[UIDevice currentDevice].name.lowercaseString containsString:@"simulator"]) {
        return NO;
    }
    
    if ([[NSBundle mainBundle] pathForResource:@"embedded" ofType:@"mobileprovision"]) {
        return NO;
    }
    
    return ([NSBundle mainBundle].appStoreReceiptURL != nil);
}

@end
