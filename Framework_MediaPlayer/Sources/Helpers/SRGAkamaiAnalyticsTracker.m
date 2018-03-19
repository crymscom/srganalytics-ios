//
//  Copyright (c) SRG SSR. All rights reserved.
//
//  License information is available from the LICENSE file.
//

#import "SRGAkamaiAnalyticsTracker.h"

#import "NSBundle+SRGAnalytics_MediaPlayer.h"

#import <AkamaiMediaAnalytics/AkamaiMediaAnalytics.h>
#import <UIKit/UIKit.h>

@implementation SRGAkamaiAnalyticsTracker

#pragma mark Notifications

+ (void)applicationWillTerminate:(NSNotification *)notification
{
    [AKAMMediaAnalytics_Av deinitMASDK];
}

@end

__attribute__((constructor)) static void SRGAkamaiAnalyticsTrackerInit(void)
{
    // Akamai media analytics SDK initialization
    NSURL *akamaiConfigurationFileURL = [[NSBundle srg_analyticsMediaPlayerBundle] URLForResource:@"akamai-media-analytics-configuration" withExtension:@"xml"];
    [AKAMMediaAnalytics_Av initWithConfigURL:akamaiConfigurationFileURL];
    
    [[NSNotificationCenter defaultCenter] addObserver:[SRGAkamaiAnalyticsTracker class]
                                             selector:@selector(applicationWillTerminate:)
                                                 name:UIApplicationWillTerminateNotification
                                               object:nil];
}
