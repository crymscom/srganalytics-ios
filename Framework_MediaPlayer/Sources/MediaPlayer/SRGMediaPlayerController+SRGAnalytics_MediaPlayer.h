//
//  Copyright (c) SRG SSR. All rights reserved.
//
//  License information is available from the LICENSE file.
//

#import <SRGMediaPlayer/SRGMediaPlayer.h>

NS_ASSUME_NONNULL_BEGIN

// Forward declarations
@protocol SRGAnalyticsMediaPlayerTrackingDelegate;

/**
 *  Stream measurement additions to SRGAnalytics, based on comScore StreamSense. The SRGAnalytics_MediaPlayer framework 
 *  is an optional SRGAnalytics companion framework which can be used to easily measure audio and video consumption in 
 *  applications powered by the SRGMediaPlayer library.
 *
 *  When playing a media, events will be automatically sent at appropriate times when the player state changes or
 *  when segments are being played.
 *
 *  ## Usage
 *
 *  Simply add `SRGAnalytics_MediaPlayer.framework` to your project (which should already contain the main
 *  `SRGAnalytics.framework` as well as `SRGMediaPlayer.framework` as dependencies).
 *
 *  The tracker itself must have been started before any measurements can take place (@see `SRGAnalyticsTracker`).
 * 
 *  By default, provided a tracker has been started, all media players are automatically tracked without any 
 *  additional work. You can disable this behavior by setting the `SRGMediaPlayerController` `tracked` property to NO.
 *  If you do not want any events to be emitted by a player, you should set this property to NO before beginning
 *  playback.
 *
 *  By default, standard SRG playback information (playhead position, type of event, etc.) is sent in stream events.
 *  To supply additional measurement information (e.g. title or duration), you must use custom labels.
 *
 *  ## Custom measurement labels
 *
 *  You can supply additional custom measurement labels with stream events sent from your application. Be careful
 *  when using custom labels, though, and ensure your custom keys do not match reserved values by using appropriate
 *  naming conventions (e.g. a prefix).
 *
 *  To supply custom measurement labels, specify a tracking delegate, conforming to the `SRGAnalyticsMediaPlayerTrackingDelegate`
 *  protocol, when calling one of the methods below. This tracking delegate requires two methods to be implemented,
 *  one for labels associated with the content, one for segment-specific labels.
 *
 *  When playing a segment, corresponding labels are merged with those associated with the content, overriding existing keys. 
 *  You can take advantage of this behavior to add segment information on top of content labels.
 */
@interface SRGMediaPlayerController (SRGAnalytics_MediaPlayer)

/**
 *  Same as `-[SRGMediaPlayerController prepareToPlayURL:atTime:withSegments:userInfo:completionHandler:]`, but with 
 *  optional tracking delegate
 *
 *  @param trackingDelegate The tracking delegate to use. The delegate is retained
 */
- (void)prepareToPlayURL:(NSURL *)URL
                  atTime:(CMTime)time
            withSegments:(nullable NSArray<id<SRGSegment>> *)segments
        trackingDelegate:(nullable id<SRGAnalyticsMediaPlayerTrackingDelegate>)trackingDelegate
                userInfo:(nullable NSDictionary *)userInfo completionHandler:(nullable void (^)(void))completionHandler;

/**
 *  Same as `-[SRGMediaPlayerController playURL:atTime:withSegments:userInfo:]`, but with optional tracking delegate
 *
 *  @param trackingDelegate The tracking delegate to use. The delegate is retained
 */
- (void)playURL:(NSURL *)URL
         atTime:(CMTime)time
   withSegments:(nullable NSArray<id<SRGSegment>> *)segments
trackingDelegate:(nullable id<SRGAnalyticsMediaPlayerTrackingDelegate>)trackingDelegate
       userInfo:(nullable NSDictionary *)userInfo;

/**
 *  Same as `-[SRGMediaPlayerController prepareToPlayURL:atIndex:inSegments:withUserInfo:completionHandler:]`, but with 
 *  optional tracking delegate
 *
 *  @param trackingDelegate The tracking delegate to use. The delegate is retained
 */
- (void)prepareToPlayURL:(NSURL *)URL
                 atIndex:(NSInteger)index
              inSegments:(NSArray<id<SRGSegment>> *)segments
    withTrackingDelegate:(nullable id<SRGAnalyticsMediaPlayerTrackingDelegate>)trackingDelegate
                userInfo:(nullable NSDictionary *)userInfo
       completionHandler:(nullable void (^)(void))completionHandler;

/**
 *  Same as `-[SRGMediaPlayerController playURL:atIndex:inSegments:withUserInfo:]`, but with optional tracking delegate
 *
 *  @param trackingDelegate The tracking delegate to use. The delegate is retained
 */
- (void)playURL:(NSURL *)URL
        atIndex:(NSInteger)index
     inSegments:(NSArray<id<SRGSegment>> *)segments
withTrackingDelegate:(nullable id<SRGAnalyticsMediaPlayerTrackingDelegate>)trackingDelegate
       userInfo:(nullable NSDictionary *)userInfo;

/**
 *  Set to NO to disable automatic player controller tracking. The default value is YES
 *
 *  @discussion Media players are tracked between the time they prepare a media for playback and the time they return to
 *              the idle state. You can start and stop tracking at any time, which will automatically send the required
 *              stream events. If you do not want to track a player at all, be sure that you set this property to NO
 *              before starting playback
 */
@property (nonatomic, getter=isTracked) BOOL tracked;

@end

/**
 *  Protocol through which custom labels can be provided during playback
 */
@protocol SRGAnalyticsMediaPlayerTrackingDelegate <NSObject>

/**
 *  Labels associated with the content being played
 */
- (nullable NSDictionary<NSString *, NSString *> *)contentLabels;

/**
 *  Labels associated with the segment being played
 *
 *  @param segment The segment for which segment labels can be supplied. This method is also called when no segment is
 *                 being played (i.e. segment is nil), which also lets you provide labels in such cases if you want
 */
- (nullable NSDictionary<NSString *, NSString *> *)labelsForSegment:(nullable id<SRGSegment>)segment;

@end

NS_ASSUME_NONNULL_END
