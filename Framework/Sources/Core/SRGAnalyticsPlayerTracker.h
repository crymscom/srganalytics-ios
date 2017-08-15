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
     *  The player was stopped (interrupting playback).
     */
    SRGAnalyticsPlayerEventStop,
    /**
     *  Playback ended normally.
     */
    SRGAnalyticsPlayerEventEnd,
    /**
     *  Normal heartbeat.
     */
    SRGAnalyticsPlayerEventHeartbeat,
    /**
     *  Live hearbeat (to be sent when playing in live conditions only).
     */
    SRGAnalyticsPlayerEventLiveHeartbeat
};

/**
 *  Additional playback measurement labels.
 */
@interface SRGAnalyticsPlayerLabels : NSObject <NSCopying>

/**
 *  The media player display name, e.g. "AVPlayer" if you are using `AVPlayer` directly.
 */
@property (nonatomic, copy, nullable) NSString *playerName;

/**
 *  The media player version.
 */
@property (nonatomic, copy, nullable) NSString *playerVersion;

/**
 *  Set to `@YES` iff subtitles are enabled at the time the measurement is made.
 */
@property (nonatomic, nullable) NSNumber *subtitlesEnabled;             // BOOL

/**
 *  Set to the current positive shift from live conditions, in milliseconds. Must be 0 for live streams without timeshift 
 *  support, and `nil` for on-demand streams.
 */
@property (nonatomic, nullable) NSNumber *timeshiftInMilliseconds;      // Long

/**
 *  The current bandwidth in bits per second.
 */
@property (nonatomic, nullable) NSNumber *bandwidthInBitsPerSecond;     // Long

/**
 *  The volume of the player, on a scale from 0 to 100.
 *
 *  @discussion As the name suggests, this value must represent the volume of the player. If the player is not started or 
 *              muted, this value must be set to 0.
 */
@property (nonatomic, nullable) NSNumber *playerVolumeInPercent;        // Long

/**
 *  Additional custom information, mapping variables to values. See https://srfmmz.atlassian.net/wiki/spaces/INTFORSCHUNG/pages/197019081 
 *  for a full list of possible variable names.
 *
 *  You should rarely need to provide custom information with measurements, as this requires the variable name to be
 *  declared on TagCommander portal first (otherwise the associated value will be discarded).
 */
@property (nonatomic, nullable) NSDictionary<NSString *, NSString *> *customInfo;

/**
 *  Additional custom information to be sent to comScore. See https://srfmmz.atlassian.net/wiki/spaces/SRGPLAY/pages/36077617/Measurement+of+SRG+Player+Apps
 *  for a full list of possible variable names.
 *
 *  @discussion This information is sent in Stream Sense.
 */
@property (nonatomic, nullable) NSDictionary<NSString *, NSString *> *comScoreCustomInfo;

/**
 *  Additional custom segment information to be sent to comScore. See https://srfmmz.atlassian.net/wiki/spaces/SRGPLAY/pages/36077617/Measurement+of+SRG+Player+Apps
 *  for a full list of possible variable names.
 *
 *  @discussion This information is sent in StreamSense clips.
 */
@property (nonatomic, nullable) NSDictionary<NSString *, NSString *> *comScoreCustomSegmentInfo;

/**
 *  Merge the receiver with the provided labels (overriding values defined by it, otherwise keeping available ones).
 *  Use this method when you need to override full-length labels with more specific segment labels (use `-copy` to
 *  start with a copy if you don't want to preserve the original values for later).
 *
 *  @discussion Custom value dictionaries are merged as well.
 */
- (void)mergeWithLabels:(nullable SRGAnalyticsPlayerLabels *)labels;

@end

/**
 *  Tracker for media playback consumption. This tracker ensures that the media analytics event sequences are always
 *  reliable, guaranteeing correct measurements.
 *
 *  When you need to track a new media playback, simply instantiate an `SRGAnalyticsPlayerTracker`, keeping a strong
 *  reference to it, and call the tracking method when you need to record an event.
 *
 *  Implementing media player tracking is tricky to get right, and should only be required if your player is not based
 *  on SRG MediaPlayer (e.g. if you use `AVPlayer` directly). Please refer to the official documentation more information:
 *    https://srfmmz.atlassian.net/wiki/spaces/INTFORSCHUNG/pages/195595938/Implementation+Concept+-+draft
 */
@interface SRGAnalyticsPlayerTracker : NSObject

/**
 *  Track a media player event.
 *
 *  @param event    The event type.
 *  @param position The playback position at which the event occurs, in milliseconds.
 *  @param labels   Additional detailed event information.
 *
 *  @discussion Depending on the service, calling this method might not always lead to an associated event. The possibility
 *              of emitting an event might namely be constrained by the event which was emitted before it (if any). For
 *              more information, refer to the official documentation.
 */
- (void)trackPlayerEvent:(SRGAnalyticsPlayerEvent)event
              atPosition:(NSTimeInterval)position
              withLabels:(nullable SRGAnalyticsPlayerLabels *)labels;

@end

NS_ASSUME_NONNULL_END
