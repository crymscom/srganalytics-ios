//
//  Copyright (c) SRG SSR. All rights reserved.
//
//  License information is available from the LICENSE file.
//

#import "RTSAnalyticsMediaPlayerDataSource.h"
#import "RTSAnalyticsTracker+MediaPlayer.h"

#import <SRGAnalytics/SRGAnalytics.h>

@interface RTSAnalyticsTracker (MediaPlayer)

- (void)startTrackingForBusinessUnit:(SSRBusinessUnit)businessUnit
                     mediaDataSource:(id<RTSAnalyticsMediaPlayerDataSource>)dataSource;
- (void)startTrackingForBusinessUnit:(SSRBusinessUnit)businessUnit
                     mediaDataSource:(id<RTSAnalyticsMediaPlayerDataSource>)dataSource
                         inDebugMode:(BOOL)debugMode;

@end

@interface RTSAnalyticsTracker (MediaPlayerUnavailable)

- (void)startTrackingForBusinessUnit:(SSRBusinessUnit)businessUnit NS_UNAVAILABLE;
- (void)startTrackingForBusinessUnit:(SSRBusinessUnit)businessUnit inDebugMode:(BOOL)debugMode NS_UNAVAILABLE;

@end
