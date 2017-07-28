//
//  Copyright (c) SRG SSR. All rights reserved.
//
//  License information is available from the LICENSE file.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

/**
 *  @name Media player events
 */
typedef NS_ENUM(NSInteger, SRGAnalyticsPlayerEvent) {
    /**
     *  The player started buffering.
     */
    SRGAnalyticsPlayerEventBuffer,
    /**
     *  Playback started or resumed.
     */
    SRGAnalyticsPlayerEventPlay,
    /**
     *  Playback was paused.
     */
    SRGAnalyticsPlayerEventPause,
    /**
     *  The player started seeking.
     */
    SRGAnalyticsPlayerEventSeek,
    /**
     *  The player was stopped.
     */
    SRGAnalyticsPlayerEventStop,
    /**
     *  Playback ended normally.
     */
    SRGAnalyticsPlayerEventEnd,
    /**
     *  Heartbeat (VOD).
     */
    SRGAnalyticsPlayerEventHeartbeat,
    /**
     *  Live hearbeat (send when live only).
     */
    SRGAnalyticsPlayerEventLiveHeartbeat
};

/**
 *  Tracker for media playback consumption. This tracker ensures that the media analytics event sequences are always
 *  reliable, guaranteeing correct measurements.
 */
@interface SRGAnalyticsPlayerTracker : NSObject

/**
 *  Track a media player event.
 *
 *  @param event                 The event type.
 *  @param position              The playback position at which the event occurs, in milliseconds.
 *  @param labels                Additional custom labels.
 *  @param comScoreLabels        Custom comScore information to be sent along the event and which is meaningful for your application
 *                               measurements.
 *  @param comScoreSegmentLabels Custom comScore segment information to be sent along the event and which is meaningful to your application
 *                               measurements.
 *
 *  @discussion Be careful when using custom labels and ensure your custom keys do not match reserved values by
 *              using appropriate naming conventions (e.g. a prefix).
 */
- (void)trackPlayerEvent:(SRGAnalyticsPlayerEvent)event
              atPosition:(NSTimeInterval)position
              withLabels:(nullable NSDictionary<NSString *, NSString *> *)labels
          comScoreLabels:(nullable NSDictionary<NSString *, NSString *> *)comScoreLabels
   comScoreSegmentLabels:(nullable NSDictionary<NSString *, NSString *> *)comScoreSegmentLabels;

@end

NS_ASSUME_NONNULL_END
