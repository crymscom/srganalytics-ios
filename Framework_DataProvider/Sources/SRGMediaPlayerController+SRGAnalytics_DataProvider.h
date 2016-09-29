//
//  Copyright (c) SRG SSR. All rights reserved.
//
//  License information is available from the LICENSE file.
//

#import <SRGDataProvider/SRGDataProvider.h>
#import <SRGMediaPlayer/SRGMediaPlayer.h>

NS_ASSUME_NONNULL_BEGIN

/**
 *  Data provider compatibility additions to `SRGMediaPlayerViewController`.
 *
 *  For more information about stream measurements, @see SRGMediaPlayerController+SRGAnalytics.h
 */
@interface SRGMediaPlayerController (SRGAnalytics_DataProvider)

/**
 *  Return a request for preparing to play a media composition, trying to use the specified quality. The request must 
 *  be started by calling `-resume`
 *
 *  @param mediaComposition  The media composition to prepare
 *  @param preferredQuality  The quality to use. If `SRGQualityNone` or not found, the best available quality
 *                           is used
 *  @param userInfo          Optional dictionary conveying arbitrary information during playback
 *  @param completionHandler The completion handler will be called once the player is prepared, or if a request
 *                           error is encountered (it will not be called if the player cannot play the content;
 *                           listen to `SRGMediaPlayerPlaybackDidFailNotification` to catch playback errors)
 *
 *  @return The playback request
 */
- (SRGRequest *)prepareToPlayMediaComposition:(SRGMediaComposition *)mediaComposition
                         withPreferredQuality:(SRGQuality)preferredQuality
                                     userInfo:(nullable NSDictionary *)userInfo
                            completionHandler:(nullable void (^)(NSError *error))completionHandler;

/**
 *  Return a request for playing a media composition, trying to use the specified quality. The request must be started
 *  by calling `-resume`
 *
 *  @param mediaComposition  The media composition to play
 *  @param preferredQuality  The quality to use. If `SRGQualityNone` or not found, the best available quality
 *                           is used
 *  @param userInfo          Optional dictionary conveying arbitrary information during playback
 *  @param completionHandler The completion handler will be called once the player is playing, or if a request
 *                           error is encountered (it will not be called if the player cannot play the content;
 *                           listen to `SRGMediaPlayerPlaybackDidFailNotification` to catch playback errors)
 *
 *  @return The playback request
 */
- (SRGRequest *)playMediaComposition:(SRGMediaComposition *)mediaComposition
                withPreferredQuality:(SRGQuality)preferredQuality
                            userInfo:(nullable NSDictionary *)userInfo
                   completionHandler:(nullable void (^)(NSError *error))completionHandler;

@end

NS_ASSUME_NONNULL_END
