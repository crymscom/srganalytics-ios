//
//  Copyright (c) SRG SSR. All rights reserved.
//
//  License information is available from the LICENSE file.
//

#import <SRGMediaPlayer/SRGMediaPlayer.h>
#import "SRGAnalyticsMediaPlayerConstants.h"

NS_ASSUME_NONNULL_BEGIN

@interface SRGMediaPlayerController (SRGAnalytics)

- (void)prepareToPlayURL:(NSURL *)URL atTime:(CMTime)time withSegments:(nullable NSArray<id<SRGSegment>> *)segments analyticsInfo:(nullable NSDictionary *)analyticsInfo userInfo:(nullable NSDictionary *)userInfo completionHandler:(nullable void (^)(void))completionHandler;
- (void)playURL:(NSURL *)URL atTime:(CMTime)time withSegments:(nullable NSArray<id<SRGSegment>> *)segments analyticsInfo:(nullable NSDictionary *)analyticsInfo userInfo:(nullable NSDictionary *)userInfo;

- (void)prepareToPlayURL:(NSURL *)URL atIndex:(NSInteger)index inSegments:(NSArray<id<SRGSegment>> *)segments withAnalyticsInfo:(nullable NSDictionary *)analyticsInfo userInfo:(nullable NSDictionary *)userInfo completionHandler:(nullable void (^)(void))completionHandler;
- (void)playURL:(NSURL *)URL atIndex:(NSInteger)index inSegments:(NSArray<id<SRGSegment>> *)segments withAnalyticsInfo:(nullable NSDictionary *)analyticsInfo userInfo:(nullable NSDictionary *)userInfo;

/**
 *  Allow SRGAnalytics to track media player states. By defaut, YES.
 */
@property (nonatomic, getter=isTracked) BOOL tracked;

@end

NS_ASSUME_NONNULL_END
