//
//  Copyright (c) SRG SSR. All rights reserved.
//
//  License information is available from the LICENSE file.
//

#import <SRGAnalytics/SRGAnalytics.h>
#import <SRGMediaPlayer/SRGMediaPlayer.h>

#import "MainTableViewController.h"

#import "AppDelegate.h"
#import "SimpleViewController.h"
#import "SegmentsPlayerViewController.h"
#import "SRGMediaPlayerController+SRGAnalytics_MediaPlayer.h"

@interface MainTableViewController () <UITableViewDelegate, SRGAnalyticsViewTracking>

@end

@implementation MainTableViewController

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
	SimpleViewController *controller = [segue destinationViewController];
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
        SRGMediaPlayerViewController *playerViewController = [[SRGMediaPlayerViewController alloc] initWithContentURL:[self contentURLForIdentifier:cell.reuseIdentifier]
                                                                                                      analyticsLabels:@{ @"ns_st_ep" : [self contentURLNameForIdentifier:cell.reuseIdentifier],
                                                                                                                         @"ns_st_pn" : @(1)}
                                                                                                             userInfo:nil];
		[self presentViewController:playerViewController animated:YES completion:nil];
	}
    else if ([cell.reuseIdentifier hasPrefix:@"SegmentsMediaPlayer"])
    {
        SegmentsPlayerViewController *segmentsPlayerViewController = [[SegmentsPlayerViewController alloc] initWithContentURL:[self contentURLForIdentifier:cell.reuseIdentifier]
                                                                                                                     segments:[self segmentsForIdentifier:cell.reuseIdentifier]];
        [self presentViewController:segmentsPlayerViewController animated:YES completion:nil];
    }
	else if ([cell.reuseIdentifier isEqualToString:@"PushNotificationCell"])
	{
		UIApplication *application = [UIApplication sharedApplication];
        [(AppDelegate *)application.delegate application:application didReceiveRemoteNotification:@{} fetchCompletionHandler:^(UIBackgroundFetchResult result) {}];
	}
    else if ([cell.reuseIdentifier isEqualToString:@"HiddenEventWithNoTitleCell"]) {
        [[SRGAnalyticsTracker sharedTracker] trackHiddenEventWithTitle:@""];
    }
    else if ([cell.reuseIdentifier isEqualToString:@"HiddenEventWithTitleCell"]) {
        [[SRGAnalyticsTracker sharedTracker] trackHiddenEventWithTitle:@"Title"];
    }
    else if ([cell.reuseIdentifier isEqualToString:@"HiddenEventWithTitleAndCustomLabelsCell"]) {
        [[SRGAnalyticsTracker sharedTracker] trackHiddenEventWithTitle:@"Title" customLabels:@{ @"srg_ap_cu" : @"custom" }];
    }
}



#pragma mark - URLS and Segments

- (NSURL *)contentURLForIdentifier:(NSString *)identifier
{
	NSString *urlString = nil;
	if ([identifier hasSuffix:@"LiveCell"])
	{
		urlString = @"http://esioslive6-i.akamaihd.net/hls/live/202892/AL_P_ESP1_FR_FRA/playlist.m3u8";
	}
	else if ([identifier hasSuffix:@"VODCell"] || [identifier hasSuffix:@"SegmentsCell"])
	{
		urlString = @"http://stream-i.rts.ch/i/tp/1993/tp_10071993-,450,k.mp4.csmil/master.m3u8";
	}
    else if ([identifier hasSuffix:@"DVRCell"])
    {
        urlString = @"https://wowza.jwplayer.com/live/jelly.stream/playlist.m3u8?DVR";
    }
    else if ([identifier hasSuffix:@"SegmentsMediaPlayerMultiplePhysicalSegmentsAODCell"])
    {
        urlString = @"http://srfaodorigin-vh.akamaihd.net/i/world/echo-der-zeit/7ea975b2-fafe-487b-a6a5-9b7d2461ff05.,q10,q20,.mp4.csmil/master.m3u8";
    }
    else if ([identifier hasSuffix:@"SegmentsMediaPlayerMultiplePhysicalSegmentsAODCell_2"])
    {
        urlString = @"http://srfaodorigin-vh.akamaihd.net/i/world/echo-der-zeit/5cc0475c-0f87-4c62-85d3-c43857094543.,q10,q20,.mp4.csmil/master.m3u8";
    }
    
	return [NSURL URLWithString:urlString];
}

- (NSString *)contentURLNameForIdentifier:(NSString *)identifier
{
    NSString *name = nil;
    if ([identifier hasSuffix:@"LiveCell"])
    {
        name = @"Eurosport";
    }
    else if ([identifier hasSuffix:@"VODCell"] || [identifier hasSuffix:@"SegmentsCell"])
    {
        name = @"Téléjournal";
    }
    else if ([identifier hasSuffix:@"DVRCell"])
    {
        name = @"Clock";
    }
    else if ([identifier hasSuffix:@"SegmentsMediaPlayerMultiplePhysicalSegmentsAODCell"])
    {
        name = @"SRF 1";
    }
    else if ([identifier hasSuffix:@"SegmentsMediaPlayerMultiplePhysicalSegmentsAODCell_2"])
    {
        name = @"SRF AOD";
    }
    
    return name;
}

- (NSArray<Segment *> *)segmentsForIdentifier:(NSString *)identifier
{
    if ([identifier rangeOfString:@"MultipleSegments"].length != 0)
    {
        const NSTimeInterval segment1StartTime = 2.;
        const NSTimeInterval segment1Duration = 3.;
        
        const NSTimeInterval segment2StartTime = segment1StartTime + segment1Duration;
        const NSTimeInterval segment2Duration = 5.;
        
        const NSTimeInterval segment3StartTime = 40.;
        const NSTimeInterval segment3Duration = 30.;
        
        Segment *segment1 = [[Segment alloc] initWithDictionary:@{@"name" : @"segment1",
                                                                  @"startTime" : @(segment1StartTime * 1000),
                                                                  @"duration" : @(segment1Duration * 1000),
                                                                  @"position" : @(2)}];
        
        Segment *segment2 = [[Segment alloc] initWithDictionary:@{@"name" : @"segment2",
                                                                  @"startTime" : @(segment2StartTime * 1000),
                                                                  @"duration" : @(segment2Duration * 1000),
                                                                  @"position" : @(3)}];;
        
        Segment *segment3 = [[Segment alloc] initWithDictionary:@{@"name" : @"segment3",
                                                                  @"startTime" : @(segment3StartTime * 1000),
                                                                  @"duration" : @(segment3Duration * 1000),
                                                                  @"position" : @(4)}];;
        
        return @[segment1, segment2, segment3];
    }
//    else if ([identifier isEqualToString:@"SegmentsMediaPlayerMultiplePhysicalSegmentsAODCell"])
//    {
//        Segment *physicalSegment1 = [[Segment alloc] initWithName:@"physical_segment1" timeRange:CMTimeRangeMake(kCMTimeZero, CMTimeMakeWithSeconds(3600., 1.))];
//        Segment *physicalSegment2 = [[Segment alloc] initWithName:@"physical_segment2" timeRange:CMTimeRangeMake(kCMTimeZero, CMTimeMakeWithSeconds(1200., 1.))];
//        return @[physicalSegment1, physicalSegment2];
//    }
//    else
//    {
//        Segment *fullLengthSegment = [[Segment alloc] initWithName:@"full_length" timeRange:CMTimeRangeMake(kCMTimeZero, CMTimeMakeWithSeconds(3600., 1.))];
//        
//        CMTimeRange timeRange = CMTimeRangeMake(CMTimeMakeWithSeconds(2., 1.), CMTimeMakeWithSeconds(15., 1.));
//        Segment *segment = [[Segment alloc] initWithName:@"segment" timeRange:timeRange];
//        return @[fullLengthSegment, segment];
//    }
    return nil;
}

#pragma mark - SRGAnalyticsViewTracking

- (NSString *) srg_pageViewTitle
{
	return @"MainPageTitle";
}

@end
