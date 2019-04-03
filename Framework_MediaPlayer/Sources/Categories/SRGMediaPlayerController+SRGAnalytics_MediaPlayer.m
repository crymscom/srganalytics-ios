//
//  Copyright (c) SRG SSR. All rights reserved.
//
//  License information is available from the LICENSE file.
//

#import "SRGMediaPlayerController+SRGAnalytics_MediaPlayer.h"

#import "SRGMediaAnalytics.h"
#import "SRGMediaPlayerTracker.h"

#import <objc/runtime.h>

static void *s_trackedKey = &s_trackedKey;

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
              atPosition:(SRGPosition *)position
            withSegments:(NSArray<id<SRGSegment>> *)segments
         analyticsLabels:(SRGAnalyticsStreamLabels *)analyticsLabels
                userInfo:(NSDictionary *)userInfo
       completionHandler:(void (^)(void))completionHandler
{
    NSDictionary *fullUserInfo = [SRGMediaPlayerController fullInfoWithAnalyticsLabels:analyticsLabels userInfo:userInfo];
    [self prepareToPlayURL:URL atPosition:position withSegments:segments userInfo:fullUserInfo completionHandler:completionHandler];
}

- (void)prepareToPlayItem:(AVPlayerItem *)item
               atPosition:(SRGPosition *)position
             withSegments:(NSArray<id<SRGSegment>> *)segments
          analyticsLabels:(SRGAnalyticsStreamLabels *)analyticsLabels
                 userInfo:(NSDictionary *)userInfo
        completionHandler:(void (^)(void))completionHandler
{
    NSDictionary *fullUserInfo = [SRGMediaPlayerController fullInfoWithAnalyticsLabels:analyticsLabels userInfo:userInfo];
    [self prepareToPlayItem:item atPosition:position withSegments:segments userInfo:fullUserInfo completionHandler:completionHandler];
}

- (void)playURL:(NSURL *)URL
     atPosition:(SRGPosition *)position
   withSegments:(NSArray<id<SRGSegment>> *)segments
analyticsLabels:(SRGAnalyticsStreamLabels *)analyticsLabels
       userInfo:(NSDictionary *)userInfo
{
    NSDictionary *fullUserInfo = [SRGMediaPlayerController fullInfoWithAnalyticsLabels:analyticsLabels userInfo:userInfo];
    [self playURL:URL atPosition:position withSegments:segments userInfo:fullUserInfo];
}

- (void)playItem:(AVPlayerItem *)item
      atPosition:(SRGPosition *)position
    withSegments:(NSArray<id<SRGSegment>> *)segments
 analyticsLabels:(SRGAnalyticsStreamLabels *)analyticsLabels
        userInfo:(NSDictionary *)userInfo
{
    NSDictionary *fullUserInfo = [SRGMediaPlayerController fullInfoWithAnalyticsLabels:analyticsLabels userInfo:userInfo];
    [self playItem:item atPosition:position withSegments:segments userInfo:fullUserInfo];
}

- (void)prepareToPlayURL:(NSURL *)URL
                 atIndex:(NSInteger)index
                position:(SRGPosition *)position
              inSegments:(NSArray<id<SRGSegment>> *)segments
     withAnalyticsLabels:(SRGAnalyticsStreamLabels *)analyticsLabels
                userInfo:(NSDictionary *)userInfo
       completionHandler:(void (^)(void))completionHandler
{
    NSDictionary *fullUserInfo = [SRGMediaPlayerController fullInfoWithAnalyticsLabels:analyticsLabels userInfo:userInfo];
    [self prepareToPlayURL:URL atIndex:index position:position inSegments:segments withUserInfo:fullUserInfo completionHandler:completionHandler];
}

- (void)prepareToPlayItem:(AVPlayerItem *)item
                  atIndex:(NSInteger)index
                 position:(SRGPosition *)position
               inSegments:(NSArray<id<SRGSegment>> *)segments
      withAnalyticsLabels:(SRGAnalyticsStreamLabels *)analyticsLabels
                 userInfo:(NSDictionary *)userInfo
        completionHandler:(void (^)(void))completionHandler
{
    NSDictionary *fullUserInfo = [SRGMediaPlayerController fullInfoWithAnalyticsLabels:analyticsLabels userInfo:userInfo];
    [self prepareToPlayItem:item atIndex:index position:position inSegments:segments withUserInfo:fullUserInfo completionHandler:completionHandler];
}

- (void)playURL:(NSURL *)URL
        atIndex:(NSInteger)index
       position:(SRGPosition *)position
     inSegments:(NSArray<id<SRGSegment>> *)segments
withAnalyticsLabels:(SRGAnalyticsStreamLabels *)analyticsLabels
       userInfo:(NSDictionary *)userInfo
{
    NSDictionary *fullUserInfo = [SRGMediaPlayerController fullInfoWithAnalyticsLabels:analyticsLabels userInfo:userInfo];
    [self playURL:URL atIndex:index position:position inSegments:segments withUserInfo:fullUserInfo];
}

- (void)playItem:(AVPlayerItem *)item
         atIndex:(NSInteger)index
        position:(SRGPosition *)position
      inSegments:(NSArray<id<SRGSegment>> *)segments
withAnalyticsLabels:(SRGAnalyticsStreamLabels *)analyticsLabels
        userInfo:(NSDictionary *)userInfo
{
    NSDictionary *fullUserInfo = [SRGMediaPlayerController fullInfoWithAnalyticsLabels:analyticsLabels userInfo:userInfo];
    [self playItem:item atIndex:index position:position inSegments:segments withUserInfo:fullUserInfo];
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
