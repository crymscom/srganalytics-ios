//
//  Copyright (c) SRG SSR. All rights reserved.
//
//  License information is available from the LICENSE file.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

// Forward declarations
@class SRGAnalyticsStreamTracker;

/**
 *  @name Stream states
 */
typedef NS_ENUM(NSInteger, SRGAnalyticsStreamState) {
    /**
     *  The stream is currently being played.
     */
    SRGAnalyticsStreamStatePlaying = 1,
    /**
     *  Stream playback is paused.
     */
    SRGAnalyticsStreamStatePaused,
    /**
     *  The stream is being seeked to another location.
     */
    SRGAnalyticsStreamStateSeeking,
    /**
     *  The stream playback is stopped.
     */
    SRGAnalyticsStreamStateStopped,
    /**
     *  Stream playback ended normally.
     */
    SRGAnalyticsStreamStateEnded
};

/**
 *  Additional stream measurement labels.
 */
@interface SRGAnalyticsStreamLabels : NSObject <NSCopying>

/**
 *  @name Player information
 */

/**
 *  The media player display name, e.g. "AVPlayer" if you are using `AVPlayer` directly.
 */
@property (nonatomic, copy, nullable) NSString *playerName;

/**
 *  The media player version.
 */
@property (nonatomic, copy, nullable) NSString *playerVersion;

/**
 *  The volume of the player, on a scale from 0 to 100.
 *
 *  @discussion As the name suggests, this value must represent the volume of the player. If the player is not started or
 *              muted, this value must be set to 0.
 */
@property (nonatomic, nullable) NSNumber *playerVolumeInPercent;        // Long

/**
 *  @name Playback information
 */

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
 *  @name Custom information
 */

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
 *  @discussion This information is sent in comScore StreamSense.
 */
@property (nonatomic, nullable) NSDictionary<NSString *, NSString *> *comScoreCustomInfo;

/**
 *  Additional custom segment information to be sent to comScore. See https://srfmmz.atlassian.net/wiki/spaces/SRGPLAY/pages/36077617/Measurement+of+SRG+Player+Apps
 *  for a full list of possible variable names.
 *
 *  @discussion This information is sent in comScore StreamSense clips.
 */
@property (nonatomic, nullable) NSDictionary<NSString *, NSString *> *comScoreCustomSegmentInfo;

/**
 *  Merge the receiver with the provided labels (overriding values defined by it, otherwise keeping available ones).
 *  Use this method when you need to override full-length labels with more specific segment labels.
 *
 *  @discussion Custom value dictionaries are merged as well. If you need to preserve the original object intact,
 *              start with a copy.
 */
- (void)mergeWithLabels:(nullable SRGAnalyticsStreamLabels *)labels;

@end

/**
 *  Stream tracker delegate.
 */
@protocol SRGAnalyticsStreamTrackerDelegate <NSObject>

/**
 *  Return `YES` iff the stream is being played in live conditions.
 */
- (BOOL)streamTrackerIsPlayingLive:(SRGAnalyticsStreamTracker *)tracker;

/**
 *  The current playback position.
 */
- (NSTimeInterval)positionForStreamTracker:(SRGAnalyticsStreamTracker *)tracker;

/**
 *  Current labels associated with the stream.
 */
- (nullable SRGAnalyticsStreamLabels *)labelsForStreamTracker:(SRGAnalyticsStreamTracker *)tracker;

@end

/**
 *  Tracker for stream playback consumption. This tracker ensures that the stream analytics event sequences are always
 *  reliable, guaranteeing correct measurements. It also transparently manages heartbeats during playback.
 *
 *  When you need to track a new stream playback, simply instantiate an `SRGAnalyticsStreamTracker`, keeping a strong
 *  reference to it, and call the update method to keep the tracker informed about your player state. You must know
 *  which kind of stream is being loaded at the time you initiate the tracker, so that the tracker behavior can be
 *  adjusted appropriately.
 *
 *  To have heartbeats managed transparently, attach a delegate to the tracker, and implement the associated protocol
 *  to return current playback information.
 *
 *  Note that implementing media player tracking can be tricky to get right, and should only be required if your player is not based
 *  on SRG MediaPlayer (e.g. if you use `AVPlayer` directly). Please refer to the official documentation more information:
 *    https://srfmmz.atlassian.net/wiki/spaces/INTFORSCHUNG/pages/195595938/Implementation+Concept+-+draft
 */
@interface SRGAnalyticsStreamTracker : NSObject

/**
 *  Create a tracker instance.
 *
 *  @param livestream Set to `YES` if the stream is a livestream (either purely live or supporting DVR), or to `NO`
 *                    for on-demand streams.
 */
- (instancetype)initForLivestream:(BOOL)livestream;

/**
 *  The tracker delegate.
 *
 *  @discussion No heartbeats are sent if no delegate has been assigned.
 */
@property (nonatomic, weak, nullable) id<SRGAnalyticsStreamTrackerDelegate> delegate;

/**
 *  Update the tracker with the specified stream state and information.
 *
 *  @param state    The current player state.
 *  @param position The current player playback position, in milliseconds.
 *  @param labels   Additional detailed information.
 *
 *  @discussion An stream analytics event is only fired when proper conditions are met. To ensure events are emitted
 *              appropriately, you should therefore update the tracker when appropriate (e.g. when the player playing
 *              the stream changes its playback state).
 */
- (void)updateWithStreamState:(SRGAnalyticsStreamState)state
                     position:(NSTimeInterval)position
                       labels:(nullable SRGAnalyticsStreamLabels *)labels;

@end

NS_ASSUME_NONNULL_END
