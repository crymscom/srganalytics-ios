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
#import "ViewController.h"
#import "CustomMediaPlayerViewController.h"
#import "Segment.h"
#import "SegmentsMediaPlayerViewController.h"

@interface TableViewController () <UITableViewDelegate, RTSAnalyticsPageViewDataSource, RTSMediaPlayerControllerDataSource, RTSMediaSegmentsDataSource>

@end

@implementation TableViewController

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
	ViewController *controller = [segue destinationViewController];
	if ([segue.identifier isEqualToString:@"ViewWithNoTitle"]) {
		controller.title = nil;
	}else if ([segue.identifier isEqualToString:@"ViewWithTitle"]) {
		controller.title = @"C'est un titre pour l'événement !";
	}else if ([segue.identifier isEqualToString:@"ViewWithTitleAndLevels"]) {
		controller.title = @"Title";
		controller.levels = @[ @"TV", @"D'autres niveaux.plus loin"];
	}else if ([segue.identifier isEqualToString:@"ViewWithTitleLevelsAndCustomLabels"]) {
		controller.title = @"Title";
		controller.levels = @[ @"TV", @"n1", @"n2"];
		controller.customLabels = @{ @"srg_ap_cu" : @"custom" };
	}
}


#pragma mark - UITableViewDelegate

- (void) tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
	NSLog(@"Did Select indexPath at row %ld", indexPath.row);
	
	UITableViewCell *cell = [tableView cellForRowAtIndexPath:indexPath];
	
	if ([cell.reuseIdentifier hasPrefix:@"MediaPlayer"])
	{
		RTSMediaPlayerViewController *playerViewController = [[RTSMediaPlayerViewController alloc] initWithContentIdentifier:cell.reuseIdentifier dataSource:self];
		[self presentViewController:playerViewController animated:YES completion:nil];
	}
	else if ([cell.reuseIdentifier hasPrefix:@"CustomMediaPlayer"])
	{
		CustomMediaPlayerViewController *playerViewController = [[CustomMediaPlayerViewController alloc] initWithContentIdentifier:cell.reuseIdentifier dataSource:self];
		[self presentViewController:playerViewController animated:YES completion:nil];
	}
    else if ([cell.reuseIdentifier hasPrefix:@"SegmentsMediaPlayer"])
    {
        SegmentsMediaPlayerViewController *segmentsPlayerViewController = [[SegmentsMediaPlayerViewController alloc] initWithContentIdentifier:cell.reuseIdentifier dataSource:self];
        [self presentViewController:segmentsPlayerViewController animated:YES completion:nil];
    }
	else if ([cell.reuseIdentifier isEqualToString:@"PushNotificationCell"])
	{
		UIApplication *application = [UIApplication sharedApplication];
		[(AppDelegate *)application.delegate application:application didReceiveRemoteNotification:nil fetchCompletionHandler:nil];
	}
}



#pragma mark - RTSMediaPlayerControllerDataSource

- (void) mediaPlayerController:(RTSMediaPlayerController *)mediaPlayerController contentURLForIdentifier:(NSString *)identifier completionHandler:(void (^)(NSURL *, NSError *))completionHandler
{
	NSString *urlString = nil;
	if ([identifier hasSuffix:@"LiveCell"])
	{
		urlString = @"https://srgssruni9ch-lh.akamaihd.net/i/enc9uni_ch@191320/master.m3u8";
	}
	else if ([identifier hasSuffix:@"VODCell"] || [identifier hasSuffix:@"SegmentsCell"])
	{
		urlString = @"http://stream-i.rts.ch/i/tp/1993/tp_10071993-,450,k.mp4.csmil/master.m3u8";
	}
	
	NSURL *URL = [NSURL URLWithString:urlString];
	completionHandler(URL, nil);
}



#pragma mark - RTSMediaSegmentsDataSource

- (void)segmentsController:(RTSMediaSegmentsController *)controller segmentsForIdentifier:(NSString *)identifier withCompletionHandler:(RTSMediaSegmentsCompletionHandler)completionHandler
{
    AVPlayerItem *playerItem = controller.playerController.playerItem;
    CMTimeRange fullTimeRange = [[playerItem.seekableTimeRanges firstObject] CMTimeRangeValue];
    Segment *fullLengthSegment = [[Segment alloc] initWithTimeRange:fullTimeRange];
    
    if ([identifier rangeOfString:@"TwoSegments"].length != 0)
    {
        CMTimeRange timeRange1 = CMTimeRangeMake(CMTimeMakeWithSeconds(2., 1.), CMTimeMakeWithSeconds(3., 1.));
        Segment *segment1 = [[Segment alloc] initWithTimeRange:timeRange1];
        
        CMTimeRange timeRange2 = CMTimeRangeMake(CMTimeMakeWithSeconds(5., 1.), CMTimeMakeWithSeconds(7., 1.));
        Segment *segment2 = [[Segment alloc] initWithTimeRange:timeRange2];
        
        completionHandler(fullLengthSegment, @[segment1, segment2], nil);
    }
    else
    {
        CMTimeRange timeRange = CMTimeRangeMake(CMTimeMakeWithSeconds(2., 1.), CMTimeMakeWithSeconds(3., 1.));
        Segment *segment = [[Segment alloc] initWithTimeRange:timeRange];
        completionHandler(fullLengthSegment, @[segment], nil);
    }
}


#pragma mark - RTSAnalyticsPageViewDataSource

- (NSString *) pageViewTitle
{
	return @"MainPageTitle";
}

@end
