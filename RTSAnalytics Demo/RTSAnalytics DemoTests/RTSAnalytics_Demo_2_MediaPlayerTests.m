//
//  Copyright (c) SRG. All rights reserved.
//
//  License information is available from the LICENSE file.
//

#import <UIKit/UIKit.h>
#import <XCTest/XCTest.h>
#import <KIF/KIF.h>
#import <SRGMediaPlayer/RTSMediaSegmentsController.h>

// Need some flexibility when testing times as they might not be exact. Introduce several arbitrary tolerance levels which can
// be used depending on the precision available
#define AssertIsWithin1Second(expression1, expression2) XCTAssertTrue(fabs([expression1 doubleValue] - expression2) < 1000.)
#define AssertIsWithin20Seconds(expression1, expression2) XCTAssertTrue(fabs([expression1 doubleValue] - expression2) < 20000.)

@interface RTSAnalytics_Demo_2_MediaPlayerTests : KIFTestCase

@end

@implementation RTSAnalytics_Demo_2_MediaPlayerTests

- (void)setUp
{
    [super setUp];
    [KIFSystemTestActor setDefaultTimeout:30.0];
}

#warning Disabled because of missing stream
- (void)disabled_testOpenDefaultMediaPlayerAndPlayLiveStreamThenClose
{
	[tester tapRowAtIndexPath:[NSIndexPath indexPathForRow:0 inSection:1] inTableViewWithAccessibilityIdentifier:@"tableView"];
	
    {
        NSNotification *notification = [system waitForNotificationName:@"RTSAnalyticsComScoreRequestDidFinish" object:nil];
        NSDictionary *labels = notification.userInfo[@"RTSAnalyticsLabels"];
        XCTAssertEqualObjects(labels[@"ns_st_ev"], @"play");
        XCTAssertEqualObjects(labels[@"ns_st_li"], @"1");
        AssertIsWithin1Second(labels[@"ns_st_po"], 0.);
        XCTAssertEqualObjects(labels[@"srg_enc"], @"9");
        AssertIsWithin1Second(labels[@"srg_timeshift"], 0.);
        
        [tester waitForTimeInterval:2.0f];
    }
    
    {
        NSNotification *notification = [system waitForNotificationName:@"RTSAnalyticsComScoreRequestDidFinish" object:nil whileExecutingBlock:^{
            [tester tapViewWithAccessibilityLabel:@"Done"];
        }];
        
        NSDictionary *labels = notification.userInfo[@"RTSAnalyticsLabels"];
        XCTAssertEqualObjects(labels[@"ns_st_ev"], @"end");
        XCTAssertEqualObjects(labels[@"ns_st_li"], @"1");
        AssertIsWithin1Second(labels[@"ns_st_po"], 2000.);
        XCTAssertEqualObjects(labels[@"srg_enc"], @"9");
        AssertIsWithin1Second(labels[@"srg_timeshift"], 0.);
        
        [tester waitForTimeInterval:2.0f];
    }
}

- (void)testOpenDefaultMediaPlayerAndPlayVODStreamThenClose
{
	[tester tapRowAtIndexPath:[NSIndexPath indexPathForRow:1 inSection:1] inTableViewWithAccessibilityIdentifier:@"tableView"];

    {
        NSNotification *notification = [system waitForNotificationName:@"RTSAnalyticsComScoreRequestDidFinish" object:nil];
        NSDictionary *labels = notification.userInfo[@"RTSAnalyticsLabels"];
        XCTAssertEqualObjects(labels[@"ns_st_ev"], @"play");
        XCTAssertNil(labels[@"ns_st_li"], @"The parameter ns_st_li must only sent for live streams");
        AssertIsWithin1Second(labels[@"ns_st_po"], 0.);
        XCTAssertNil(labels[@"srg_enc"]);
        XCTAssertNil(labels[@"srg_timeshift"], @"The parameter srg_timeshift must only sent for live streams");
        
        [tester waitForTimeInterval:2.0f];
    }
    
    {
        NSNotification *notification = [system waitForNotificationName:@"RTSAnalyticsComScoreRequestDidFinish" object:nil whileExecutingBlock:^{
            [tester tapViewWithAccessibilityLabel:@"Done"];
        }];
        
        NSDictionary *labels = notification.userInfo[@"RTSAnalyticsLabels"];
        XCTAssertEqualObjects(labels[@"ns_st_ev"], @"end");
        XCTAssertNil(labels[@"ns_st_li"], @"The parameter ns_st_li must only sent for live streams");
        AssertIsWithin1Second(labels[@"ns_st_po"], 2000.);
        XCTAssertNil(labels[@"srg_enc"]);
        XCTAssertNil(labels[@"srg_timeshift"], @"The parameter srg_timeshift must only sent for live streams");
        
        [tester waitForTimeInterval:2.0f];
    }
}

// DVR streams should start at the end, i.e. live
- (void)testOpenDefaultMediaPlayerPlayDVRStreamAndSeekToNonLiveThenClose
{
    {
        [self expectationForNotification:@"RTSAnalyticsComScoreRequestDidFinish" object:nil handler:^BOOL(NSNotification *notification) {
            NSDictionary *labels = notification.userInfo[@"RTSAnalyticsLabels"];
            
            // Only consider relevant events
            if (!labels[@"clip_type"])
            {
                return NO;
            }
            
            XCTAssertEqualObjects(labels[@"ns_st_ev"], @"play");
            XCTAssertEqualObjects(labels[@"ns_st_li"], @"1");
            AssertIsWithin1Second(labels[@"srg_timeshift"], 0.);
            return YES;
        }];
        
        [tester tapRowAtIndexPath:[NSIndexPath indexPathForRow:5 inSection:1] inTableViewWithAccessibilityIdentifier:@"tableView"];
        
        [self waitForExpectationsWithTimeout:20. handler:nil];
    }

    // Seek to the past. Must store the position for seeking back to the live later (KIF requires a valid slider position to move to)
    static const CGFloat kPastPosition = 5.f;
    __block float position = 0.f;
    {
        __block NSInteger numberOfNotificationsReceived = 0;
        [self expectationForNotification:@"RTSAnalyticsComScoreRequestDidFinish" object:nil handler:^BOOL(NSNotification *notification) {
            NSDictionary *labels = notification.userInfo[@"RTSAnalyticsLabels"];
            
            // Skip heartbeats
            if ([labels[@"ns_st_ev"] isEqualToString:@"hb"])
            {
                return NO;
            }
            
            numberOfNotificationsReceived++;
            
            // Pause for the live
            if (numberOfNotificationsReceived == 1)
            {
                XCTAssertEqualObjects(labels[@"ns_st_ev"], @"pause");
                XCTAssertEqualObjects(labels[@"ns_st_li"], @"1");
                AssertIsWithin1Second(labels[@"srg_timeshift"], 0.);
                
                // Not finished yet
                return NO;
            }
            // Play for the past
            else if (numberOfNotificationsReceived == 2)
            {
                XCTAssertEqualObjects(labels[@"ns_st_ev"], @"play");
                XCTAssertEqualObjects(labels[@"ns_st_li"], @"1");
                
                // It is difficult to test this value since the DVR window varies with this test stream. Only check
                // that the value is large enough, the probability is small that the test fails because the available
                // DVR window is too small
                position = [labels[@"srg_timeshift"] floatValue] / 1000.f;
                XCTAssertTrue(position > 10.f);
                return YES;
            }
            else
            {
                return NO;
            }
        }];
        
        [tester setValue:kPastPosition forSliderWithAccessibilityLabel:@"slider"];
        
        [self waitForExpectationsWithTimeout:20. handler:nil];
    }
    
    // Seek back to the live
    {
        __block NSInteger numberOfNotificationsReceived = 0;
        [self expectationForNotification:@"RTSAnalyticsComScoreRequestDidFinish" object:nil handler:^BOOL(NSNotification *notification) {
            NSDictionary *labels = notification.userInfo[@"RTSAnalyticsLabels"];
            
            // Skip heartbeats
            if ([labels[@"ns_st_ev"] isEqualToString:@"hb"])
            {
                return NO;
            }
            
            numberOfNotificationsReceived++;
            
            // Pause for the past
            if (numberOfNotificationsReceived == 1)
            {
                XCTAssertEqualObjects(labels[@"ns_st_ev"], @"pause");
                XCTAssertEqualObjects(labels[@"ns_st_li"], @"1");
                
                // It is difficult to test this value since the DVR window varies with this test stream. Only check
                // that the value is large enough, the probability is small that the test fails because the available
                // DVR window is too small
                XCTAssertTrue([labels[@"srg_timeshift"] floatValue] > 10.f * 1000.f);
                
                // Not finished yet
                return NO;
            }
            // Play for the live
            else if (numberOfNotificationsReceived == 2)
            {
                XCTAssertEqualObjects(labels[@"ns_st_ev"], @"play");
                XCTAssertEqualObjects(labels[@"ns_st_li"], @"1");
                AssertIsWithin1Second(labels[@"srg_timeshift"], 0.);
                return YES;
            }
            else
            {
                return NO;
            }
        }];
        
        // Add a tolerance to avoid trying to set a value larger than the slider max, which leads to a KIF exception
        static const float kSliderTolerance = 4.f;
        [tester setValue:position - kPastPosition - kSliderTolerance  forSliderWithAccessibilityLabel:@"slider"];
        
        [self waitForExpectationsWithTimeout:20. handler:nil];
    }
    
    // Close
    {
        [tester tapViewWithAccessibilityLabel:@"Done"];
    }
    
    [tester waitForTimeInterval:2.0f];
}

// Expected behavior: When playing the full-length, we receive full-length labels. When a segment has been selected by the user, we
// receive segment labels. After the segment has been played through, we receive full-length labels again
//
// Heartbeat information must contain full-length labels when playing the full-length, and segment information while playing a
// segment selected by the user
- (void)testOpenMediaPlayerAndPlayOneSegmentCheckHeartbeats
{
    // Initial full-length play when opening
    {
        [self expectationForNotification:@"RTSAnalyticsComScoreRequestDidFinish" object:nil handler:^BOOL(NSNotification *notification) {
            NSDictionary *labels = notification.userInfo[@"RTSAnalyticsLabels"];
            
            // Only consider relevant events
            if (!labels[@"clip_type"])
            {
                return NO;
            }
            
            XCTAssertEqualObjects(labels[@"ns_st_ev"], @"play");
            AssertIsWithin1Second(labels[@"ns_st_po"], 0.);
            XCTAssertEqualObjects(labels[@"clip_type"], @"full_length");
            return YES;
        }];
        
        [tester tapRowAtIndexPath:[NSIndexPath indexPathForRow:6 inSection:1] inTableViewWithAccessibilityIdentifier:@"tableView"];
        
        [self waitForExpectationsWithTimeout:20. handler:nil];
    }
    
    // Play the segment. Expect full-length pause immediately followed by segment play
    {
        __block NSInteger numberOfNotificationsReceived = 0;
        [self expectationForNotification:@"RTSAnalyticsComScoreRequestDidFinish" object:nil handler:^BOOL(NSNotification *notification) {
            NSDictionary *labels = notification.userInfo[@"RTSAnalyticsLabels"];
            
            // Skip heartbeats, but check information
            if ([labels[@"ns_st_ev"] isEqualToString:@"hb"])
            {
                XCTAssertEqualObjects(labels[@"clip_type"], @"full_length");
                return NO;
            }
            
            numberOfNotificationsReceived++;
            
            // Pause for the full-length
            if (numberOfNotificationsReceived == 1)
            {
                XCTAssertEqualObjects(labels[@"ns_st_ev"], @"pause");
                XCTAssertEqualObjects(labels[@"clip_type"], @"full_length");
                AssertIsWithin1Second(labels[@"ns_st_po"], 0.);
                
                // Not finished yet
                return NO;
            }
            // Play for the segment
            else if (numberOfNotificationsReceived == 2)
            {
                XCTAssertEqualObjects(labels[@"ns_st_ev"], @"play");
                XCTAssertEqualObjects(labels[@"clip_type"], @"segment");
                AssertIsWithin1Second(labels[@"ns_st_po"], 2000.);
                return YES;
            }
            else
            {
                return NO;
            }
        }];
        
        // Tap on the button playing the first segment
        [tester tapViewWithAccessibilityLabel:@"Segment #1"];
        
        [self waitForExpectationsWithTimeout:20. handler:nil];
    }

    // Let the segment be played through, at which point resumes with the full-length
    {
        __block NSInteger numberOfNotificationsReceived = 0;
        [self expectationForNotification:@"RTSAnalyticsComScoreRequestDidFinish" object:nil handler:^BOOL(NSNotification *notification) {
            NSDictionary *labels = notification.userInfo[@"RTSAnalyticsLabels"];
            
            // Skip heartbeats
            if ([labels[@"ns_st_ev"] isEqualToString:@"hb"])
            {
                XCTAssertEqualObjects(labels[@"clip_type"], @"segment");
                return NO;
            }
            
            numberOfNotificationsReceived++;
            
            // Pause for the segment
            if (numberOfNotificationsReceived == 1)
            {
                XCTAssertEqualObjects(labels[@"ns_st_ev"], @"pause");
                XCTAssertEqualObjects(labels[@"clip_type"], @"segment");
                AssertIsWithin1Second(labels[@"ns_st_po"], 17000.);
                
                // Not finished yet
                return NO;
            }
            // Play for the full-length
            else if (numberOfNotificationsReceived == 2)
            {
                XCTAssertEqualObjects(labels[@"ns_st_ev"], @"play");
                XCTAssertEqualObjects(labels[@"clip_type"], @"full_length");
                AssertIsWithin1Second(labels[@"ns_st_po"], 17000.);
                return YES;
            }
            else
            {
                return NO;
            }
        }];
        [self waitForExpectationsWithTimeout:20. handler:nil];
    }
    
    // Wait for one more heartbeat, and check we get full-length information again
    {
        [self expectationForNotification:@"RTSAnalyticsComScoreRequestDidFinish" object:nil handler:^BOOL(NSNotification *notification) {
            NSDictionary *labels = notification.userInfo[@"RTSAnalyticsLabels"];
            
            if (! [labels[@"ns_st_ev"] isEqualToString:@"hb"])
            {
                return NO;
            }
            
            XCTAssertEqualObjects(labels[@"clip_type"], @"full_length");
            return YES;
        }];
        [self waitForExpectationsWithTimeout:60. handler:nil];
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
- (void)testOpenMediaPlayerAndPlayTwoConsecutiveSegments
{
    // Initial full-length play when opening
    {
        [self expectationForNotification:@"RTSAnalyticsComScoreRequestDidFinish" object:nil handler:^BOOL(NSNotification *notification) {
            NSDictionary *labels = notification.userInfo[@"RTSAnalyticsLabels"];
            
            // Only consider relevant events
            if (!labels[@"clip_type"])
            {
                return NO;
            }
            
            XCTAssertEqualObjects(labels[@"ns_st_ev"], @"play");
            AssertIsWithin1Second(labels[@"ns_st_po"], 0.);
            XCTAssertEqualObjects(labels[@"clip_type"], @"full_length");
            return YES;
        }];
        
        [tester tapRowAtIndexPath:[NSIndexPath indexPathForRow:7 inSection:1] inTableViewWithAccessibilityIdentifier:@"tableView"];
        
        [self waitForExpectationsWithTimeout:20. handler:nil];
    }
    
    // Go to 1st segment. Expect full-length pause immediately followed by segment play
    {
        __block NSInteger numberOfNotificationsReceived = 0;
        [self expectationForNotification:@"RTSAnalyticsComScoreRequestDidFinish" object:nil handler:^BOOL(NSNotification *notification) {
            NSDictionary *labels = notification.userInfo[@"RTSAnalyticsLabels"];
            
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
                AssertIsWithin1Second(labels[@"ns_st_po"], 0.);
                XCTAssertEqualObjects(labels[@"clip_type"], @"full_length");
                
                // Not finished yet
                return NO;
            }
            // Play for the first segment
            else if (numberOfNotificationsReceived == 2)
            {
                XCTAssertEqualObjects(labels[@"ns_st_ev"], @"play");
                AssertIsWithin1Second(labels[@"ns_st_po"], 2000.);
                XCTAssertEqualObjects(labels[@"clip_type"], @"segment1");
                return YES;
            }
            else
            {
                return NO;
            }
        }];
        
        [tester tapViewWithAccessibilityLabel:@"Segment #1"];
        
        [self waitForExpectationsWithTimeout:20. handler:nil];
    }
    
    // Playback continues after the first segment. Even if a second segment immediately follows it, we switch to the full-length
    // since the user does not select it explicitly
    {
        __block NSInteger numberOfNotificationsReceived = 0;
        [self expectationForNotification:@"RTSAnalyticsComScoreRequestDidFinish" object:nil handler:^BOOL(NSNotification *notification) {
            NSDictionary *labels = notification.userInfo[@"RTSAnalyticsLabels"];
            
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
                AssertIsWithin1Second(labels[@"ns_st_po"], 5000.);
                XCTAssertEqualObjects(labels[@"clip_type"], @"segment1");
                
                // Not finished yet
                return NO;
            }
            // Play for the full-length (even if there is a segment, it was not selected by the user)
            else if (numberOfNotificationsReceived == 2)
            {
                XCTAssertEqualObjects(labels[@"ns_st_ev"], @"play");
                AssertIsWithin1Second(labels[@"ns_st_po"], 5000.);
                XCTAssertEqualObjects(labels[@"clip_type"], @"full_length");
                return YES;
            }
            else
            {
                return NO;
            }
        }];
        [self waitForExpectationsWithTimeout:20. handler:nil];
    }
    
    // Close
    {
        [tester tapViewWithAccessibilityLabel:@"Done"];
    }
    
    [tester waitForTimeInterval:2.0f];
}

// Expected behavior: When playing the full-length, we receive full-length labels. When a segment has been selected by the user, we
// receive segment labels. When switching segments manually, we receveive labels for the new segment
- (void)testOpenMediaPlayerAndManuallySwitchBetweenSegments
{
    // Initial full-length play when opening
    {
        [self expectationForNotification:@"RTSAnalyticsComScoreRequestDidFinish" object:nil handler:^BOOL(NSNotification *notification) {
            NSDictionary *labels = notification.userInfo[@"RTSAnalyticsLabels"];
            
            // Only consider relevant events
            if (!labels[@"clip_type"])
            {
                return NO;
            }
            
            XCTAssertEqualObjects(labels[@"ns_st_ev"], @"play");
            AssertIsWithin1Second(labels[@"ns_st_po"], 0.);
            XCTAssertEqualObjects(labels[@"clip_type"], @"full_length");
            return YES;
        }];
        
        [tester tapRowAtIndexPath:[NSIndexPath indexPathForRow:7 inSection:1] inTableViewWithAccessibilityIdentifier:@"tableView"];
        
        [self waitForExpectationsWithTimeout:20. handler:nil];
    }
    
    // Go to 1st segment. Expect full-length pause immediately followed by segment play
    {
        __block NSInteger numberOfNotificationsReceived = 0;
        [self expectationForNotification:@"RTSAnalyticsComScoreRequestDidFinish" object:nil handler:^BOOL(NSNotification *notification) {
            NSDictionary *labels = notification.userInfo[@"RTSAnalyticsLabels"];
            
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
                AssertIsWithin1Second(labels[@"ns_st_po"], 0.);
                XCTAssertEqualObjects(labels[@"clip_type"], @"full_length");
                
                // Not finished yet
                return NO;
            }
            // Play for the first segment
            else if (numberOfNotificationsReceived == 2)
            {
                XCTAssertEqualObjects(labels[@"ns_st_ev"], @"play");
                AssertIsWithin1Second(labels[@"ns_st_po"], 2000.);
                XCTAssertEqualObjects(labels[@"clip_type"], @"segment1");
                return YES;
            }
            else
            {
                return NO;
            }
        }];
        
        [tester tapViewWithAccessibilityLabel:@"Segment #1"];
        
        [self waitForExpectationsWithTimeout:20. handler:nil];
    }
    
    // Manually switch to the second segment. Expect first segment pause immediately followed by second segment play
    {
        __block NSInteger numberOfNotificationsReceived = 0;
        [self expectationForNotification:@"RTSAnalyticsComScoreRequestDidFinish" object:nil handler:^BOOL(NSNotification *notification) {
            NSDictionary *labels = notification.userInfo[@"RTSAnalyticsLabels"];
            
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
                AssertIsWithin1Second(labels[@"ns_st_po"], 2000.);
                XCTAssertEqualObjects(labels[@"clip_type"], @"segment1");
                
                // Not finished yet
                return NO;
            }
            // Play for the second segment
            else if (numberOfNotificationsReceived == 2)
            {
                XCTAssertEqualObjects(labels[@"ns_st_ev"], @"play");
                AssertIsWithin1Second(labels[@"ns_st_po"], 5000.);
                XCTAssertEqualObjects(labels[@"clip_type"], @"segment2");
                return YES;
            }
            else
            {
                return NO;
            }
        }];
        
        [tester tapViewWithAccessibilityLabel:@"Segment #2"];
        
        [self waitForExpectationsWithTimeout:20. handler:nil];
    }
    
    // Close
    {
        [tester tapViewWithAccessibilityLabel:@"Done"];
    }
    
    [tester waitForTimeInterval:2.0f];
}

// Expected behavior: When playing a segment, selecting the same segment generates a pause for the segment, followed by a play
// for the same segment
- (void)testOpenMediaPlayerAndSwitchToTheSameSegment
{
    // Initial full-length play when opening
    {
        [self expectationForNotification:@"RTSAnalyticsComScoreRequestDidFinish" object:nil handler:^BOOL(NSNotification *notification) {
            NSDictionary *labels = notification.userInfo[@"RTSAnalyticsLabels"];
            
            // Only consider relevant events
            if (!labels[@"clip_type"])
            {
                return NO;
            }
            
            XCTAssertEqualObjects(labels[@"ns_st_ev"], @"play");
            AssertIsWithin1Second(labels[@"ns_st_po"], 0.);
            XCTAssertEqualObjects(labels[@"clip_type"], @"full_length");
            return YES;
        }];
        
        [tester tapRowAtIndexPath:[NSIndexPath indexPathForRow:7 inSection:1] inTableViewWithAccessibilityIdentifier:@"tableView"];
        
        [self waitForExpectationsWithTimeout:20. handler:nil];
    }
    
    // Go to 1st segment. Expect full-length pause immediately followed by segment play
    {
        __block NSInteger numberOfNotificationsReceived = 0;
        [self expectationForNotification:@"RTSAnalyticsComScoreRequestDidFinish" object:nil handler:^BOOL(NSNotification *notification) {
            NSDictionary *labels = notification.userInfo[@"RTSAnalyticsLabels"];
            
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
                AssertIsWithin1Second(labels[@"ns_st_po"], 0.);
                XCTAssertEqualObjects(labels[@"clip_type"], @"full_length");
                
                // Not finished yet
                return NO;
            }
            // Play for the first segment
            else if (numberOfNotificationsReceived == 2)
            {
                XCTAssertEqualObjects(labels[@"ns_st_ev"], @"play");
                AssertIsWithin1Second(labels[@"ns_st_po"], 2000.);
                XCTAssertEqualObjects(labels[@"clip_type"], @"segment1");
                return YES;
            }
            else
            {
                return NO;
            }
        }];
        
        [tester tapViewWithAccessibilityLabel:@"Segment #1"];
        
        [self waitForExpectationsWithTimeout:20. handler:nil];
    }
    
    // Manually switch to the same segment. Expect segment pause and play for the same segment
    {
        __block NSInteger numberOfNotificationsReceived = 0;
        [self expectationForNotification:@"RTSAnalyticsComScoreRequestDidFinish" object:nil handler:^BOOL(NSNotification *notification) {
            NSDictionary *labels = notification.userInfo[@"RTSAnalyticsLabels"];
            
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
                AssertIsWithin1Second(labels[@"ns_st_po"], 2000.);
                XCTAssertEqualObjects(labels[@"clip_type"], @"segment1");
                
                // Not finished yet
                return NO;
            }
            // Play for the full-length (even if there is a segment, it was not selected by the user)
            else if (numberOfNotificationsReceived == 2)
            {
                XCTAssertEqualObjects(labels[@"ns_st_ev"], @"play");
                AssertIsWithin1Second(labels[@"ns_st_po"], 2000.);
                XCTAssertEqualObjects(labels[@"clip_type"], @"segment1");
                return YES;
            }
            else
            {
                return NO;
            }
        }];
        
        [tester tapViewWithAccessibilityLabel:@"Segment #1"];
        
        [self waitForExpectationsWithTimeout:20. handler:nil];
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
        [self expectationForNotification:@"RTSAnalyticsComScoreRequestDidFinish" object:nil handler:^BOOL(NSNotification *notification) {
            NSDictionary *labels = notification.userInfo[@"RTSAnalyticsLabels"];
            
            // Only consider relevant events
            if (!labels[@"clip_type"])
            {
                return NO;
            }
            
            XCTAssertEqualObjects(labels[@"ns_st_ev"], @"play");
            AssertIsWithin1Second(labels[@"ns_st_po"], 0.);
            XCTAssertEqualObjects(labels[@"clip_type"], @"full_length");
            return YES;
        }];
        
        [tester tapRowAtIndexPath:[NSIndexPath indexPathForRow:6 inSection:1] inTableViewWithAccessibilityIdentifier:@"tableView"];
        
        [self waitForExpectationsWithTimeout:20. handler:nil];
    }
    
    // Go to the segment. Expect full-length pause immediately followed by segment play
    {
        __block NSInteger numberOfNotificationsReceived = 0;
        [self expectationForNotification:@"RTSAnalyticsComScoreRequestDidFinish" object:nil handler:^BOOL(NSNotification *notification) {
            NSDictionary *labels = notification.userInfo[@"RTSAnalyticsLabels"];
            
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
            else
            {
                return NO;
            }
        }];
        
        [tester tapViewWithAccessibilityLabel:@"Segment #1"];
        
        [self waitForExpectationsWithTimeout:20. handler:nil];
    }
    
    // Seek outside the segment. Expect segment pause followed by full-length play
    {
        __block NSInteger numberOfNotificationsReceived = 0;
        [self expectationForNotification:@"RTSAnalyticsComScoreRequestDidFinish" object:nil handler:^BOOL(NSNotification *notification) {
            NSDictionary *labels = notification.userInfo[@"RTSAnalyticsLabels"];
            
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
            else
            {
                return NO;
            }
        }];
        
        [tester setValue:time forSliderWithAccessibilityLabel:@"slider"];
                
        [self waitForExpectationsWithTimeout:20. handler:nil];
    }
    
    // Close
    {
        [tester tapViewWithAccessibilityLabel:@"Done"];
    }
    
    [tester waitForTimeInterval:2.0f];
}

- (void)testOpenMediaPlayerAndPlaySegmentBeforeSeekingOutsideIt
{
    [self openMediaPlayerAndPlaySegmentBeforeSeekingAtTime:40.];
}

- (void)testOpenMediaPlayerAndPlaySegmentBeforeSeekingInsideIt
{
    [self openMediaPlayerAndPlaySegmentBeforeSeekingAtTime:3.];
}

// Expected behavior: When closing the player while a segment is being played, no end event is expected for the segment, only for the
// full-length
- (void)testOpenMediaPlayerAndPlaySegmentWhileClosingThePlayer
{
    // Initial full-length play when opening
    {
        [self expectationForNotification:@"RTSAnalyticsComScoreRequestDidFinish" object:nil handler:^BOOL(NSNotification *notification) {
            NSDictionary *labels = notification.userInfo[@"RTSAnalyticsLabels"];
            
            // Only consider relevant events
            if (!labels[@"clip_type"])
            {
                return NO;
            }
            
            XCTAssertEqualObjects(labels[@"ns_st_ev"], @"play");
            XCTAssertEqualObjects(labels[@"clip_type"], @"full_length");
            return YES;
        }];
        
        [tester tapRowAtIndexPath:[NSIndexPath indexPathForRow:6 inSection:1] inTableViewWithAccessibilityIdentifier:@"tableView"];
        
        [self waitForExpectationsWithTimeout:20. handler:nil];
    }
    
    // Go to the segment. Expect full-length pause immediately followed by segment play
    {
        __block NSInteger numberOfNotificationsReceived = 0;
        [self expectationForNotification:@"RTSAnalyticsComScoreRequestDidFinish" object:nil handler:^BOOL(NSNotification *notification) {
            NSDictionary *labels = notification.userInfo[@"RTSAnalyticsLabels"];
            
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
            else
            {
                return NO;
            }
        }];
        
        [tester tapViewWithAccessibilityLabel:@"Segment #1"];
        
        [self waitForExpectationsWithTimeout:20. handler:nil];
    }
    
    // Close the player. Only an end event is expected for the full-length
    {
        [self expectationForNotification:@"RTSAnalyticsComScoreRequestDidFinish" object:nil handler:^BOOL(NSNotification *notification) {
            NSDictionary *labels = notification.userInfo[@"RTSAnalyticsLabels"];
            
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
        
        [self waitForExpectationsWithTimeout:20. handler:nil];
    }
    
    [tester waitForTimeInterval:2.0f];
}

// Try to seek into a blocked segment. Must pause the full-length
- (void)testOpenMediaPlayerAndSeekIntoBlockedSegment
{
    // Initial full-length play when opening
    {
        [self expectationForNotification:@"RTSAnalyticsComScoreRequestDidFinish" object:nil handler:^BOOL(NSNotification *notification) {
            NSDictionary *labels = notification.userInfo[@"RTSAnalyticsLabels"];
            
            // Only consider relevant events
            if (!labels[@"clip_type"])
            {
                return NO;
            }
            
            XCTAssertEqualObjects(labels[@"ns_st_ev"], @"play");
            AssertIsWithin1Second(labels[@"ns_st_po"], 0.);
            XCTAssertEqualObjects(labels[@"clip_type"], @"full_length");
            return YES;
        }];
        
        [tester tapRowAtIndexPath:[NSIndexPath indexPathForRow:7 inSection:1] inTableViewWithAccessibilityIdentifier:@"tableView"];
        
        [self waitForExpectationsWithTimeout:20. handler:nil];
    }
    
    // Seek into the blocked segment
    {
        [self expectationForNotification:@"RTSAnalyticsComScoreRequestDidFinish" object:nil handler:^BOOL(NSNotification *notification) {
            NSDictionary *labels = notification.userInfo[@"RTSAnalyticsLabels"];
            
            // Skip heartbeats
            if ([labels[@"ns_st_ev"] isEqualToString:@"hb"])
            {
                return NO;
            }
            
            XCTAssertEqualObjects(labels[@"ns_st_ev"], @"pause");
            AssertIsWithin1Second(labels[@"ns_st_po"], 0.);
            XCTAssertEqualObjects(labels[@"clip_type"], @"full_length");
            return YES;
        }];
        
        [tester setValue:43. forSliderWithAccessibilityLabel:@"slider"];
        
        [self waitForExpectationsWithTimeout:20. handler:nil];
    }
    
    // Close
    {
        [tester tapViewWithAccessibilityLabel:@"Done"];
    }
    
    [tester waitForTimeInterval:2.0f];
}

// Pause while the full-length is being played
- (void)testOpenMediaPlayerPlayThenPauseFullLength
{
    // Initial full-length play when opening
    {
        [self expectationForNotification:@"RTSAnalyticsComScoreRequestDidFinish" object:nil handler:^BOOL(NSNotification *notification) {
            NSDictionary *labels = notification.userInfo[@"RTSAnalyticsLabels"];
            
            // Only consider relevant events
            if (!labels[@"clip_type"])
            {
                return NO;
            }
            
            XCTAssertEqualObjects(labels[@"ns_st_ev"], @"play");
            AssertIsWithin1Second(labels[@"ns_st_po"], 0.);
            XCTAssertEqualObjects(labels[@"clip_type"], @"full_length");
            return YES;
        }];
        
        [tester tapRowAtIndexPath:[NSIndexPath indexPathForRow:6 inSection:1] inTableViewWithAccessibilityIdentifier:@"tableView"];
        
        [self waitForExpectationsWithTimeout:20. handler:nil];
    }
    
    // Pause
    {
        [self expectationForNotification:@"RTSAnalyticsComScoreRequestDidFinish" object:nil handler:^BOOL(NSNotification *notification) {
            NSDictionary *labels = notification.userInfo[@"RTSAnalyticsLabels"];
            
            // Skip heartbeats
            if ([labels[@"ns_st_ev"] isEqualToString:@"hb"])
            {
                return NO;
            }
            
            XCTAssertEqualObjects(labels[@"ns_st_ev"], @"pause");
            AssertIsWithin1Second(labels[@"ns_st_po"], 0.);
            XCTAssertEqualObjects(labels[@"clip_type"], @"full_length");
            return YES;
        }];

        [tester tapViewWithAccessibilityLabel:@"play"];
        
        [self waitForExpectationsWithTimeout:20. handler:nil];
    }
    
    // Close
    {
        [tester tapViewWithAccessibilityLabel:@"Done"];
    }
    
    [tester waitForTimeInterval:2.0f];
}

// Pause while a segment is being played
- (void)testOpenMediaPlayerPlayThenPauseSegment
{
    // Initial full-length play when opening
    {
        [self expectationForNotification:@"RTSAnalyticsComScoreRequestDidFinish" object:nil handler:^BOOL(NSNotification *notification) {
            NSDictionary *labels = notification.userInfo[@"RTSAnalyticsLabels"];
            
            // Only consider relevant events
            if (!labels[@"clip_type"])
            {
                return NO;
            }
            
            XCTAssertEqualObjects(labels[@"ns_st_ev"], @"play");
            AssertIsWithin1Second(labels[@"ns_st_po"], 0.);
            XCTAssertEqualObjects(labels[@"clip_type"], @"full_length");
            return YES;
        }];
        
        [tester tapRowAtIndexPath:[NSIndexPath indexPathForRow:6 inSection:1] inTableViewWithAccessibilityIdentifier:@"tableView"];
        
        [self waitForExpectationsWithTimeout:20. handler:nil];
    }
    
    // Go to the segment. Expect full-length pause immediately followed by segment play
    {
        __block NSInteger numberOfNotificationsReceived = 0;
        [self expectationForNotification:@"RTSAnalyticsComScoreRequestDidFinish" object:nil handler:^BOOL(NSNotification *notification) {
            NSDictionary *labels = notification.userInfo[@"RTSAnalyticsLabels"];
            
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
                AssertIsWithin1Second(labels[@"ns_st_po"], 0.);
                XCTAssertEqualObjects(labels[@"clip_type"], @"full_length");
                
                // Not finished yet
                return NO;
            }
            // Play for the first segment
            else if (numberOfNotificationsReceived == 2)
            {
                XCTAssertEqualObjects(labels[@"ns_st_ev"], @"play");
                AssertIsWithin1Second(labels[@"ns_st_po"], 2000.);
                XCTAssertEqualObjects(labels[@"clip_type"], @"segment");
                return YES;
            }
            else
            {
                return NO;
            }
        }];
        
        [tester tapViewWithAccessibilityLabel:@"Segment #1"];
        
        [self waitForExpectationsWithTimeout:20. handler:nil];
    }
    
    // Pause
    {
        [self expectationForNotification:@"RTSAnalyticsComScoreRequestDidFinish" object:nil handler:^BOOL(NSNotification *notification) {
            NSDictionary *labels = notification.userInfo[@"RTSAnalyticsLabels"];
            
            // Skip heartbeats
            if ([labels[@"ns_st_ev"] isEqualToString:@"hb"])
            {
                return NO;
            }
            
            XCTAssertEqualObjects(labels[@"ns_st_ev"], @"pause");
            XCTAssertEqualObjects(labels[@"clip_type"], @"segment");
            return YES;
        }];
        
        [tester tapViewWithAccessibilityLabel:@"play"];
        
        [self waitForExpectationsWithTimeout:20. handler:nil];
    }
    
    // Close
    {
        [tester tapViewWithAccessibilityLabel:@"Done"];
    }
    
    [tester waitForTimeInterval:2.0f];
}

@end
