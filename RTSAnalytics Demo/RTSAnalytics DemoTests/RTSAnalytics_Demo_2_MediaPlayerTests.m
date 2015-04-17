//
//  Created by Frédéric Humbert-Droz on 17/04/15.
//  Copyright (c) 2015 RTS. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <XCTest/XCTest.h>
#import <KIF/KIF.h>

@interface RTSAnalytics_Demo_2_MediaPlayerTests : KIFTestCase

@end

@implementation RTSAnalytics_Demo_2_MediaPlayerTests

- (void)test_1_OpenDefaultMediaPlayerControllerSendsLiveStreamStartMeasurement
{
	[tester tapRowAtIndexPath:[NSIndexPath indexPathForRow:0 inSection:1] inTableViewWithAccessibilityIdentifier:@"tableView"];
	
	NSNotification *notification = [system waitForNotificationName:@"RTSAnalyticsComScoreRequestDidFinish" object:nil];
	NSDictionary *labels = notification.userInfo[@"RTSAnalyticsLabels"];
    XCTAssertEqualObjects(@"play", labels[@"ns_st_ev"]);
	XCTAssertEqualObjects(@"1",    labels[@"ns_st_li"]);
}

- (void)test_2_CloseMediaPlayerSendsStreamLiveEndMeasurement
{
	NSNotification *notification = [system waitForNotificationName:@"RTSAnalyticsComScoreRequestDidFinish" object:nil whileExecutingBlock:^{
		[tester tapViewWithAccessibilityLabel:@"Done"];
	}];
	
	NSDictionary *labels = notification.userInfo[@"RTSAnalyticsLabels"];
	XCTAssertEqualObjects(@"end", labels[@"ns_st_ev"]);
	XCTAssertEqualObjects(@"1",   labels[@"ns_st_li"]);
	
	[tester waitForTimeInterval:2.0f];
}

- (void)test_3_OpenDefaultMediaPlayerControllerSendsLiveStreamStartMeasurement
{
	[tester tapRowAtIndexPath:[NSIndexPath indexPathForRow:1 inSection:1] inTableViewWithAccessibilityIdentifier:@"tableView"];
	
	NSNotification *notification = [system waitForNotificationName:@"RTSAnalyticsComScoreRequestDidFinish" object:nil];
	NSDictionary *labels = notification.userInfo[@"RTSAnalyticsLabels"];
	XCTAssertEqualObjects(@"play", labels[@"ns_st_ev"]);
	XCTAssertEqualObjects(@"0",    labels[@"ns_st_li"]);
}

- (void)test_4_CloseMediaPlayerSendsStreamLiveEndMeasurement
{
	NSNotification *notification = [system waitForNotificationName:@"RTSAnalyticsComScoreRequestDidFinish" object:nil whileExecutingBlock:^{
		[tester tapViewWithAccessibilityLabel:@"Done"];
	}];
	
	NSDictionary *labels = notification.userInfo[@"RTSAnalyticsLabels"];
	XCTAssertEqualObjects(@"end", labels[@"ns_st_ev"]);
	XCTAssertEqualObjects(@"0",    labels[@"ns_st_li"]);
	
	[tester waitForTimeInterval:2.0f];
}

@end
