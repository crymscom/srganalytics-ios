//
//  TableViewController.m
//  RTSAnalytics Demo
//
//  Created by Frédéric Humbert-Droz on 17/04/15.
//  Copyright (c) 2015 RTS. All rights reserved.
//

#import "TableViewController.h"
#import <RTSAnalytics/RTSAnalytics.h>
#import <RTSMediaPlayer/RTSMediaPlayer.h>

#import "AppDelegate.h"

@interface TableViewController () <UITableViewDelegate, RTSAnalyticsPageViewDataSource, RTSMediaPlayerControllerDataSource>

@end

@implementation TableViewController

#pragma mark - UITableViewDelegate

- (void) tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
	NSLog(@"Did Select indexPath at row %ld", indexPath.row);
	
	UITableViewCell *cell = [tableView cellForRowAtIndexPath:indexPath];
	
	if ([cell.reuseIdentifier isEqualToString:@"MediaPlayerCell"])
	{
		RTSMediaPlayerViewController *playerViewController = [[RTSMediaPlayerViewController alloc] initWithContentIdentifier:@"myIdentifier" dataSource:self];
		[self presentViewController:playerViewController animated:YES completion:NULL];
	}
	else if ([cell.reuseIdentifier isEqualToString:@"PushNotitificationCell"])
	{
		UIApplication *application = [UIApplication sharedApplication];
		[(AppDelegate *)application.delegate application:application didReceiveRemoteNotification:nil fetchCompletionHandler:NULL];
	}
}



#pragma mark - RTSMediaPlayerControllerDataSource

- (void) mediaPlayerController:(RTSMediaPlayerController *)mediaPlayerController contentURLForIdentifier:(NSString *)identifier completionHandler:(void (^)(NSURL *, NSError *))completionHandler
{
	NSURL *URL = [NSURL URLWithString:@"https://srgssruni9ch-lh.akamaihd.net/i/enc9uni_ch@191320/master.m3u8"];
	completionHandler(URL, nil);
}



#pragma mark - RTSAnalyticsPageViewDataSource

- (NSString *) pageViewTitle
{
	return @"MainPageTitle";
}

@end
