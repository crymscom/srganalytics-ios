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
     withToleranceBefore:(CMTime)toleranceBefore
          toleranceAfter:(CMTime)toleranceAfter
                segments:(NSArray<id<SRGSegment>> *)segments
         analyticsLabels:(SRGAnalyticsStreamLabels *)analyticsLabels
                userInfo:(NSDictionary *)userInfo
       completionHandler:(void (^)(void))completionHandler
{
    NSDictionary *fullUserInfo = [SRGMediaPlayerController fullInfoWithAnalyticsLabels:analyticsLabels userInfo:userInfo];
    [self prepareToPlayURL:URL atTime:time withToleranceBefore:toleranceBefore toleranceAfter:toleranceAfter segments:segments userInfo:fullUserInfo completionHandler:completionHandler];
}

- (void)prepareToPlayItem:(AVPlayerItem *)item
                   atTime:(CMTime)time
      withToleranceBefore:(CMTime)toleranceBefore
           toleranceAfter:(CMTime)toleranceAfter
                 segments:(NSArray<id<SRGSegment>> *)segments
          analyticsLabels:(SRGAnalyticsStreamLabels *)analyticsLabels
                 userInfo:(NSDictionary *)userInfo
        completionHandler:(void (^)(void))completionHandler
{
    NSDictionary *fullUserInfo = [SRGMediaPlayerController fullInfoWithAnalyticsLabels:analyticsLabels userInfo:userInfo];
    [self prepareToPlayItem:item atTime:time withToleranceBefore:toleranceBefore toleranceAfter:toleranceAfter segments:segments userInfo:fullUserInfo completionHandler:completionHandler];
}

- (void)playURL:(NSURL *)URL
         atTime:(CMTime)time
withToleranceBefore:(CMTime)toleranceBefore
 toleranceAfter:(CMTime)toleranceAfter
       segments:(NSArray<id<SRGSegment>> *)segments
analyticsLabels:(SRGAnalyticsStreamLabels *)analyticsLabels
       userInfo:(NSDictionary *)userInfo
{
    NSDictionary *fullUserInfo = [SRGMediaPlayerController fullInfoWithAnalyticsLabels:analyticsLabels userInfo:userInfo];
    [self playURL:URL atTime:time withToleranceBefore:toleranceBefore toleranceAfter:toleranceAfter segments:segments userInfo:fullUserInfo];
}

- (void)playItem:(AVPlayerItem *)item
          atTime:(CMTime)time
withToleranceBefore:(CMTime)toleranceBefore
  toleranceAfter:(CMTime)toleranceAfter
        segments:(NSArray<id<SRGSegment>> *)segments
 analyticsLabels:(SRGAnalyticsStreamLabels *)analyticsLabels
        userInfo:(NSDictionary *)userInfo
{
    NSDictionary *fullUserInfo = [SRGMediaPlayerController fullInfoWithAnalyticsLabels:analyticsLabels userInfo:userInfo];
    [self playItem:item atTime:time withToleranceBefore:toleranceBefore toleranceAfter:toleranceAfter segments:segments userInfo:fullUserInfo];
}

- (void)prepareToPlayURL:(NSURL *)URL
                 atIndex:(NSInteger)index
                    time:(CMTime)time
              inSegments:(NSArray<id<SRGSegment>> *)segments
     withToleranceBefore:(CMTime)toleranceBefore
          toleranceAfter:(CMTime)toleranceAfter
         analyticsLabels:(SRGAnalyticsStreamLabels *)analyticsLabels
                userInfo:(NSDictionary *)userInfo
       completionHandler:(void (^)(void))completionHandler
{
    NSDictionary *fullUserInfo = [SRGMediaPlayerController fullInfoWithAnalyticsLabels:analyticsLabels userInfo:userInfo];
    [self prepareToPlayURL:URL atIndex:index time:time inSegments:segments withToleranceBefore:toleranceBefore toleranceAfter:toleranceAfter userInfo:fullUserInfo completionHandler:completionHandler];
}

- (void)prepareToPlayItem:(AVPlayerItem *)item
                  atIndex:(NSInteger)index
                     time:(CMTime)time
               inSegments:(NSArray<id<SRGSegment>> *)segments
      withToleranceBefore:(CMTime)toleranceBefore
           toleranceAfter:(CMTime)toleranceAfter
          analyticsLabels:(SRGAnalyticsStreamLabels *)analyticsLabels
                 userInfo:(NSDictionary *)userInfo
        completionHandler:(void (^)(void))completionHandler
{
    NSDictionary *fullUserInfo = [SRGMediaPlayerController fullInfoWithAnalyticsLabels:analyticsLabels userInfo:userInfo];
    [self prepareToPlayItem:item atIndex:index time:time inSegments:segments withToleranceBefore:toleranceBefore toleranceAfter:toleranceAfter userInfo:fullUserInfo completionHandler:completionHandler];
}

- (void)playURL:(NSURL *)URL
        atIndex:(NSInteger)index
           time:(CMTime)time
     inSegments:(NSArray<id<SRGSegment>> *)segments
withToleranceBefore:(CMTime)toleranceBefore
 toleranceAfter:(CMTime)toleranceAfter
analyticsLabels:(SRGAnalyticsStreamLabels *)analyticsLabels
       userInfo:(NSDictionary *)userInfo
{
    NSDictionary *fullUserInfo = [SRGMediaPlayerController fullInfoWithAnalyticsLabels:analyticsLabels userInfo:userInfo];
    [self playURL:URL atIndex:index time:time inSegments:segments withToleranceBefore:toleranceBefore toleranceAfter:toleranceAfter userInfo:fullUserInfo];
}

- (void)playItem:(AVPlayerItem *)item
         atIndex:(NSInteger)index
            time:(CMTime)time
      inSegments:(NSArray<id<SRGSegment>> *)segments
withToleranceBefore:(CMTime)toleranceBefore
  toleranceAfter:(CMTime)toleranceAfter
 analyticsLabels:(SRGAnalyticsStreamLabels *)analyticsLabels
        userInfo:(NSDictionary *)userInfo
{
    NSDictionary *fullUserInfo = [SRGMediaPlayerController fullInfoWithAnalyticsLabels:analyticsLabels userInfo:userInfo];
    [self playItem:item atIndex:index time:time inSegments:segments withToleranceBefore:toleranceBefore toleranceAfter:toleranceAfter userInfo:fullUserInfo];
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
    objc_setAssociatedObject(self, s_analyticsPlayerNameKey, analyticsPlayerName, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

- (NSString *)analyticsPlayerVersion
{
    NSString *analyticsPlayerVersion = objc_getAssociatedObject(self, s_analyticsPlayerVersionKey);
    return analyticsPlayerVersion ?: SRGMediaPlayerMarketingVersion();
}

- (void)setAnalyticsPlayerVersion:(NSString *)analyticsPlayerVersion
{
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
