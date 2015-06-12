//
//  Created by Frédéric Humbert-Droz on 17/04/15.
//  Copyright (c) 2015 RTS. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <XCTest/XCTest.h>
#import <KIF/KIF.h>
#import <RTSMediaPlayer/RTSMediaSegmentsController.h>

extern NSString * const RTSAnalyticsComScoreRequestDidFinishNotification;
extern NSString * const RTSAnalyticsComScoreRequestLabelsUserInfoKey;

@interface RTSAnalytics_Demo_2_MediaPlayerTests : KIFTestCase

@end

@implementation RTSAnalytics_Demo_2_MediaPlayerTests

- (void)test_1_OpenDefaultMediaPlayerControllerSendsLiveStreamStartMeasurement
{
	[tester tapRowAtIndexPath:[NSIndexPath indexPathForRow:0 inSection:1] inTableViewWithAccessibilityIdentifier:@"tableView"];
	
	NSNotification *notification = [system waitForNotificationName:RTSAnalyticsComScoreRequestDidFinishNotification object:nil];
	NSDictionary *labels = notification.userInfo[RTSAnalyticsComScoreRequestLabelsUserInfoKey];
    XCTAssertEqualObjects(labels[@"ns_st_ev"], @"play");
	XCTAssertEqualObjects(labels[@"ns_st_li"], @"1");
	XCTAssertEqualObjects(labels[@"srg_enc"], @"9");
}

- (void)test_2_CloseMediaPlayerSendsStreamLiveEndMeasurement
{
	NSNotification *notification = [system waitForNotificationName:RTSAnalyticsComScoreRequestDidFinishNotification object:nil whileExecutingBlock:^{
		[tester tapViewWithAccessibilityLabel:@"Done"];
	}];
	
	NSDictionary *labels = notification.userInfo[RTSAnalyticsComScoreRequestLabelsUserInfoKey];
	XCTAssertEqualObjects(labels[@"ns_st_ev"], @"end");
	XCTAssertEqualObjects(labels[@"ns_st_li"], @"1");
	XCTAssertEqualObjects(labels[@"srg_enc"], @"9");
	
	[tester waitForTimeInterval:2.0f];
}

- (void)test_3_OpenDefaultMediaPlayerControllerSendsLiveStreamStartMeasurement
{
	[tester tapRowAtIndexPath:[NSIndexPath indexPathForRow:1 inSection:1] inTableViewWithAccessibilityIdentifier:@"tableView"];
	
	NSNotification *notification = [system waitForNotificationName:RTSAnalyticsComScoreRequestDidFinishNotification object:nil];
	NSDictionary *labels = notification.userInfo[RTSAnalyticsComScoreRequestLabelsUserInfoKey];
	XCTAssertEqualObjects(labels[@"ns_st_ev"], @"play");
	XCTAssertEqualObjects(labels[@"ns_st_li"], @"0");
	XCTAssertNil(labels[@"srg_enc"]);
}

- (void)test_4_CloseMediaPlayerSendsStreamLiveEndMeasurement
{
	NSNotification *notification = [system waitForNotificationName:RTSAnalyticsComScoreRequestDidFinishNotification object:nil whileExecutingBlock:^{
		[tester tapViewWithAccessibilityLabel:@"Done"];
	}];
	
	NSDictionary *labels = notification.userInfo[RTSAnalyticsComScoreRequestLabelsUserInfoKey];
	XCTAssertEqualObjects(labels[@"ns_st_ev"], @"end");
	XCTAssertEqualObjects(labels[@"ns_st_li"], @"0");
	XCTAssertNil(labels[@"srg_enc"]);
	
	[tester waitForTimeInterval:2.0f];
}

- (void)test_5_OpenDefaultMediaPlayerControllerAndPlaySegment
{
    [tester tapRowAtIndexPath:[NSIndexPath indexPathForRow:4 inSection:1] inTableViewWithAccessibilityIdentifier:@"tableView"];
    
    // Wait for the video to play
    {
        NSNotification *notification = [system waitForNotificationName:RTSAnalyticsComScoreRequestDidFinishNotification object:nil];
        NSDictionary *labels = notification.userInfo[RTSAnalyticsComScoreRequestLabelsUserInfoKey];
        XCTAssertEqualObjects(labels[@"ns_st_ev"], @"play");
    }
    
    [NSThread sleepForTimeInterval:3.];
    
    // Switch to the first segment
    // TODO: It would be nice to test check that the transition is made through a pause / play, but sadly neither KIF nor XCTest see all
    //       notifications. One possible solution could be to accumulate those notifications into an array, and to check and clear it
    //       when KIF or XCTest manages to catch a notification
    {
        [system waitForNotificationName:RTSMediaPlaybackSegmentDidChangeNotification object:nil whileExecutingBlock:^{
            [tester tapViewWithAccessibilityLabel:@"Segment #1"];
        }];
        
        // Catch a heartbeat afterwards
#if 0
        NSNotification *notification = [system waitForNotificationName:RTSAnalyticsComScoreRequestDidFinishNotification object:nil];
        NSDictionary *labels = notification.userInfo[RTSAnalyticsComScoreRequestLabelsUserInfoKey];
        XCTAssertEqualObjects(labels[@"ns_st_ev"], @"hb");
#endif
    }
    
    [tester waitForTimeInterval:2.0f];
}

@end
