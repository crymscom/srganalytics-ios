//
//  Copyright (c) SRG SSR. All rights reserved.
//
//  License information is available from the LICENSE file.
//

#import "NSBundle+SRGAnalytics.h"

#import "SRGAnalyticsTracker.h"

@implementation NSBundle (SRGAnalytics)

+ (instancetype)SRGAnalyticsBundle
{
    static NSBundle *bundle;
    static dispatch_once_t once;
    dispatch_once(&once, ^{
        bundle = [NSBundle bundleForClass:[SRGAnalyticsTracker class]];
    });
    return bundle;
}

@end
