//
//  Copyright (c) SRG SSR. All rights reserved.
//
//  License information is available from the LICENSE file.
//

#import <SRGAnalytics/SRGAnalytics.h>
#import "AppDelegate.h"
#import "Segment.h"
#import "ViewController.h"

@interface AppDelegate () <RTSAnalyticsMediaPlayerDataSource>

@end

@implementation AppDelegate


- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions
{
	// Tracker
	RTSAnalyticsTracker *analyticsTracker = [RTSAnalyticsTracker sharedTracker];
	[analyticsTracker startTrackingForBusinessUnit:SSRBusinessUnitRTS mediaDataSource:self];

	return YES;
}

- (void)application:(UIApplication *)application didReceiveLocalNotification:(UILocalNotification *)notification
{
	NSLog(@"didReceiveLocalNotification %@", notification.userInfo);
	
	[self openViewControllerFromNotification];
}

- (void)application:(UIApplication *)application didReceiveRemoteNotification:(NSDictionary *)userInfo fetchCompletionHandler:(void (^)(UIBackgroundFetchResult result))completionHandler
{
	NSLog(@"didReceiveRemoteNotification %@", userInfo);
	
	[self openViewControllerFromNotification];
}

- (void) openViewControllerFromNotification
{
	UINavigationController *navigationController = [self.window.rootViewController.storyboard instantiateViewControllerWithIdentifier:@"PushNavigationController"];
	ViewController *controller = (ViewController *)navigationController.topViewController;
	controller.pageViewFromPushNotification = YES;
	[self.window.rootViewController presentViewController:navigationController animated:YES completion:^{
		controller.pageViewFromPushNotification = NO;
	}];
}

#pragma mark - RTSAnalyticsMediaPlayerDataSource

- (NSDictionary *)streamSensePlaylistMetadataForIdentifier:(NSString *)identifier
{
    return nil;
}

- (NSDictionary *)streamSenseClipMetadataForIdentifier:(NSString *)identifier withSegment:(Segment *)segment
{
    return @{ @"clip_name" : segment ? segment.name : @"no_name" };
}

@end
