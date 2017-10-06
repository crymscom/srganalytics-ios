//
//  Copyright (c) SRG SSR. All rights reserved.
//
//  License information is available from the LICENSE file.
//

#import "SRGAnalyticsLabels.h"

NS_ASSUME_NONNULL_BEGIN

/**
 *  Additional stream measurement labels.
 */
@interface SRGAnalyticsStreamLabels : SRGAnalyticsLabels

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
 *  Additional custom segment information to be sent to comScore. See https://srfmmz.atlassian.net/wiki/spaces/SRGPLAY/pages/36077617/Measurement+of+SRG+Player+Apps
 *  for a full list of possible variable names.
 *
 *  @discussion This information is sent in comScore StreamSense clips.
 */
@property (nonatomic, nullable) NSDictionary<NSString *, NSString *> *comScoreCustomSegmentInfo;

/**
 *  @name Miscellaneous
 */

/**
 *  Merge the receiver with the provided labels (overriding values defined by it, otherwise keeping available ones).
 *  Use this method when you need to override full-length labels with more specific segment labels.
 *
 *  @discussion Custom value dictionaries are merged as well. If you need to preserve the original object intact,
 *              start with a copy.
 */
- (void)mergeWithLabels:(nullable SRGAnalyticsStreamLabels *)labels;

/**
 *  Dictionary containing the raw segment-related values which will be sent to comScore.
 */
@property (nonatomic, readonly) NSDictionary<NSString *, NSString *> *comScoreSegmentLabelsDictionary;

@end

NS_ASSUME_NONNULL_END
