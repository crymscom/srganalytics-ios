//
//  Copyright (c) SRG SSR. All rights reserved.
//
//  License information is available from the LICENSE file.
//

#import <SRGDataProvider/SRGDataProvider.h>
#import <SRGMediaPlayer/SRGMediaPlayer.h>

NS_ASSUME_NONNULL_BEGIN

/**
 *  Data provider compatibility additions to `SRGMediaPlayerController`.
 *
 *  For more information about stream measurements, @see SRGMediaPlayerController+SRGAnalytics.h
 */
@interface SRGMediaPlayerController (SRGAnalytics_DataProvider)

/**
 *  Return a request for preparing to play a media composition, trying to use the specified quality. The request can
 *  be started automatically if `resume` is set to YES. If set to NO, you are responsible of starting the request,
 *  either by calling `-resume` on it or adding it to a request queue.
 *
 *  @param mediaComposition  The media composition to prepare
 *  @param preferredProtocol The protocol to use. If `SRGProtocolNone` or if the protocol is not found, a recommended
 *                           protocol will be used instead
 *  @param preferredQuality  The quality to use. If `SRGQualityNone` or not found, the best available quality
 *                           is used
 *  @param userInfo          Optional dictionary conveying arbitrary information during playback
 *  @param resume            Set to YES if you want the request to be started automatically
 *  @param completionHandler The completion handler will be called once the player is prepared, or if a request
 *                           error is encountered (it will not be called if the player cannot play the content;
 *                           listen to `SRGMediaPlayerPlaybackDidFailNotification` to catch playback errors)
 *
 *  @return The playback request. If successful, the player will be paused on the chapter / segment specified by
 *          the media composition. The method might return nil if no protocol / quality combination is found
 */
- (nullable SRGRequest *)prepareToPlayMediaComposition:(SRGMediaComposition *)mediaComposition
                                 withPreferredProtocol:(SRGProtocol)preferredProtocol
                                      preferredQuality:(SRGQuality)preferredQuality
                                              userInfo:(nullable NSDictionary *)userInfo
                                                resume:(BOOL)resume
                                     completionHandler:(nullable void (^)(NSError * _Nullable error))completionHandler;

/**
 *  Return a request for playing a media composition, trying to use the specified quality. The request can
 *  be started automatically if `resume` is set to YES. If set to NO, you are responsible of starting the request,
 *  either by calling `-resume` on it or adding it to a request queue.
 *
 *  @param mediaComposition  The media composition to play
 *  @param preferredProtocol The protocol to use. If `SRGProtocolNone` or if the protocol is not found, a recommended
 *                           protocol will be used instead
 *  @param preferredQuality  The quality to use. If `SRGQualityNone` or not found, the best available quality
 *                           is used
 *  @param userInfo          Optional dictionary conveying arbitrary information during playback
 *  @param resume            Set to YES if you want the request to be started automatically
 *  @param completionHandler The completion handler will be called once the player is playing, or if a request
 *                           error is encountered (it will not be called if the player cannot play the content;
 *                           listen to `SRGMediaPlayerPlaybackDidFailNotification` to catch playback errors)
 *
 *  @return The playback request. If successful, the player will start on the chapter / segment specified by
 *          the media composition. The method might return nil if no protocol / quality combination is found
 */
- (nullable SRGRequest *)playMediaComposition:(SRGMediaComposition *)mediaComposition
                        withPreferredProtocol:(SRGProtocol)preferredProtocol
                             preferredQuality:(SRGQuality)preferredQuality
                                     userInfo:(nullable NSDictionary *)userInfo
                                       resume:(BOOL)resume
                            completionHandler:(nullable void (^)(NSError * _Nullable error))completionHandler;

/**
 *  Return the media composition currently played, if any
 */
@property (nonatomic, readonly, nullable) SRGMediaComposition *mediaComposition;

@end

NS_ASSUME_NONNULL_END
