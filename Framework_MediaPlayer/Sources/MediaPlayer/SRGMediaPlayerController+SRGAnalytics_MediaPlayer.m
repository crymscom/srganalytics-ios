//
//  Copyright (c) SRG SSR. All rights reserved.
//
//  License information is available from the LICENSE file.
//

#import "SRGMediaPlayerController+SRGAnalytics_MediaPlayer.h"

#import "SRGMediaPlayerTracker.h"

#import <objc/runtime.h>

static void *SRGAnalyticsTrackedKey = &SRGAnalyticsTrackedKey;

@implementation SRGMediaPlayerController (SRGAnalytics_MediaPlayer)

#pragma mark Helpers

+ (NSDictionary *)fullInfoWithAnalyticsLabels:(NSDictionary<NSString *, NSString *> *)analyticsLabels
                      comScoreAnalyticsLabels:(NSDictionary<NSString *, NSString *> *)comScoreAnalyticsLabels
                                     userInfo:(NSDictionary *)userInfo
{
    NSMutableDictionary *fullUserInfo = [NSMutableDictionary dictionary];
    if (analyticsLabels) {
        fullUserInfo[SRGAnalyticsMediaPlayerLabelsKey] = analyticsLabels;
    }
    if (comScoreAnalyticsLabels) {
        fullUserInfo[SRGAnalyticsMediaPlayerComScoreLabelsKey] = comScoreAnalyticsLabels;
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
         analyticsLabels:(NSDictionary *)analyticsLabels
 comScoreAnalyticsLabels:(NSDictionary *)comScoreAnalyticsLabels
                userInfo:(NSDictionary *)userInfo
       completionHandler:(void (^)(void))completionHandler
{
    NSDictionary *fullUserInfo = [SRGMediaPlayerController fullInfoWithAnalyticsLabels:analyticsLabels comScoreAnalyticsLabels:comScoreAnalyticsLabels userInfo:userInfo];
    [self prepareToPlayURL:URL atTime:time withSegments:segments userInfo:fullUserInfo completionHandler:completionHandler];
}

- (void)playURL:(NSURL *)URL
         atTime:(CMTime)time
   withSegments:(NSArray<id<SRGSegment>> *)segments
analyticsLabels:(NSDictionary *)analyticsLabels
comScoreAnalyticsLabels:(NSDictionary *)comScoreAnalyticsLabels
       userInfo:(NSDictionary *)userInfo
{
    NSDictionary *fullUserInfo = [SRGMediaPlayerController fullInfoWithAnalyticsLabels:analyticsLabels comScoreAnalyticsLabels:comScoreAnalyticsLabels userInfo:userInfo];
    [self playURL:URL atTime:time withSegments:segments userInfo:fullUserInfo];
}

- (void)prepareToPlayURL:(NSURL *)URL
                 atIndex:(NSInteger)index
              inSegments:(NSArray<id<SRGSegment>> *)segments
     withAnalyticsLabels:(NSDictionary *)analyticsLabels
 comScoreAnalyticsLabels:(NSDictionary *)comScoreAnalyticsLabels
                userInfo:(NSDictionary *)userInfo
       completionHandler:(void (^)(void))completionHandler
{
    NSDictionary *fullUserInfo = [SRGMediaPlayerController fullInfoWithAnalyticsLabels:analyticsLabels comScoreAnalyticsLabels:comScoreAnalyticsLabels userInfo:userInfo];
    [self prepareToPlayURL:URL atIndex:index inSegments:segments withUserInfo:fullUserInfo completionHandler:completionHandler];
}

- (void)playURL:(NSURL *)URL
        atIndex:(NSInteger)index
     inSegments:(NSArray<id<SRGSegment>> *)segments
withAnalyticsLabels:(NSDictionary *)analyticsLabels
comScoreAnalyticsLabels:(NSDictionary *)comScoreAnalyticsLabels
       userInfo:(NSDictionary *)userInfo
{
    NSDictionary *fullUserInfo = [SRGMediaPlayerController fullInfoWithAnalyticsLabels:analyticsLabels comScoreAnalyticsLabels:comScoreAnalyticsLabels userInfo:userInfo];
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
