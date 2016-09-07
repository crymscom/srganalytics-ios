//
//  Copyright (c) SRG SSR. All rights reserved.
//
//  License information is available from the LICENSE file.
//

#import "SRGAnalyticsTracker+MediaPlayer.h"

#import <SRGAnalytics/SRGAnalytics.h>

NS_ASSUME_NONNULL_BEGIN

@interface SRGAnalyticsTracker (MediaPlayer)

/**
 *  Start media player stream measurement
 *
 *  @discussion By default, stream measurement uses the ComscoreVirtualSite vsite defined in the Info.plist `SRGAnalytics` dictionary
 *              (see `-[SRGAnalyticsTracker startTrackingForBusinessUnit:] documentation`). This value can be optionally overridden
 *              by adding a StreamSenseVirtualSite entry to the same `SRGAnalytics` dictionary
 */
- (void)startStreamMeasurementWithVirtualSite:(nullable NSString *)virtualSite;

@end

NS_ASSUME_NONNULL_END