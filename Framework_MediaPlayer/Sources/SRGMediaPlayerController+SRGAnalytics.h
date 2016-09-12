//
//  Copyright (c) SRG SSR. All rights reserved.
//
//  License information is available from the LICENSE file.
//

#import <SRGMediaPlayer/SRGMediaPlayer.h>
#import "SRGAnalyticsMediaPlayerConstants.h"

NS_ASSUME_NONNULL_BEGIN

@interface SRGMediaPlayerController (SRGAnalytics)

/**
 *  Allow SRGAnalytics to track media player states. By defaut, YES.
 */
@property (nonatomic, getter=isTracked) BOOL tracked;

/**
 *  Analytics labels for the current played URL
 *  @return A dictionnary from userInfo[SRGAnalyticsMediaPlayerDictionnaryKey] value.
 */
@property (nonatomic, readonly) NSDictionary *srg_analyticsLabels;

@end

NS_ASSUME_NONNULL_END
