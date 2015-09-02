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
    else if ([identifier hasSuffix:@"DVRCell"])
    {
        urlString = @"http://srgssruni22ach-lh.akamaihd.net/i/enc22auni_ch@195192/master.m3u8";
    }
	
	NSURL *URL = [NSURL URLWithString:urlString];
	completionHandler(URL, nil);
}



#pragma mark - RTSMediaSegmentsDataSource

- (void) segmentsController:(RTSMediaSegmentsController *)controller segmentsForIdentifier:(NSString *)identifier withCompletionHandler:(RTSMediaSegmentsCompletionHandler)completionHandler
{
    Segment *fullLengthSegment = [[Segment alloc] initWithTimeRange:CMTimeRangeMake(kCMTimeZero, CMTimeMakeWithSeconds(3600., 1.)) name:@"full" blocked:NO];
    
    if ([identifier rangeOfString:@"MultipleSegments"].length != 0)
    {
        const NSTimeInterval segment1StartTime = 2.;
        const NSTimeInterval segment1Duration = 3.;
        
        const NSTimeInterval segment2StartTime = segment1StartTime + segment1Duration;
        const NSTimeInterval segment2Duration = 5.;
        
        const NSTimeInterval segment3StartTime = 40.;
        const NSTimeInterval segment3Duration = 30.;
        
        CMTimeRange timeRange1 = CMTimeRangeMake(CMTimeMakeWithSeconds(segment1StartTime, 1.), CMTimeMakeWithSeconds(segment1Duration, 1.));
        Segment *segment1 = [[Segment alloc] initWithTimeRange:timeRange1 name:@"segment1" blocked:NO];
        
        CMTimeRange timeRange2 = CMTimeRangeMake(CMTimeMakeWithSeconds(segment2StartTime, 1.), CMTimeMakeWithSeconds(segment2Duration, 1.));
        Segment *segment2 = [[Segment alloc] initWithTimeRange:timeRange2 name:@"segment2" blocked:NO];
        
        CMTimeRange timeRange3 = CMTimeRangeMake(CMTimeMakeWithSeconds(segment3StartTime, 1.), CMTimeMakeWithSeconds(segment3Duration, 1.));
        Segment *segment3 = [[Segment alloc] initWithTimeRange:timeRange3 name:@"segment3" blocked:YES];
        
        completionHandler(fullLengthSegment, @[segment1, segment2, segment3], nil);
    }
    else
    {
        CMTimeRange timeRange = CMTimeRangeMake(CMTimeMakeWithSeconds(2., 1.), CMTimeMakeWithSeconds(15., 1.));
        Segment *segment = [[Segment alloc] initWithTimeRange:timeRange name:@"segment" blocked:NO];
        completionHandler(fullLengthSegment, @[segment], nil);
    }
}


#pragma mark - RTSAnalyticsPageViewDataSource

- (NSString *) pageViewTitle
{
	return @"MainPageTitle";
}

@end
