//
//  Copyright (c) SRG SSR. All rights reserved.
//
//  License information is available from the LICENSE file.
//

#import "RTSAnalyticsMediaPlayerDataSource.h"
#import "RTSAnalyticsTracker+MediaPlayer.h"

#import <SRGAnalytics/SRGAnalytics.h>

@interface RTSAnalyticsTracker (MediaPlayer)

/**
 *  Start media player stream measurement
 *
 *  @param dataSource The data source to be provided for stream tracking
 *
 *  @discussion By default, stream measurement uses the ComscoreVirtualSite vsite defined in the Info.plist `RTSAnalytics` dictionary
 *              (see `-[RTSAnalyticsTracker startTrackingForBusinessUnit:] documentation`). This value can be optionally overridden
 *              by adding a StreamSenseVirtualSite entry to the same `RTSAnalytics` dictionary
 */
- (void)startStreamMeasurementWithMediaDataSource:(id<RTSAnalyticsMediaPlayerDataSource>)dataSource;

/**
 *  The virtual site to be used for sending StreamSense stats.
 */
@property (nonatomic, readonly, strong) NSString *streamSenseVSite;

@end
