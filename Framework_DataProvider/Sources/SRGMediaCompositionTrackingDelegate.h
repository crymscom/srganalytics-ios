//
//  Copyright (c) SRG SSR. All rights reserved.
//
//  License information is available from the LICENSE file.
//

#import <SRGAnalytics_MediaPlayer/SRGAnalytics_MediaPlayer.h>
#import <SRGDataProvider/SRGDataProvider.h>

NS_ASSUME_NONNULL_BEGIN

/**
 *  Internal class for tracking media composition playback
 */
@interface SRGMediaCompositionTrackingDelegate : NSObject <SRGAnalyticsMediaPlayerTrackingDelegate>

/**
 *  Track the specified media composition when playing the specified resource
 */
- (instancetype)initWithMediaComposition:(SRGMediaComposition *)mediaComposition resource:(SRGResource *)resource NS_DESIGNATED_INITIALIZER;

@end

@interface SRGMediaCompositionTrackingDelegate (Unavailable)

- (instancetype)init NS_UNAVAILABLE;

@end

NS_ASSUME_NONNULL_END
