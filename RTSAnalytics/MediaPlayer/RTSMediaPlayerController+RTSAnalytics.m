//
//  Copyright (c) SRG SSR. All rights reserved.
//
//  License information is available from the LICENSE file.
//

#import "RTSMediaPlayerController+RTSAnalytics.h"
#import "RTSMediaPlayerControllerTracker_private.h"
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
    BOOL prevTracked = self.tracked;
    if (tracked == prevTracked) {
        return;
    }
    
    objc_setAssociatedObject(self, RTSAnalyticsTrackedKey, @(tracked), OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    
    if (tracked) {
        [[RTSMediaPlayerControllerTracker sharedTracker] startTrackingMediaPlayerController:self];
    }
    else {
        [[RTSMediaPlayerControllerTracker sharedTracker] stopTrackingMediaPlayerController:self];
    }
}

@end
