//
//  Copyright (c) SRG SSR. All rights reserved.
//
//  License information is available from the LICENSE file.
//

#import <SRGAnalytics/SRGAnalytics.h>
#import <SRGMediaPlayer/SRGMediaPlayer.h>
#import <SRGDataProvider/SRGDataProvider.h>

NS_ASSUME_NONNULL_BEGIN

// Completion block signatures.
typedef void (^SRGResourceCompletionBlock)(NSURL * _Nullable URL, SRGResource *resource, NSArray<id<SRGSegment>> *segments, NSInteger index, SRGAnalyticsStreamLabels * _Nullable analyticsLabels, NSError * _Nullable error);

@interface SRGMediaComposition (SRGAnalytics_DataProvider)

/**
 *  Return a request to retrieve a playable resource for the receiver, trying to use the specified preferred settings.
 *  If no exact match can be found for the specified settings, a recommended valid setup will be used instead.
 *
 *  @param streamingMethod   The streaming method to use. If `SRGStreamingMethodNone` or if the method is not
 *                           found, a recommended method will be used instead.
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
 *  @param completionHandler The completion handler, returning the URL, the associated resource, the segments associated
 *                           with the media, the segment index to start with, as well as consolidated analytics labels.
 *
 *  @return The method might return `nil` if no protocol / quality combination is found. Resource lookup is performed so
 *          that a matching streaming method is found first, then a matching stream type, and finally a quality.
 */
- (nullable SRGRequest *)resourceWithPreferredStreamingMethod:(SRGStreamingMethod)streamingMethod
                                                   streamType:(SRGStreamType)streamType
                                                      quality:(SRGQuality)quality
                                                 startBitRate:(NSInteger)startBitRate
                                              completionBlock:(SRGResourceCompletionBlock)completionBlock;

@end

NS_ASSUME_NONNULL_END
