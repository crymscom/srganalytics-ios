//
//  Copyright (c) SRG SSR. All rights reserved.
//
//  License information is available from the LICENSE file.
//

#import "SRGMediaPlayerController+SRGAnalytics.h"
#import "SRGMediaPlayerControllerTracker.h"
#import <objc/runtime.h>

static NSMutableDictionary *s_identifierForURL;

static void *SRGAnalyticsIdentifierKey = &SRGAnalyticsIdentifierKey;
static void *SRGAnalyticsTrackedKey = &SRGAnalyticsTrackedKey;

@implementation SRGMediaPlayerController (SRGAnalytics)

+ (void)prepareToplayURL:(NSURL *)URL withIdentifier:(NSString *)identifier
{
    if (!s_identifierForURL) {
        s_identifierForURL = [NSMutableDictionary dictionary];
    }
    s_identifierForURL[URL] = identifier;
}

- (NSString *)identifier
{
//    NSString *identifier = objc_getAssociatedObject(self, SRGAnalyticsIdentifierKey);
//    return identifier;
    return s_identifierForURL[self.contentURL];
}

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
    
    if (tracked) {
        [[SRGMediaPlayerControllerTracker sharedTracker] startTrackingMediaPlayerController:self];
    }
    else {
        [[SRGMediaPlayerControllerTracker sharedTracker] stopTrackingMediaPlayerController:self];
    }
}

- (void)prepareToPlayIdentifier:(NSString *)identifier withURL:(NSURL *)URL atTime:(CMTime)startTime withSegments:(NSArray<id<SRGSegment>> *)segments completionHandler:(void (^)(void))completionHandler
{
//    [self reset];
//    self.identifier = identifier;
//    [self prepareToPlayURL:URL atTime:startTime withSegments:segments completionHandler:completionHandler];
}


@end
