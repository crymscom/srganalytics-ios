//
//  Copyright (c) SRG SSR. All rights reserved.
//
//  License information is available from the LICENSE file.
//

#import "SRGAnalyticsTracker+MediaPlayer.h"

#import "SRGMediaPlayerControllerTracker.h"

@implementation SRGAnalyticsTracker (MediaPlayer)

- (void)startStreamMeasurementWithVirtualSite:(NSString *)virtualSite
{
    [[SRGMediaPlayerControllerTracker sharedTracker] startStreamMeasurementForVirtualSite:virtualSite ?: self.comscoreVSite];
}

@end
