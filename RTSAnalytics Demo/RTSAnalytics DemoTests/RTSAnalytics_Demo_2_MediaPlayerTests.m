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
    
    // Initial play when opening
    {
        NSNotification *notification = [system waitForNotificationName:RTSAnalyticsComScoreRequestDidFinishNotification object:nil];
        NSDictionary *labels = notification.userInfo[RTSAnalyticsComScoreRequestLabelsUserInfoKey];
        XCTAssertEqualObjects(labels[@"ns_st_ev"], @"play");
        XCTAssertEqualObjects(labels[@"clip_type"], @"full_length");
    }
    
    // Wait 3 seconds to hear the transition to the new segment
    [NSThread sleepForTimeInterval:3.];
    
    // Go to 1st segment. Expect pause immediately followed by play. Must deal with both in a single waiting block, otherwise race
    // conditions might arise because of how waiting is implemented (run loop). This is not possible with the current KIF implementation,
    // we must therefore revert to XCTest instead
    {
        __block NSInteger numberOfNotificationsReceived = 0;
        [self expectationForNotification:RTSAnalyticsComScoreRequestDidFinishNotification object:nil handler:^BOOL(NSNotification *notification) {
            numberOfNotificationsReceived++;
            
            NSDictionary *labels = notification.userInfo[RTSAnalyticsComScoreRequestLabelsUserInfoKey];

            // Pause notification
            if (numberOfNotificationsReceived == 1)
            {
                XCTAssertEqualObjects(labels[@"ns_st_ev"], @"pause");
                XCTAssertEqualObjects(labels[@"clip_type"], @"full_length");
                
                // Not finished yet
                return NO;
            }
            // Play notification
            else if (numberOfNotificationsReceived == 2)
            {
                XCTAssertEqualObjects(labels[@"ns_st_ev"], @"play");
                XCTAssertEqualObjects(labels[@"clip_type"], @"segment");
                return YES;
            }
            else
            {
                return NO;
            }
        }];
        
        [tester tapViewWithAccessibilityLabel:@"Segment #1"];
        
        [self waitForExpectationsWithTimeout:10. handler:nil];
    }
}

@end
