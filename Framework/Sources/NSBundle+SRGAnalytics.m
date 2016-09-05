//
//  Copyright (c) SRG SSR. All rights reserved.
//
//  License information is available from the LICENSE file.
//

#import "NSBundle+RTSAnalytics.h"

#import "RTSAnalyticsTracker.h"

@implementation NSBundle (RTSAnalytics)

+ (instancetype)RTSAnalyticsBundle
{
    static NSBundle *bundle;
    static dispatch_once_t once;
    dispatch_once(&once, ^{
        bundle = [NSBundle bundleForClass:[RTSAnalyticsTracker class]];
    });
    return bundle;
}

@end
