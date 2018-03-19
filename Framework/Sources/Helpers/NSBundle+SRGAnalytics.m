//
//  Copyright (c) SRG SSR. All rights reserved.
//
//  License information is available from the LICENSE file.
//

#import "NSBundle+SRGAnalytics.h"

#import "SRGAnalyticsTracker.h"

#import <UIKit/UIKit.h>

@implementation NSBundle (SRGAnalytics)

+ (NSBundle *)srg_analyticsBundle
{
    static NSBundle *s_bundle;
    static dispatch_once_t s_once;
    dispatch_once(&s_once, ^{
        s_bundle = [NSBundle bundleForClass:[SRGAnalyticsTracker class]];
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
