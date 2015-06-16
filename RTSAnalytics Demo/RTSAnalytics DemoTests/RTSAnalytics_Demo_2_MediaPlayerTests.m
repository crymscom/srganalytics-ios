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

// Expected behavior: When playing the full-length, we receive full-length labels. When a segment has been selected by the user, we
// receive segment labels. After the segment has been played through, we receive full-length labels again. Each transition is characterized
// by a pause / play event combination, since two consecutive identical Comscore events are sent only once (the first event is sent, the
// following ones are ignored)
- (void)test_5_OpenDefaultMediaPlayerControllerAndPlaySegment
{
    // Initial full-length play when opening
    {
        [self expectationForNotification:RTSAnalyticsComScoreRequestDidFinishNotification object:nil handler:^BOOL(NSNotification *notification) {
            NSDictionary *labels = notification.userInfo[RTSAnalyticsComScoreRequestLabelsUserInfoKey];
            
            // Skip view-related events
            if ([labels[@"name"] isEqualToString:@"app.mainpagetitle"])
            {
                return NO;
            }
            
            XCTAssertEqualObjects(labels[@"ns_st_ev"], @"play");
            XCTAssertEqualObjects(labels[@"clip_type"], @"full_length");
            return YES;
        }];
        
        // Open 1-segment demo
        [tester tapRowAtIndexPath:[NSIndexPath indexPathForRow:4 inSection:1] inTableViewWithAccessibilityIdentifier:@"tableView"];
        
        [self waitForExpectationsWithTimeout:10. handler:nil];
    }
    
    // Wait 3 seconds to hear the transition to the new segment (optional)
    [NSThread sleepForTimeInterval:3.];
    
    // Play the segment. Expect full-length pause immediately followed by segment play. We MUST deal with both in a single waiting block,
    // otherwise race conditions might arise because of how waiting is implemented (run loop). Doing so is not possible with the current
    // KIF implementation, we therefore use XCTest instead
    {
        __block NSInteger numberOfNotificationsReceived = 0;
        [self expectationForNotification:RTSAnalyticsComScoreRequestDidFinishNotification object:nil handler:^BOOL(NSNotification *notification) {
            NSDictionary *labels = notification.userInfo[RTSAnalyticsComScoreRequestLabelsUserInfoKey];
            
            // Skip heartbeats
            if ([labels[@"ns_st_ev"] isEqualToString:@"hb"])
            {
                return NO;
            }
            
            numberOfNotificationsReceived++;
            
            // Pause for the full-length
            if (numberOfNotificationsReceived == 1)
            {
                XCTAssertEqualObjects(labels[@"ns_st_ev"], @"pause");
                XCTAssertEqualObjects(labels[@"clip_type"], @"full_length");
                
                // Not finished yet
                return NO;
            }
            // Play for the segment
            else if (numberOfNotificationsReceived == 2)
            {
                XCTAssertEqualObjects(labels[@"ns_st_ev"], @"play");
                XCTAssertEqualObjects(labels[@"clip_type"], @"segment");
                return YES;
            }
            // E.g.
            else
            {
                return NO;
            }
        }];
        
        // Tap on the button playing the first segment
        [tester tapViewWithAccessibilityLabel:@"Segment #1"];
        
        [self waitForExpectationsWithTimeout:10. handler:nil];
    }

    // Let the segment be played through. A pause / play notification pair for the segment, respective full-length must be received when switching
    // to the full-length again
    {
        __block NSInteger numberOfNotificationsReceived = 0;
        [self expectationForNotification:RTSAnalyticsComScoreRequestDidFinishNotification object:nil handler:^BOOL(NSNotification *notification) {
            NSDictionary *labels = notification.userInfo[RTSAnalyticsComScoreRequestLabelsUserInfoKey];
            
            // Skip heartbeats
            if ([labels[@"ns_st_ev"] isEqualToString:@"hb"])
            {
                return NO;
            }
            
            numberOfNotificationsReceived++;
            
            // Pause for the segment
            if (numberOfNotificationsReceived == 1)
            {
                XCTAssertEqualObjects(labels[@"ns_st_ev"], @"pause");
                XCTAssertEqualObjects(labels[@"clip_type"], @"segment");
                
                // Not finished yet
                return NO;
            }
            // Play for the full-length
            else if (numberOfNotificationsReceived == 2)
            {
                XCTAssertEqualObjects(labels[@"ns_st_ev"], @"play");
                XCTAssertEqualObjects(labels[@"clip_type"], @"full_length");
                return YES;
            }
            // E.g.
            else
            {
                return NO;
            }
        }];
        [self waitForExpectationsWithTimeout:10. handler:nil];
    }
}

// Expected behavior: When playing the full-length, we receive full-length labels. When a segment has been selected by the user, we
// receive segment labels. After the segment has been played through, we receive full-length labels again. This is the behavior
// even if there is a segment right after the segment, since segment labels are sent over iff the user has selected the segment.
// Each transition is characterized by a pause / play event combination, since two consecutive identical Comscore events are sent
// only once (the first event is sent, the following ones are ignored)
- (void)test_6_OpenDefaultMediaPlayerControllerAndPlayConsecutiveSegments
{
    // Initial full-length play when opening
    {
        [self expectationForNotification:RTSAnalyticsComScoreRequestDidFinishNotification object:nil handler:^BOOL(NSNotification *notification) {
            NSDictionary *labels = notification.userInfo[RTSAnalyticsComScoreRequestLabelsUserInfoKey];
            
            // Skip view-related events
            if ([labels[@"name"] isEqualToString:@"app.mainpagetitle"])
            {
                return NO;
            }
            
            XCTAssertEqualObjects(labels[@"ns_st_ev"], @"play");
            XCTAssertEqualObjects(labels[@"clip_type"], @"full_length");
            return YES;
        }];
        
        [tester tapRowAtIndexPath:[NSIndexPath indexPathForRow:5 inSection:1] inTableViewWithAccessibilityIdentifier:@"tableView"];
        
        [self waitForExpectationsWithTimeout:10. handler:nil];
    }
    
    // Wait 3 seconds to hear the transition to the new segment (optional)
    [NSThread sleepForTimeInterval:3.];
    
    // Go to 1st segment. Expect full-length pause immediately followed by segment play. We MUST deal with both in a single waiting block,
    // otherwise race conditions might arise because of how waiting is implemented (run loop). Doing so is not possible with the current
    // KIF implementation, we therefore use XCTest instead
    {
        __block NSInteger numberOfNotificationsReceived = 0;
        [self expectationForNotification:RTSAnalyticsComScoreRequestDidFinishNotification object:nil handler:^BOOL(NSNotification *notification) {
            NSDictionary *labels = notification.userInfo[RTSAnalyticsComScoreRequestLabelsUserInfoKey];
            
            // Skip heartbeats
            if ([labels[@"ns_st_ev"] isEqualToString:@"hb"])
            {
                return NO;
            }
            
            numberOfNotificationsReceived++;
            
            // Pause for the full-length
            if (numberOfNotificationsReceived == 1)
            {
                XCTAssertEqualObjects(labels[@"ns_st_ev"], @"pause");
                XCTAssertEqualObjects(labels[@"clip_type"], @"full_length");
                
                // Not finished yet
                return NO;
            }
            // Play for the first segment
            else if (numberOfNotificationsReceived == 2)
            {
                XCTAssertEqualObjects(labels[@"ns_st_ev"], @"play");
                XCTAssertEqualObjects(labels[@"clip_type"], @"segment1");
                return YES;
            }
            // E.g.
            else
            {
                return NO;
            }
        }];
        
        [tester tapViewWithAccessibilityLabel:@"Segment #1"];
        
        [self waitForExpectationsWithTimeout:10. handler:nil];
    }
    
    // Playback switches over to the second segment. We exit a user-selected segment, we thus expect a pause / play event pair with the respective
    // segment labels
    {
        __block NSInteger numberOfNotificationsReceived = 0;
        [self expectationForNotification:RTSAnalyticsComScoreRequestDidFinishNotification object:nil handler:^BOOL(NSNotification *notification) {
            NSDictionary *labels = notification.userInfo[RTSAnalyticsComScoreRequestLabelsUserInfoKey];
            
            // Skip heartbeats
            if ([labels[@"ns_st_ev"] isEqualToString:@"hb"])
            {
                return NO;
            }
            
            numberOfNotificationsReceived++;
            
            // Pause for the first segment
            if (numberOfNotificationsReceived == 1)
            {
                XCTAssertEqualObjects(labels[@"ns_st_ev"], @"pause");
                XCTAssertEqualObjects(labels[@"clip_type"], @"segment1");
                
                // Not finished yet
                return NO;
            }
            // Play for the second segment
            else if (numberOfNotificationsReceived == 2)
            {
                XCTAssertEqualObjects(labels[@"ns_st_ev"], @"play");
                XCTAssertEqualObjects(labels[@"clip_type"], @"segment2");
                return YES;
            }
            // E.g.
            else
            {
                return NO;
            }
        }];
        [self waitForExpectationsWithTimeout:60. handler:nil];
    }
}

@end
