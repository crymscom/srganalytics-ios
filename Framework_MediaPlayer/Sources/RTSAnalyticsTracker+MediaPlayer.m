//
//  Copyright (c) SRG SSR. All rights reserved.
//
//  License information is available from the LICENSE file.
//

#import "RTSAnalyticsTracker+MediaPlayer.h"

#import "RTSMediaPlayerControllerTracker_private.h"

@implementation RTSAnalyticsTracker (MediaPlayer)

- (void)startTrackingForBusinessUnit:(SSRBusinessUnit)businessUnit
                     mediaDataSource:(id<RTSAnalyticsMediaPlayerDataSource>)dataSource

{
    [self startTrackingForBusinessUnit:businessUnit mediaDataSource:dataSource inDebugMode:NO];
}

- (void)startTrackingForBusinessUnit:(SSRBusinessUnit)businessUnit
                     mediaDataSource:(id<RTSAnalyticsMediaPlayerDataSource>)dataSource
                         inDebugMode:(BOOL)debugMode
{
    [self startTrackingForBusinessUnit:businessUnit inDebugMode:debugMode];
    
    NSAssert(self.streamSenseVSite.length > 0, @"You MUST define `RTSAnalytics>ComscoreVirtualSite` key in your app Info.plist, optionally overridden with `RTSAnalytics>StreamSenseVirtualSite`");
    [[RTSMediaPlayerControllerTracker sharedTracker] startStreamMeasurementForVirtualSite:self.streamSenseVSite mediaDataSource:dataSource];
}

@end
