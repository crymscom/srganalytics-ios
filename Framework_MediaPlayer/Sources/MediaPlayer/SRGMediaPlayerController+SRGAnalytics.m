//
//  Copyright (c) SRG SSR. All rights reserved.
//
//  License information is available from the LICENSE file.
//

#import "SRGMediaPlayerController+SRGAnalytics.h"

#import "SRGMediaPlayerTracker.h"

#import <objc/runtime.h>

static void *SRGAnalyticsTrackedKey = &SRGAnalyticsTrackedKey;

@implementation SRGMediaPlayerController (SRGAnalytics)

#pragma mark Helpers

+ (NSDictionary *)fullInfoWithTrackingDelegate:(id<SRGAnalyticsMediaPlayerTrackingDelegate>)trackingDelegate userInfo:(NSDictionary *)userInfo
{
    NSMutableDictionary *fullUserInfo = [NSMutableDictionary dictionary];
    if (trackingDelegate) {
        fullUserInfo[SRGAnalyticsMediaPlayerTrackingDelegateKey] = trackingDelegate;
    }
    if (userInfo) {
        [fullUserInfo addEntriesFromDictionary:userInfo];
    }
    return [fullUserInfo copy];
}

#pragma mark Playback methods

- (void)prepareToPlayURL:(NSURL *)URL
                  atTime:(CMTime)time
            withSegments:(NSArray<id<SRGSegment>> *)segments
        trackingDelegate:(id<SRGAnalyticsMediaPlayerTrackingDelegate>)trackingDelegate
                userInfo:(NSDictionary *)userInfo
       completionHandler:(void (^)(void))completionHandler
{
    NSDictionary *fullUserInfo = [SRGMediaPlayerController fullInfoWithTrackingDelegate:trackingDelegate userInfo:userInfo];
    [self prepareToPlayURL:URL atTime:time withSegments:segments userInfo:fullUserInfo completionHandler:completionHandler];
}

- (void)playURL:(NSURL *)URL
         atTime:(CMTime)time
   withSegments:(NSArray<id<SRGSegment>> *)segments
trackingDelegate:(id<SRGAnalyticsMediaPlayerTrackingDelegate>)trackingDelegate
       userInfo:(NSDictionary *)userInfo
{
    NSDictionary *fullUserInfo = [SRGMediaPlayerController fullInfoWithTrackingDelegate:trackingDelegate userInfo:userInfo];
    [self playURL:URL atTime:time withSegments:segments userInfo:fullUserInfo];
}

- (void)prepareToPlayURL:(NSURL *)URL
                 atIndex:(NSInteger)index
              inSegments:(NSArray<id<SRGSegment>> *)segments
    withTrackingDelegate:(id<SRGAnalyticsMediaPlayerTrackingDelegate>)trackingDelegate
                userInfo:(NSDictionary *)userInfo
       completionHandler:(void (^)(void))completionHandler
{
    NSDictionary *fullUserInfo = [SRGMediaPlayerController fullInfoWithTrackingDelegate:trackingDelegate userInfo:userInfo];
    [self prepareToPlayURL:URL atIndex:index inSegments:segments withUserInfo:fullUserInfo completionHandler:completionHandler];
}

- (void)playURL:(NSURL *)URL
        atIndex:(NSInteger)index
     inSegments:(NSArray<id<SRGSegment>> *)segments
withTrackingDelegate:(id<SRGAnalyticsMediaPlayerTrackingDelegate>)trackingDelegate
       userInfo:(NSDictionary *)userInfo
{
    NSDictionary *fullUserInfo = [SRGMediaPlayerController fullInfoWithTrackingDelegate:trackingDelegate userInfo:userInfo];
    [self playURL:URL atIndex:index inSegments:segments withUserInfo:fullUserInfo];
}

#pragma mark Getters and setters

- (BOOL)isTracked
{
    NSNumber *isTracked = objc_getAssociatedObject(self, SRGAnalyticsTrackedKey);
    return isTracked ? [isTracked boolValue] : YES;
}

- (void)setTracked:(BOOL)tracked
{
    objc_setAssociatedObject(self, SRGAnalyticsTrackedKey, @(tracked), OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

@end
