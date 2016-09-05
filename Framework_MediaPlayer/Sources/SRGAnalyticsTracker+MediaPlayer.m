//
//  Copyright (c) SRG SSR. All rights reserved.
//
//  License information is available from the LICENSE file.
//

#import "SRGAnalyticsTracker+MediaPlayer.h"

#import "SRGMediaPlayerControllerTracker.h"

@implementation SRGAnalyticsTracker (MediaPlayer)

- (void)startStreamMeasurementWithMediaDataSource:(id<SRGAnalyticsMediaPlayerDataSource>)dataSource;
{
    NSAssert(self.streamSenseVSite.length > 0, @"You MUST define `SRGAnalytics>ComscoreVirtualSite` key in your app Info.plist, optionally overridden with `SRGAnalytics>StreamSenseVirtualSite`");
    [[SRGMediaPlayerControllerTracker sharedTracker] startStreamMeasurementForVirtualSite:self.streamSenseVSite mediaDataSource:dataSource];
}

- (NSString *) streamSenseVSite
{
    NSDictionary *analyticsInfoDictionary = [[NSBundle mainBundle] objectForInfoDictionaryKey:@"SRGAnalytics"];
    return analyticsInfoDictionary[@"StreamSenseVirtualSite"] ?: self.comscoreVSite;
}

@end
