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
 *  Return a request for preparing to play a media composition, trying to use the specified preferred settings. The request 
 *  can be started automatically if `resume` is set to `YES`. If set to `NO`, you are responsible of starting the request,
 *  either by calling `-resume` on it or adding it to a request queue. If no exact match can be found for the specified
 *  settings, a recommended valid setup will be used instead.
 *
 *  @param mediaComposition  The media composition to prepare.
 *  @param streamingMethod   The streaming method to use. If `SRGStreamingMethodNone` or if the method is not
 *                           found, a recommended method will be used instead.
 *  @param streamType        The stream type to use. If `SRGStreamTypeNone` or not found, the most flexible stream
 *                           type is used.
 *  @param quality           The quality to use. If `SRGQualityNone` or not found, the best available quality
 *                           is used.
 *  @param startBitRate      The bit rate the media should start playing with, in kbps. This parameter is a
 *                           recommendation with no result guarantee, though it should in general be applied. The
 *                           nearest available quality (larger or smaller than the requested size) will be used.
 *                           Usual SRG SSR valid bit ranges vary from 100 to 3000 kbps. Use 0 to start with the
 *                           lowest quality stream.
 *  @param userInfo          Optional dictionary conveying arbitrary information during playback.
 *  @param resume            Set to `YES` if you want the request to be started automatically.
 *  @param completionHandler The completion handler will be called once the player is prepared, or if a request
 *                           error is encountered (it will not be called if the player cannot play the content;
 *                           listen to `SRGMediaPlayerPlaybackDidFailNotification` to catch playback errors).
 *
 *  @return The playback request. If successful, the player will be paused on the chapter / segment specified by
 *          the media composition. The method might return `nil` if no protocol / quality combination is found.
 *          Resource lookup is performed so that a matching streaming method is found first, then a matching
 *          stream type, and finally a quality.
 */
- (nullable SRGRequest *)prepareToPlayMediaComposition:(SRGMediaComposition *)mediaComposition
                          withPreferredStreamingMethod:(SRGStreamingMethod)streamingMethod
                                            streamType:(SRGStreamType)streamType
                                               quality:(SRGQuality)quality
                                          startBitRate:(NSInteger)startBitRate
                                              userInfo:(nullable NSDictionary *)userInfo
                                                resume:(BOOL)resume
                                     completionHandler:(nullable void (^)(NSError * _Nullable error))completionHandler;

/**
 *  Return a request for playing a media composition, trying to use the specified preferred settings. The request can
 *  be started automatically if `resume` is set to `YES`. If set to `NO`, you are responsible of starting the request,
 *  either by calling `-resume` on it or adding it to a request queue. If no exact match can be found for the specified
 *  settings, a recommended valid setup will be used instead.
 *
 *  For parameter and return value documentation, see above.
 */
- (nullable SRGRequest *)playMediaComposition:(SRGMediaComposition *)mediaComposition
                 withPreferredStreamingMethod:(SRGStreamingMethod)streamingMethod
                                   streamType:(SRGStreamType)streamType
                                      quality:(SRGQuality)quality
                                 startBitRate:(NSInteger)startBitRate
                                     userInfo:(nullable NSDictionary *)userInfo
                                       resume:(BOOL)resume
                            completionHandler:(nullable void (^)(NSError * _Nullable error))completionHandler;

/**
 *  The media composition currently played, if any.
 *
 *  @discussion This property can also be used to update the media composition currently being played. Only media compositions with
 *              identical main chapter will be taken into account.
 */
@property (nonatomic, nullable) SRGMediaComposition *mediaComposition;

/**
 *  The streaming method used for playback, `SRGStreamingMethodNone` if none.
 */
@property (nonatomic, readonly) SRGStreamingMethod streamingMethod;

/**
 *  The quality used for playback, `SRGQualityNone` if none.
 */
@property (nonatomic, readonly) SRGQuality quality;

@end

NS_ASSUME_NONNULL_END
