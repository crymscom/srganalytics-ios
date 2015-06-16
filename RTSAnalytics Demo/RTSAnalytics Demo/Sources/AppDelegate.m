//
//  Created by Frédéric Humbert-Droz on 17/04/15.
//  Copyright (c) 2015 RTS. All rights reserved.
//

#import "AppDelegate.h"

#import <RTSAnalytics/RTSAnalytics.h>
#import "Segment.h"

@interface AppDelegate () <RTSAnalyticsMediaPlayerDataSource>

@end

@implementation AppDelegate


- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions
{
	setenv("RTSAnalyticsLogLevel", "-1", 0);
	
	// Tracker
	RTSAnalyticsTracker *analyticsTracker = [RTSAnalyticsTracker sharedTracker];
	[analyticsTracker setComscoreVSite:@"rts-app-test-v"];
	[analyticsTracker setNetmetrixAppId:@"test"];
	
	[analyticsTracker setProduction:NO];
	
	[analyticsTracker startTrackingForBusinessUnit:SSRBusinessUnitRTS launchOptions:launchOptions mediaDataSource:self];

	return YES;
}

- (void)application:(UIApplication *)application didReceiveLocalNotification:(UILocalNotification *)notification
{
	NSLog(@"didReceiveLocalNotification %@", notification.userInfo);
	
	[[RTSAnalyticsTracker sharedTracker] trackPushNotificationReceived];
	[self openViewControllerFromNotification];
}

- (void)application:(UIApplication *)application didReceiveRemoteNotification:(NSDictionary *)userInfo fetchCompletionHandler:(void (^)(UIBackgroundFetchResult result))completionHandler
{
	NSLog(@"didReceiveRemoteNotification %@", userInfo);
	
	[[RTSAnalyticsTracker sharedTracker] trackPushNotificationReceived];
	[self openViewControllerFromNotification];
}

- (void) openViewControllerFromNotification
{
	UIViewController *controller = [self.window.rootViewController.storyboard instantiateViewControllerWithIdentifier:@"PushNavigationController"];
	[self.window.rootViewController presentViewController:controller animated:YES completion:NULL];
}

#pragma mark - RTSAnalyticsMediaPlayerDataSource

- (NSDictionary *)streamSenseLabelsMetadataForIdentifier:(NSString *)identifier
{
    return nil;
}

- (NSDictionary *)streamSensePlaylistMetadataForIdentifier:(NSString *)identifier
{
    return nil;
}

- (NSDictionary *)streamSenseClipMetadataForIdentifier:(NSString *)identifier withSegment:(Segment *)segment
{
    // Add a clip_type custom field to check whether we are in a segment or in the full-length in tests
    return @{ @"clip_type" : segment ? segment.name : @"full_length" };
}

@end
