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

- (void)setUp
{
    [super setUp];
    [KIFSystemTestActor setDefaultTimeout:30.0];
}
- (void)test_1_OpenDefaultMediaPlayerControllerSendsLiveStreamStartMeasurement
{
	[tester tapRowAtIndexPath:[NSIndexPath indexPathForRow:0 inSection:1] inTableViewWithAccessibilityIdentifier:@"tableView"];
	
	NSNotification *notification = [system waitForNotificationName:RTSAnalyticsComScoreRequestDidFinishNotification object:nil];
	NSDictionary *labels = notification.userInfo[RTSAnalyticsComScoreRequestLabelsUserInfoKey];
    XCTAssertEqualObjects(labels[@"ns_st_ev"], @"play");
	XCTAssertEqualObjects(labels[@"ns_st_li"], @"1");
	XCTAssertEqualObjects(labels[@"srg_enc"], @"9");
    
    [tester waitForTimeInterval:2.0f];
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
    
    [tester waitForTimeInterval:2.0f];
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
// receive segment labels. After the segment has been played through, we receive full-length labels again
- (void)test_5_OpenMediaPlayerAndPlayOneSegment
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
    
    // Play the segment. Expect full-length pause immediately followed by segment play
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

    // Let the segment be played through, at which point resumes with the full-length
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
    
    // Close
    {
        [tester tapViewWithAccessibilityLabel:@"Done"];
    }
    
    [tester waitForTimeInterval:2.0f];
}

/**
 * Important remark about tests below: When studying transitions between full-length and segments, we receive a pause followed
 * by a play. Both events MUST be dealt with in a single waiting block, otherwise race conditions might arise because of how 
 * notification waiting is usually implemented (run loop). Doing so is not possible with the current KIF implementation, we 
 * therefore use XCTest. KIF is only used to trigger UI events
 */

// Expected behavior: When playing the full-length, we receive full-length labels. When a segment has been selected by the user, we
// receive segment labels. After the segment has been played through, we receive full-length labels again. This is the behavior
// even if there is a segment right after the segment, since segment labels are sent over only if the user has selected the segment.
- (void)test_6_OpenMediaPlayerAndPlayTwoConsecutiveSegments
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
    
    // Go to 1st segment. Expect full-length pause immediately followed by segment play
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
    
    // Playback continues after the first segment. Even if a second segment immediately follows it, we switch to the full-length
    // since the user does not select it explicitly
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
            // Play for the full-length (even if there is a segment, it was not selected by the user)
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
        [self waitForExpectationsWithTimeout:60. handler:nil];
    }
    
    // Close
    {
        [tester tapViewWithAccessibilityLabel:@"Done"];
    }
    
    [tester waitForTimeInterval:2.0f];
}

// Expected behavior: When playing the full-length, we receive full-length labels. When a segment has been selected by the user, we
// receive segment labels. When switching segments manually, we receveive labels for the new segment
- (void)test_7_OpenMediaPlayerAndManuallySwitchBetweenSegments
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
    
    // Go to 1st segment. Expect full-length pause immediately followed by segment play
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
    
    // Manually switch to the second segment. Expect first segment pause immediately followed by second segment play
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
        
        [tester tapViewWithAccessibilityLabel:@"Segment #2"];
        
        [self waitForExpectationsWithTimeout:60. handler:nil];
    }
    
    // Close
    {
        [tester tapViewWithAccessibilityLabel:@"Done"];
    }
    
    [tester waitForTimeInterval:2.0f];
}

// Expected behavior: When playing a segment, selecting the same segment generates a pause for the segment, followed by a play
// for the same segment
- (void)test_8_OpenMediaPlayerAndSwitchToTheSameSegment
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
    
    // Go to 1st segment. Expect full-length pause immediately followed by segment play
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
    
    // Manually switch to the same segment. Expect segment pause and play for the same segment
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
            // Play for the full-length (even if there is a segment, it was not selected by the user)
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
        
        [self waitForExpectationsWithTimeout:60. handler:nil];
    }
    
    // Close
    {
        [tester tapViewWithAccessibilityLabel:@"Done"];
    }
    
    [tester waitForTimeInterval:2.0f];
}

// Expected behavior: When playing a segment, seeking anywhere must emit a pause event for the segment, followed by a play for the full-length
- (void)openMediaPlayerAndPlaySegmentBeforeSeekingAtTime:(NSTimeInterval)time
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
        
        [tester tapRowAtIndexPath:[NSIndexPath indexPathForRow:4 inSection:1] inTableViewWithAccessibilityIdentifier:@"tableView"];
        
        [self waitForExpectationsWithTimeout:10. handler:nil];
    }
    
    // Go to 1st segment. Expect full-length pause immediately followed by segment play
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
                XCTAssertEqualObjects(labels[@"clip_type"], @"segment");
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
    
    // Seek outside the segment. Expect segment pause followed by full-length play
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
                XCTAssertEqualObjects(labels[@"clip_type"], @"segment");
                
                // Not finished yet
                return NO;
            }
            // Play for the first segment
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
        
        [tester setValue:time forSliderWithAccessibilityLabel:@"slider"];
                
        [self waitForExpectationsWithTimeout:10. handler:nil];
    }
    
    // Close
    {
        [tester tapViewWithAccessibilityLabel:@"Done"];
    }
    
    [tester waitForTimeInterval:2.0f];
}

- (void)test_9_OpenMediaPlayerAndPlaySegmentBeforeSeekingOutsideIt
{
    [self openMediaPlayerAndPlaySegmentBeforeSeekingAtTime:40.];
}

- (void)test_10_OpenMediaPlayerAndPlaySegmentBeforeSeekingInsideIt
{
    [self openMediaPlayerAndPlaySegmentBeforeSeekingAtTime:3.];
}

// Expected behavior: When closing the player while a segment is being played, no end event is expected for the segment, only for the
// full-length
- (void)test_11_OpenMediaPlayerAndPlaySegmentWhileClosingThePlayer
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
        
        [tester tapRowAtIndexPath:[NSIndexPath indexPathForRow:4 inSection:1] inTableViewWithAccessibilityIdentifier:@"tableView"];
        
        [self waitForExpectationsWithTimeout:10. handler:nil];
    }
    
    // Go to 1st segment. Expect full-length pause immediately followed by segment play
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
                XCTAssertEqualObjects(labels[@"clip_type"], @"segment");
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
    
    // Close the player. Only an end event is expected for the full-length
    {
        [self expectationForNotification:RTSAnalyticsComScoreRequestDidFinishNotification object:nil handler:^BOOL(NSNotification *notification) {
            NSDictionary *labels = notification.userInfo[RTSAnalyticsComScoreRequestLabelsUserInfoKey];
            
            // Skip heartbeats
            if ([labels[@"ns_st_ev"] isEqualToString:@"hb"])
            {
                return NO;
            }
            
            XCTAssertEqualObjects(labels[@"ns_st_ev"], @"end");
            XCTAssertEqualObjects(labels[@"clip_type"], @"full_length");
            return YES;
        }];
        
        [tester tapViewWithAccessibilityLabel:@"Done"];
        
        [self waitForExpectationsWithTimeout:10. handler:nil];
    }
    
    [tester waitForTimeInterval:2.0f];
}

// Try to seek into a blocked segment. Must pause at on the full-length
- (void)test_12_OpenMediaPlayerAndSeekIntoBlockedSegment
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
        [tester tapRowAtIndexPath:[NSIndexPath indexPathForRow:5 inSection:1] inTableViewWithAccessibilityIdentifier:@"tableView"];
        
        [self waitForExpectationsWithTimeout:10. handler:nil];
    }
    
    // Seek into the blocked segment
    {
        [self expectationForNotification:RTSAnalyticsComScoreRequestDidFinishNotification object:nil handler:^BOOL(NSNotification *notification) {
            NSDictionary *labels = notification.userInfo[RTSAnalyticsComScoreRequestLabelsUserInfoKey];
            
            // Skip heartbeats
            if ([labels[@"ns_st_ev"] isEqualToString:@"hb"])
            {
                return NO;
            }
            
            XCTAssertEqualObjects(labels[@"ns_st_ev"], @"pause");
            XCTAssertEqualObjects(labels[@"clip_type"], @"full_length");
            return YES;
        }];
        
        [tester setValue:43. forSliderWithAccessibilityLabel:@"slider"];
        
        [self waitForExpectationsWithTimeout:10. handler:nil];
    }
    
    [NSThread sleepForTimeInterval:3.];
    
    // Resume playback
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
        
        [tester tapViewWithAccessibilityLabel:@"play"];
        
        [self waitForExpectationsWithTimeout:10. handler:nil];
    }
    
    // Close
    {
        [tester tapViewWithAccessibilityLabel:@"Done"];
    }
    
    [tester waitForTimeInterval:2.0f];
}

@end
