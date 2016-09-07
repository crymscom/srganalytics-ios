//
//  Copyright (c) SRG SSR. All rights reserved.
//
//  License information is available from the LICENSE file.
//

#import "SRGMediaPlayerController+SRGAnalytics.h"

#import "SRGMediaPlayerControllerTracker.h"
#import <objc/runtime.h>

NSString * const SRGAnalyticsIdentifierInfoKey = @"SRGAnalyticsIdentifierInfoKey";

static void *SRGAnalyticsTrackedKey = &SRGAnalyticsTrackedKey;

@implementation SRGMediaPlayerController (SRGAnalytics)

- (BOOL)isTracked
{
    NSNumber *isTracked = objc_getAssociatedObject(self, SRGAnalyticsTrackedKey);
    return isTracked ? [isTracked boolValue] : YES;
}

- (void)setTracked:(BOOL)tracked
{
    BOOL prevTracked = self.tracked;
    if (tracked == prevTracked) {
        return;
    }
    
    objc_setAssociatedObject(self, SRGAnalyticsTrackedKey, @(tracked), OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    
    NSString *identifier = self.userInfo[SRGAnalyticsIdentifierInfoKey];
    if (tracked) {
        [[SRGMediaPlayerControllerTracker sharedTracker] startTrackingMediaPlayerController:self forIdentifier:identifier];
    }
    else {
        [[SRGMediaPlayerControllerTracker sharedTracker] stopTrackingMediaPlayerControllerForIdentifier:identifier];
    }
}

@end
