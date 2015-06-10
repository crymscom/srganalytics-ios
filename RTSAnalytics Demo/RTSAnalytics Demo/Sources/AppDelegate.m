//
//  Created by Frédéric Humbert-Droz on 17/04/15.
//  Copyright (c) 2015 RTS. All rights reserved.
//

#import "AppDelegate.h"

#import <RTSAnalytics/RTSAnalytics.h>

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
	
	[analyticsTracker setLogEnabled:YES];
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


- (void)applicationWillResignActive:(UIApplication *)application {
	// Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
	// Use this method to pause ongoing tasks, disable timers, and throttle down OpenGL ES frame rates. Games should use this method to pause the game.
}

- (void)applicationDidEnterBackground:(UIApplication *)application {
	// Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later.
	// If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
}

- (void)applicationWillEnterForeground:(UIApplication *)application {
	// Called as part of the transition from the background to the inactive state; here you can undo many of the changes made on entering the background.
}

- (void)applicationDidBecomeActive:(UIApplication *)application {
	// Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
}

- (void)applicationWillTerminate:(UIApplication *)application {
	// Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
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

- (NSDictionary *)streamSenseClipMetadataForIdentifier:(NSString *)identifier withSegment:(id<RTSMediaSegment>)segment
{
	return nil;
}

@end
