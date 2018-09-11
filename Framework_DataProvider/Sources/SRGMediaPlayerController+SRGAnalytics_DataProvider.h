//
//  Copyright (c) SRG SSR. All rights reserved.
//
//  License information is available from the LICENSE file.
//

#import <SRGDataProvider/SRGDataProvider.h>
#import <SRGMediaPlayer/SRGMediaPlayer.h>

NS_ASSUME_NONNULL_BEGIN

/**
 *  Data provider compatibility additions to `SRGMediaPlayerController`. By playing medias with the methods provided
 *  by this category, playback and analytics metadata is entirely retrieved from the Integration Layer and automatically
 *  managed without additional work.
 *
 *  For more information about stream measurements, @see SRGMediaPlayerController+SRGAnalytics_MediaPlayer.h.
 */
@interface SRGMediaPlayerController (SRGAnalytics_DataProvider)

/**
 *  Play a media composition, trying to use the specified preferred settings. If no exact match can be found for the
 *  specified settings, a recommended valid setup will be used instead.
 *
 *  @param mediaComposition  The media composition to prepare.
 *  @param position          The position to start at. If `nil` or if the specified position lies outside the content
 *                           time range, playback starts at the default position.
 *  @param streamingMethod   The streaming method to use. If `SRGStreamingMethodNone` or if the method is not
 *                           found, a recommended method will be used instead.
 *  @param streamType        The stream type to use. If `SRGStreamTypeNone` or not found, the optimal available stream
 *                           type is used.
 *  @param quality           The quality to use. If `SRGQualityNone` or not found, the best available quality
 *                           is used.
 *  @param DRM               Set to `YES` if DRM-protected streams should be favored over non-protected ones. If set
 *                           to `NO`, the first matching resource is used, based on their original order.
 *  @param startBitRate      The bit rate the media should start playing with, in kbps. This parameter is a
 *                           recommendation with no result guarantee, though it should in general be applied. The
 *                           nearest available quality (larger or smaller than the requested size) will be used.
 *                           Usual SRG SSR valid bit ranges vary from 100 to 3000 kbps. Use 0 to start with the
 *                           lowest quality stream.
 *  @param userInfo          Optional dictionary conveying arbitrary information during playback.
 *  @param completionHandler The completion block to be called after the player has finished preparing the media. This
 *                           block will only be called if the media could be loaded.
 *
 *  @return Returns `YES` iff playback could be started.
 *
 *  @discussion Resource lookup is performed in the order of the parameters (streaming method first, then quality last).
 */
- (BOOL)prepareToPlayMediaComposition:(SRGMediaComposition *)mediaComposition
                           atPosition:(nullable SRGPosition *)position
         withPreferredStreamingMethod:(SRGStreamingMethod)streamingMethod
                           streamType:(SRGStreamType)streamType
                              quality:(SRGQuality)quality
                                  DRM:(BOOL)DRM
                         startBitRate:(NSInteger)startBitRate
                             userInfo:(nullable NSDictionary *)userInfo
                    completionHandler:(nullable void (^)(void))completionHandler;

/**
 *  Same as `-prepareToPlayMediaComposition:atPosition:withPreferredStreamingMethod:streamType:quality:DRM:startBitRate:userInfo:completionHandler:`,
 *  but automatically starting playback once the player has been prepared.
 */
- (BOOL)playMediaComposition:(SRGMediaComposition *)mediaComposition
                  atPosition:(nullable SRGPosition *)position
withPreferredStreamingMethod:(SRGStreamingMethod)streamingMethod
                  streamType:(SRGStreamType)streamType
                     quality:(SRGQuality)quality
                         DRM:(BOOL)DRM
                startBitRate:(NSInteger)startBitRate
                    userInfo:(nullable NSDictionary *)userInfo;

/**
 *  The media composition currently played, if any.
 *
 *  @discussion This property can also be used to update the media composition currently being played. Only media compositions with
 *              identical main chapter will be taken into account.
 */
@property (nonatomic, nullable) SRGMediaComposition *mediaComposition;

/**
 *  The resource used for playback, `nil` if none.
 */
@property (nonatomic, readonly, nullable) SRGResource *resource;

@end

NS_ASSUME_NONNULL_END
