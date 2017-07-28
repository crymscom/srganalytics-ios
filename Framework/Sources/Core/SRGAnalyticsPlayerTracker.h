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
 *  Additional media playback measurement labels.
 */
@interface SRGAnalyticsPlayerTrackerLabels : NSObject

/**
 *  The media player display name, e.g. "AVPlayer" if you are using `AVPlayer` directly.
 */
@property (nonatomic, copy, nullable) NSString *playerName;

/**
 *  The media player version.
 */
@property (nonatomic, copy, nullable) NSString *playerVersion;

/**
 *  Set to @YES iff subtitles are enabled at the time the measurement is made.
 */
@property (nonatomic, nullable) NSNumber *subtitlesEnabled;             // BOOL

/**
 *  Set to the current positive shift from live conditions, in milliseconds. Must be 0 for live streams without timeshift support, 
 *  and `nil` for on-demand streams.
 */
@property (nonatomic, nullable) NSNumber *timeshiftInMilliseconds;      // Long

/**
 *  The current bandwidth in bits per second.
 */
@property (nonatomic, nullable) NSNumber *bandwidthInBitsPerSecond;     // Long

/**
 *  The volume, on a scale from 0 to 100.
 */
@property (nonatomic, nullable) NSNumber *volumeInPercent;              // Long

/**
 *  Additional custom labels. See https://srfmmz.atlassian.net/wiki/spaces/INTFORSCHUNG/pages/197019081 for a full list.
 *  You should only set very specific information which does not override official labels provided above.
 *
 *  @discussion If those labels are not defined on the TagCommander portal, they won't be saved. If you override one of the above
 *              official labels in the process, the result is undefined.
 */
@property (nonatomic, nullable) NSDictionary<NSString *, NSString *> *customValues;

@end

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
 *  @param labels                Additional detailed event information.
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
              withLabels:(nullable SRGAnalyticsPlayerTrackerLabels *)labels
          comScoreLabels:(nullable NSDictionary<NSString *, NSString *> *)comScoreLabels
   comScoreSegmentLabels:(nullable NSDictionary<NSString *, NSString *> *)comScoreSegmentLabels;

@end

NS_ASSUME_NONNULL_END
