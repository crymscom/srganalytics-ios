//
//  Copyright (c) SRG SSR. All rights reserved.
//
//  License information is available from the LICENSE file.
//

#import "SRGAnalyticsMediaPlayerDataSource.h"
#import "SRGAnalyticsTracker+MediaPlayer.h"

#import <SRGAnalytics/SRGAnalytics.h>

@interface SRGAnalyticsTracker (MediaPlayer)

/**
 *  Start media player stream measurement
 *
 *  @param dataSource The data source to be provided for stream tracking
 *
 *  @discussion By default, stream measurement uses the ComscoreVirtualSite vsite defined in the Info.plist `SRGAnalytics` dictionary
 *              (see `-[SRGAnalyticsTracker startTrackingForBusinessUnit:] documentation`). This value can be optionally overridden
 *              by adding a StreamSenseVirtualSite entry to the same `SRGAnalytics` dictionary
 */
- (void)staSRGtreamMeasurementWithMediaDataSource:(id<SRGAnalyticsMediaPlayerDataSource>)dataSource;

/**
 *  The virtual site to be used for sending StreamSense stats.
 */
@property (nonatomic, readonly, strong) NSString *streamSenseVSite;

@end
