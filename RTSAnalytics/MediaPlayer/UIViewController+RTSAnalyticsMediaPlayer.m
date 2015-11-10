//
//  Copyright (c) SRG. All rights reserved.
//
//  License information is available from the LICENSE file.
//

#import "UIViewController+RTSAnalyticsMediaPlayer.h"

#import "RTSMediaPlayerControllerTracker_private.h"

@implementation UIViewController (RTSAnalyticsMediaPlayer)

- (void) startTrackingMediaPlayerController:(RTSMediaPlayerController *)mediaPlayerController
{
	[[RTSMediaPlayerControllerTracker sharedTracker] startTrackingMediaPlayerController:mediaPlayerController];
}

- (void) stopTrackingMediaPlayerController:(RTSMediaPlayerController *)mediaPlayerController
{
	[[RTSMediaPlayerControllerTracker sharedTracker] stopTrackingMediaPlayerController:mediaPlayerController];
}

@end
