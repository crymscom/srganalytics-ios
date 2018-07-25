//
//  Copyright (c) SRG SSR. All rights reserved.
//
//  License information is available from the LICENSE file.
//

#import <SRGAnalytics/SRGAnalytics.h>
#import <SRGContentProtection/SRGContentProtection.h>
#import <SRGDataProvider/SRGDataProvider.h>
#import <SRGMediaPlayer/SRGMediaPlayer.h>

NS_ASSUME_NONNULL_BEGIN

// Completion block signatures.
typedef void (^SRGPlaybackContextBlock)(NSURL *streamURL, SRGResource *resource, NSArray<id<SRGSegment>> * _Nullable segments, NSInteger index, SRGAnalyticsStreamLabels * _Nullable analyticsLabels);

@interface SRGMediaComposition (SRGAnalytics_DataProvider)

/**
 *  Retrieve a playback context for the receiver, trying to use the specified preferred settings. If no exact match can
 *  be found for the specified settings, a recommended valid setup will be used instead.
 *
 *  @param streamingMethod   The streaming method to use. If `SRGStreamingMethodNone` or if the method is not
 *                           found, a recommended method will be used instead.
 *  @param contentProtection The content protection to be applied if available, otherwise a lower setting will be
 *                           used. If `SRGContentProtectionNone` or not found, the most restrictive content protection
 *                           is used.
 *  @param streamType        The stream type to use. If `SRGStreamTypeNone` or not found, the optimal available stream
 *                           type is used.
 *  @param quality           The quality to use. If `SRGQualityNone` or not found, the best available quality
 *                           is used.
 *  @param startBitRate      The bit rate the media should start playing with, in kbps. This parameter is a
 *                           recommendation with no result guarantee, though it should in general be applied. The
 *                           nearest available quality (larger or smaller than the requested size) will be used.
 *                           Usual SRG SSR valid bit ranges vary from 100 to 3000 kbps. Use 0 to start with the
 *                           lowest quality stream.
 *  @param userInfo          Optional dictionary conveying arbitrary information during playback.
 *  @param resultBlock       The block called to return the resolved resource context (stream URL, resource, segments
 *                           associated with the media, segment index to start at, as well as consolidated analytics labels).
 *
 *  @return `YES` if a playback context can be resolved, in which case the context block is called. If no context can
 *          be resolved, the method returns `NO` and the context block is not called.
 *
 *  @discussion Resource lookup is performed in the order of the parameters (streaming method first, then quality last).
 */
- (BOOL)playbackContextWithPreferredStreamingMethod:(SRGStreamingMethod)streamingMethod
                                  contentProtection:(SRGContentProtection)contentProtection
                                         streamType:(SRGStreamType)streamType
                                            quality:(SRGQuality)quality
                                       startBitRate:(NSInteger)startBitRate
                                       contextBlock:(NS_NOESCAPE SRGPlaybackContextBlock)contextBlock;

@end

NS_ASSUME_NONNULL_END
