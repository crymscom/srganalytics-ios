//
//  Copyright (c) SRG SSR. All rights reserved.
//
//  License information is available from the LICENSE file.
//

#import "RTSAnalyticsTracker+MediaPlayer.h"

#import "RTSMediaPlayerControllerTracker.h"

@implementation RTSAnalyticsTracker (MediaPlayer)

- (void)startStreamMeasurementWithMediaDataSource:(id<RTSAnalyticsMediaPlayerDataSource>)dataSource;
{
    NSAssert(self.streamSenseVSite.length > 0, @"You MUST define `RTSAnalytics>ComscoreVirtualSite` key in your app Info.plist, optionally overridden with `RTSAnalytics>StreamSenseVirtualSite`");
    [[RTSMediaPlayerControllerTracker sharedTracker] startStreamMeasurementForVirtualSite:self.streamSenseVSite mediaDataSource:dataSource];
}

- (NSString *) streamSenseVSite
{
    NSDictionary *analyticsInfoDictionary = [[NSBundle mainBundle] objectForInfoDictionaryKey:@"RTSAnalytics"];
    return analyticsInfoDictionary[@"StreamSenseVirtualSite"] ?: self.comscoreVSite;
}

@end
