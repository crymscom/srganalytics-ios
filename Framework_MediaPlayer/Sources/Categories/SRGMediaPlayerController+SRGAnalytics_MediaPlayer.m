//
//  Copyright (c) SRG SSR. All rights reserved.
//
//  License information is available from the LICENSE file.
//

#import "SRGMediaPlayerController+SRGAnalytics_MediaPlayer.h"

#import "SRGMediaPlayerTracker.h"

#import <objc/runtime.h>

static void *s_trackedKey = &s_trackedKey;
static void *s_analyticsPlayerNameKey = &s_analyticsPlayerNameKey;
static void *s_analyticsPlayerVersionKey = &s_analyticsPlayerVersionKey;


@implementation SRGMediaPlayerController (SRGAnalytics_MediaPlayer)

#pragma mark Class methods

+ (NSDictionary *)fullInfoWithAnalyticsLabels:(SRGAnalyticsStreamLabels *)analyticsLabels
                                     userInfo:(NSDictionary *)userInfo
{
    NSMutableDictionary *fullUserInfo = [NSMutableDictionary dictionary];
    fullUserInfo[SRGAnalyticsMediaPlayerLabelsKey] = [analyticsLabels copy];
    if (userInfo) {
        [fullUserInfo addEntriesFromDictionary:userInfo];
    }
    return [fullUserInfo copy];
}

#pragma mark Playback methods

- (void)prepareToPlayURL:(NSURL *)URL
                  atTime:(CMTime)time
            withSegments:(NSArray<id<SRGSegment>> *)segments
         analyticsLabels:(SRGAnalyticsStreamLabels *)analyticsLabels
                userInfo:(NSDictionary *)userInfo
       completionHandler:(void (^)(void))completionHandler
{
    NSDictionary *fullUserInfo = [SRGMediaPlayerController fullInfoWithAnalyticsLabels:analyticsLabels userInfo:userInfo];
    [self prepareToPlayURL:URL atTime:time withSegments:segments userInfo:fullUserInfo completionHandler:completionHandler];
}

- (void)playURL:(NSURL *)URL
         atTime:(CMTime)time
   withSegments:(NSArray<id<SRGSegment>> *)segments
analyticsLabels:(SRGAnalyticsStreamLabels *)analyticsLabels
       userInfo:(NSDictionary *)userInfo
{
    NSDictionary *fullUserInfo = [SRGMediaPlayerController fullInfoWithAnalyticsLabels:analyticsLabels userInfo:userInfo];
    [self playURL:URL atTime:time withSegments:segments userInfo:fullUserInfo];
}

- (void)prepareToPlayURL:(NSURL *)URL
                 atIndex:(NSInteger)index
              inSegments:(NSArray<id<SRGSegment>> *)segments
     withAnalyticsLabels:(SRGAnalyticsStreamLabels *)analyticsLabels
                userInfo:(NSDictionary *)userInfo
       completionHandler:(void (^)(void))completionHandler
{
    NSDictionary *fullUserInfo = [SRGMediaPlayerController fullInfoWithAnalyticsLabels:analyticsLabels userInfo:userInfo];
    [self prepareToPlayURL:URL atIndex:index inSegments:segments withUserInfo:fullUserInfo completionHandler:completionHandler];
}

- (void)playURL:(NSURL *)URL
        atIndex:(NSInteger)index
     inSegments:(NSArray<id<SRGSegment>> *)segments
withAnalyticsLabels:(SRGAnalyticsStreamLabels *)analyticsLabels
       userInfo:(NSDictionary *)userInfo
{
    NSDictionary *fullUserInfo = [SRGMediaPlayerController fullInfoWithAnalyticsLabels:analyticsLabels userInfo:userInfo];
    [self playURL:URL atIndex:index inSegments:segments withUserInfo:fullUserInfo];
}

#pragma mark Getters and setters

- (BOOL)isTracked
{
    NSNumber *isTracked = objc_getAssociatedObject(self, s_trackedKey);
    return isTracked ? [isTracked boolValue] : YES;
}

- (void)setTracked:(BOOL)tracked
{
    objc_setAssociatedObject(self, s_trackedKey, @(tracked), OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

- (NSString *)analyticsPlayerName
{
    NSString *analyticsPlayerName = objc_getAssociatedObject(self, s_analyticsPlayerNameKey);
    return analyticsPlayerName ?: @"SRGMediaPlayer";
}

- (void)setAnalyticsPlayerName:(NSString *)analyticsPlayerName
{
    if (!analyticsPlayerName) {
        analyticsPlayerName = @"SRGMediaPlayer";
    }
    objc_setAssociatedObject(self, s_analyticsPlayerNameKey, analyticsPlayerName, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

- (NSString *)analyticsPlayerVersion
{
    NSString *analyticsPlayerVersion = objc_getAssociatedObject(self, s_analyticsPlayerVersionKey);
    return analyticsPlayerVersion ?: SRGMediaPlayerMarketingVersion();
}

- (void)setAnalyticsPlayerVersion:(NSString *)analyticsPlayerVersion
{
    if (!analyticsPlayerVersion) {
        analyticsPlayerVersion = SRGMediaPlayerMarketingVersion();
    }
    objc_setAssociatedObject(self, s_analyticsPlayerVersionKey, analyticsPlayerVersion, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

- (SRGAnalyticsStreamLabels *)analyticsLabels
{
    return self.userInfo[SRGAnalyticsMediaPlayerLabelsKey];
}

- (void)setAnalyticsLabels:(SRGAnalyticsStreamLabels *)analyticsLabels
{
    NSMutableDictionary *userInfo = [self.userInfo mutableCopy] ?: [NSMutableDictionary dictionary];
    userInfo[SRGAnalyticsMediaPlayerLabelsKey] = analyticsLabels;
    self.userInfo = [userInfo copy];
}

@end
