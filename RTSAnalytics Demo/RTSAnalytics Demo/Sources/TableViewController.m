//
//  Copyright (c) SRG. All rights reserved.
//
//  License information is available from the LICENSE file.
//

#import <SRGAnalytics/SRGAnalytics.h>
#import <SRGMediaPlayer/SRGMediaPlayer.h>

#import "TableViewController.h"

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
	}
    else if ([segue.identifier isEqualToString:@"ViewWithTitle"]) {
		controller.title = @"C'est un titre pour l'événement !";
	}
    else if ([segue.identifier isEqualToString:@"ViewWithTitleAndLevels"]) {
		controller.title = @"Title";
		controller.levels = @[ @"TV", @"D'autres niveaux.plus loin"];
	}
    else if ([segue.identifier isEqualToString:@"ViewWithTitleLevelsAndCustomLabels"]) {
		controller.title = @"Title";
		controller.levels = @[ @"TV", @"n1", @"n2"];
		controller.customLabels = @{ @"srg_ap_cu" : @"custom" };
	}
}


#pragma mark - UITableViewDelegate

- (void) tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
    
	NSLog(@"Did Select indexPath at row %ld", (long)indexPath.row);
	
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
        [(AppDelegate *)application.delegate application:application didReceiveRemoteNotification:@{} fetchCompletionHandler:^(UIBackgroundFetchResult result) {}];
	}
    else if ([cell.reuseIdentifier isEqualToString:@"HiddenEventWithNoTitleCell"]) {
        [[RTSAnalyticsTracker sharedTracker] trackHiddenEventWithTitle:nil];
    }
    else if ([cell.reuseIdentifier isEqualToString:@"HiddenEventWithTitleCell"]) {
        [[RTSAnalyticsTracker sharedTracker] trackHiddenEventWithTitle:@"Title"];
    }
    else if ([cell.reuseIdentifier isEqualToString:@"HiddenEventWithTitleAndCustomLabelsCell"]) {
        [[RTSAnalyticsTracker sharedTracker] trackHiddenEventWithTitle:@"Title" customLabels:@{ @"srg_ap_cu" : @"custom" }];
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
    else if ([identifier hasSuffix:@"DVRCell"])
    {
        urlString = @"http://srgssruni22ach-lh.akamaihd.net/i/enc22auni_ch@195192/master.m3u8";
    }
    else if ([identifier hasSuffix:@"SegmentsMediaPlayerMultiplePhysicalSegmentsAODCell"])
    {
        urlString = @"http://srfaodorigin-vh.akamaihd.net/i/world/echo-der-zeit/7ea975b2-fafe-487b-a6a5-9b7d2461ff05.,q10,q20,.mp4.csmil/master.m3u8";
    }
    else if ([identifier hasSuffix:@"SegmentsMediaPlayerMultiplePhysicalSegmentsAODCell_2"])
    {
        urlString = @"http://srfaodorigin-vh.akamaihd.net/i/world/echo-der-zeit/5cc0475c-0f87-4c62-85d3-c43857094543.,q10,q20,.mp4.csmil/master.m3u8";
    }
	
	NSURL *URL = [NSURL URLWithString:urlString];
	completionHandler(URL, nil);
}



#pragma mark - RTSMediaSegmentsDataSource

- (void) segmentsController:(RTSMediaSegmentsController *)controller segmentsForIdentifier:(NSString *)identifier withCompletionHandler:(RTSMediaSegmentsCompletionHandler)completionHandler
{
    if ([identifier rangeOfString:@"MultipleSegments"].length != 0)
    {
        Segment *fullLengthSegment = [[Segment alloc] initWithIdentifier:identifier name:@"full_length" timeRange:CMTimeRangeMake(kCMTimeZero, CMTimeMakeWithSeconds(3600., 1.))];
        fullLengthSegment.fullLength = YES;
        fullLengthSegment.visible = NO;
        
        const NSTimeInterval segment1StartTime = 2.;
        const NSTimeInterval segment1Duration = 3.;
        
        const NSTimeInterval segment2StartTime = segment1StartTime + segment1Duration;
        const NSTimeInterval segment2Duration = 5.;
        
        const NSTimeInterval segment3StartTime = 40.;
        const NSTimeInterval segment3Duration = 30.;
        
        CMTimeRange timeRange1 = CMTimeRangeMake(CMTimeMakeWithSeconds(segment1StartTime, 1.), CMTimeMakeWithSeconds(segment1Duration, 1.));
        Segment *segment1 = [[Segment alloc] initWithIdentifier:identifier name:@"segment1" timeRange:timeRange1];
        
        CMTimeRange timeRange2 = CMTimeRangeMake(CMTimeMakeWithSeconds(segment2StartTime, 1.), CMTimeMakeWithSeconds(segment2Duration, 1.));
        Segment *segment2 = [[Segment alloc] initWithIdentifier:identifier name:@"segment2" timeRange:timeRange2];
        
        CMTimeRange timeRange3 = CMTimeRangeMake(CMTimeMakeWithSeconds(segment3StartTime, 1.), CMTimeMakeWithSeconds(segment3Duration, 1.));
        Segment *segment3 = [[Segment alloc] initWithIdentifier:identifier name:@"segment3" timeRange:timeRange3];
        segment3.blocked = YES;
        
        completionHandler(@[fullLengthSegment, segment1, segment2, segment3], nil);
    }
    else if ([identifier isEqualToString:@"SegmentsMediaPlayerMultiplePhysicalSegmentsAODCell"])
    {
        Segment *fullLength1 = [[Segment alloc] initWithIdentifier:identifier name:@"full_length1" timeRange:CMTimeRangeMake(kCMTimeZero, CMTimeMakeWithSeconds(3600., 1.))];
        Segment *fullLength2 = [[Segment alloc] initWithIdentifier:[identifier stringByAppendingString:@"_2"] name:@"full_length2" timeRange:CMTimeRangeMake(kCMTimeZero, CMTimeMakeWithSeconds(1200., 1.))];
        completionHandler(@[fullLength1, fullLength2], nil);
    }
    else
    {
        Segment *fullLengthSegment = [[Segment alloc] initWithIdentifier:identifier name:@"full_length" timeRange:CMTimeRangeMake(kCMTimeZero, CMTimeMakeWithSeconds(3600., 1.))];
        fullLengthSegment.fullLength = YES;
        fullLengthSegment.visible = NO;
        
        CMTimeRange timeRange = CMTimeRangeMake(CMTimeMakeWithSeconds(2., 1.), CMTimeMakeWithSeconds(15., 1.));
        Segment *segment = [[Segment alloc] initWithIdentifier:identifier name:@"segment" timeRange:timeRange];
        completionHandler(@[fullLengthSegment, segment], nil);
    }
}


#pragma mark - RTSAnalyticsPageViewDataSource

- (NSString *) pageViewTitle
{
	return @"MainPageTitle";
}

@end
