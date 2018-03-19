//
//  Copyright (c) SRG SSR. All rights reserved.
//
//  License information is available from the LICENSE file.
//

#import "SRGAkamaiAnalyticsTracker.h"

#import "NSBundle+SRGAnalytics_MediaPlayer.h"

#import <AkamaiMediaAnalytics/AkamaiMediaAnalytics.h>
#import <SRGMediaPlayer/SRGMediaPlayer.h>

@implementation SRGAkamaiAnalyticsTracker

#pragma mark Notifications

+ (void)playbackStateDidChange:(NSNotification *)notification
{
    SRGMediaPlayerPlaybackState playbackState = [notification.userInfo[SRGMediaPlayerPlaybackStateKey] integerValue];
    switch (playbackState) {
        case SRGMediaPlayerPlaybackStatePreparing: {
            SRGMediaPlayerController *mediaPlayerController = notification.object;
            [AKAMMediaAnalytics_Av processWithAVPlayer:mediaPlayerController.player];
            break;
        }
            
        case SRGMediaPlayerPlaybackStateSeeking: {
            [AKAMMediaAnalytics_Av beginScrub];
            break;
        }
            
        case SRGMediaPlayerPlaybackStateIdle: {
            [AKAMMediaAnalytics_Av AVPlayerPlaybackCompleted];
            break;
        }
            
        default: {
            break;
        }
    }
    
    SRGMediaPlayerPlaybackState previousPlaybackState = [notification.userInfo[SRGMediaPlayerPreviousPlaybackStateKey] integerValue];
    if (previousPlaybackState == SRGMediaPlayerPlaybackStateSeeking) {
        [AKAMMediaAnalytics_Av endScrub];
    }
}

+ (void)applicationWillTerminate:(NSNotification *)notification
{
    [AKAMMediaAnalytics_Av deinitMASDK];
}

@end

__attribute__((constructor)) static void SRGAkamaiAnalyticsTrackerInit(void)
{
    // Akamai media analytics SDK initialization
    NSURL *akamaiConfigurationURL = [NSURL URLWithString:@"https://raw.githubusercontent.com/SRGSSR/srg-player-videojs/master/ext/AkamaiQosBeacon.xml?token=AAKY2TvDYcbXv83_58oDzgPpzfTf66izks5auLsMwA%3D%3D"];
    [AKAMMediaAnalytics_Av initWithConfigURL:akamaiConfigurationURL];

    [[NSNotificationCenter defaultCenter] addObserver:[SRGAkamaiAnalyticsTracker class]
                                             selector:@selector(playbackStateDidChange:)
                                                 name:SRGMediaPlayerPlaybackStateDidChangeNotification
                                               object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:[SRGAkamaiAnalyticsTracker class]
                                             selector:@selector(applicationWillTerminate:)
                                                 name:UIApplicationWillTerminateNotification
                                               object:nil];
}
