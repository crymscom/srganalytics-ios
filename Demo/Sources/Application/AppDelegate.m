//
//  Copyright (c) SRG SSR. All rights reserved.
//
//  License information is available from the LICENSE file.
//

#import "AppDelegate.h"

#import "DemosViewController.h"
#import "SimpleViewController.h"

#import <SRGAnalytics/SRGAnalytics.h>
#import <SRGAnalytics_MediaPlayer/SRGAnalytics_MediaPlayer.h>

@implementation AppDelegate

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions
{
    self.window = [[UIWindow alloc] initWithFrame:[UIScreen mainScreen].bounds];
    self.window.backgroundColor = [UIColor blackColor];
    [self.window makeKeyAndVisible];
    
    [[SRGAnalyticsTracker sharedTracker] startWithBusinessUnitIdentifier:SRGAnalyticsBusinessUnitIdentifierTEST
                                                     comScoreVirtualSite:@"rts-app-test-v"
                                                     netMetrixIdentifier:@"test"];
    
    DemosViewController *demosViewController = [[DemosViewController alloc] init];
    self.window.rootViewController = [[UINavigationController alloc] initWithRootViewController:demosViewController];
    
    return YES;
}

- (void)application:(UIApplication *)application didReceiveLocalNotification:(UILocalNotification *)notification
{
    NSLog(@"Local notification received: %@", notification.userInfo);

    [self openViewControllerFromNotification];
}

- (void)application:(UIApplication *)application didReceiveRemoteNotification:(NSDictionary *)userInfo fetchCompletionHandler:(void (^)(UIBackgroundFetchResult result))completionHandler
{
    NSLog(@"Remote notification received %@", userInfo);

    [self openViewControllerFromNotification];
}

- (void)openViewControllerFromNotification
{
    UINavigationController *navigationController = [self.window.rootViewController.storyboard instantiateViewControllerWithIdentifier:@"PushNavigationController"];
    SimpleViewController *controller = (SimpleViewController *)navigationController.topViewController;
    controller.srg_isOpenedFromPushNotification = YES;
    [self.window.rootViewController presentViewController:navigationController animated:YES completion:^{
        controller.srg_isOpenedFromPushNotification = NO;
    }];
}

@end
