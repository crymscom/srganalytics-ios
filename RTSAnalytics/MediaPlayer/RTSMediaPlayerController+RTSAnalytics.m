//
//  Copyright (c) SRG. All rights reserved.
//
//  License information is available from the LICENSE file.
//

#import "RTSMediaPlayerController+RTSAnalytics.h"

#import <objc/runtime.h>

static void *RTSAnalyticsTrackedKey = &RTSAnalyticsTrackedKey;

@implementation RTSMediaPlayerController (RTSAnalytics)

- (BOOL)isTracked
{
    NSNumber *isTracked = objc_getAssociatedObject(self, RTSAnalyticsTrackedKey);
    return isTracked ? [isTracked boolValue] : YES;
}

- (void)setTracked:(BOOL)tracked
{
    objc_setAssociatedObject(self, RTSAnalyticsTrackedKey, @(tracked), OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

@end
