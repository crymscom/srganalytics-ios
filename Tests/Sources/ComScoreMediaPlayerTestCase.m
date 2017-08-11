//
//  Copyright (c) SRG SSR. All rights reserved.
//
//  License information is available from the LICENSE file.
//

#import "AnalyticsTestCase.h"
#import "NSNotificationCenter+Tests.h"
#import "Segment.h"

#import <SRGAnalytics_MediaPlayer/SRGAnalytics_MediaPlayer.h>

typedef BOOL (^EventExpectationHandler)(NSString *event, NSDictionary *labels);

static NSURL *OnDemandTestURL(void)
{
    return [NSURL URLWithString:@"https://devimages.apple.com.edgekey.net/streaming/examples/bipbop_16x9/bipbop_16x9_variant.m3u8"];
}

static NSURL *LiveTestURL(void)
{
    return [NSURL URLWithString:@"http://ndr_fs-lh.akamaihd.net/i/ndrfs_nds@119224/master.m3u8?dw=0"];
}

static NSURL *DVRTestURL(void)
{
    return [NSURL URLWithString:@"http://tagesschau-lh.akamaihd.net/i/tagesschau_1@119231/master.m3u8"];
}

@interface ComScoreMediaPlayerTestCase : AnalyticsTestCase

@property (nonatomic) SRGMediaPlayerController *mediaPlayerController;

@end

@implementation ComScoreMediaPlayerTestCase

#pragma mark Setup and teardown

- (void)setUp
{
    self.mediaPlayerController = [[SRGMediaPlayerController alloc] init];
    self.mediaPlayerController.liveTolerance = 10.;
}

- (void)tearDown
{
    [self.mediaPlayerController reset];
    self.mediaPlayerController = nil;
}

#pragma mark Tests

- (void)testPrepareToPlay
{
    // Prepare the player until it is paused. No event must be received
    id prepareObserver = [[NSNotificationCenter defaultCenter] addObserverForComScoreHiddenEventNotificationUsingBlock:^(NSString * _Nonnull event, NSDictionary * _Nonnull labels) {
        XCTFail(@"No event must be received when preparing a player");
    }];
    
    [self.mediaPlayerController prepareToPlayURL:OnDemandTestURL() withCompletionHandler:^{
        [[NSNotificationCenter defaultCenter] removeObserver:prepareObserver];
    }];
    
    // Now playing must trigger a play event
    [self expectationForComScoreHiddenEventNotificationWithHandler:^BOOL(NSString *event, NSDictionary *labels) {
        XCTAssertEqualObjects(labels[@"ns_st_ev"], @"play");
        return YES;
    }];
    
    [self.mediaPlayerController play];
    
    [self waitForExpectationsWithTimeout:20. handler:nil];
    
    [self expectationForComScoreHiddenEventNotificationWithHandler:^BOOL(NSString *event, NSDictionary *labels) {
        XCTAssertEqualObjects(labels[@"ns_st_ev"], @"end");
        return YES;
    }];
    
    [self.mediaPlayerController reset];
    
    [self waitForExpectationsWithTimeout:20. handler:nil];
}

- (void)testPlaybackToEnd
{
    // Also check internal comScore important measurement values for playback duration (ns_st_pa and ns_st_pt). Ensure
    // we did not mess with them by mistake
    
    [self expectationForComScoreHiddenEventNotificationWithHandler:^BOOL(NSString *event, NSDictionary *labels) {
        XCTAssertEqualObjects(labels[@"ns_st_ev"], @"play");
        
        // comScore internal duration labels
        XCTAssertNil(labels[@"ns_st_pa"]);
        XCTAssertNil(labels[@"ns_st_pt"]);
        return YES;
    }];
    
    [self.mediaPlayerController playURL:OnDemandTestURL()];
    
    [self waitForExpectationsWithTimeout:20. handler:nil];
    
    [self expectationForComScoreHiddenEventNotificationWithHandler:^BOOL(NSString *event, NSDictionary *labels) {
        XCTAssertEqualObjects(labels[@"ns_st_ev"], @"pause");
        
        // comScore internal duration labels
        XCTAssertNotNil(labels[@"ns_st_pa"]);
        XCTAssertNotEqualObjects(labels[@"ns_st_pa"], @"0");
        XCTAssertNotEqualObjects(labels[@"ns_st_pt"], @"0");
        return YES;
    }];
    
    // Seek near the end of the video
    CMTime pastTime = CMTimeSubtract(CMTimeRangeGetEnd(self.mediaPlayerController.timeRange), CMTimeMakeWithSeconds(5., NSEC_PER_SEC));
    [self.mediaPlayerController seekPreciselyToTime:pastTime withCompletionHandler:nil];
    
    [self waitForExpectationsWithTimeout:20. handler:nil];
    
    [self expectationForComScoreHiddenEventNotificationWithHandler:^BOOL(NSString *event, NSDictionary *labels) {
        XCTAssertEqualObjects(labels[@"ns_st_ev"], @"play");
        
        // comScore internal duration labels
        XCTAssertNil(labels[@"ns_st_pa"]);
        XCTAssertNil(labels[@"ns_st_pt"]);
        return YES;
    }];
    
    [self waitForExpectationsWithTimeout:20. handler:nil];
    
    // Let playback finish normally
    
    [self expectationForComScoreHiddenEventNotificationWithHandler:^BOOL(NSString *event, NSDictionary *labels) {
        XCTAssertEqualObjects(labels[@"ns_st_ev"], @"end");
        
        // comScore internal duration labels
        XCTAssertNotNil(labels[@"ns_st_pa"]);
        XCTAssertNotEqualObjects(labels[@"ns_st_pa"], @"0");
        XCTAssertNotEqualObjects(labels[@"ns_st_pt"], @"0");
        return YES;
    }];
    
    [self waitForExpectationsWithTimeout:20. handler:nil];
}

- (void)testPlayStop
{
    [self expectationForComScoreHiddenEventNotificationWithHandler:^BOOL(NSString *event, NSDictionary *labels) {
        XCTAssertEqualObjects(labels[@"ns_st_ev"], @"play");
        return YES;
    }];
    
    [self.mediaPlayerController playURL:OnDemandTestURL()];
    
    [self waitForExpectationsWithTimeout:20. handler:nil];
    
    [self expectationForComScoreHiddenEventNotificationWithHandler:^BOOL(NSString *event, NSDictionary *labels) {
        XCTAssertEqualObjects(labels[@"ns_st_ev"], @"end");
        return YES;
    }];
    
    [self.mediaPlayerController stop];
    
    [self waitForExpectationsWithTimeout:20. handler:nil];
}

- (void)testPlayReset
{
    [self expectationForComScoreHiddenEventNotificationWithHandler:^BOOL(NSString *event, NSDictionary *labels) {
        XCTAssertEqualObjects(labels[@"ns_st_ev"], @"play");
        return YES;
    }];
    
    [self.mediaPlayerController playURL:OnDemandTestURL()];
    
    [self waitForExpectationsWithTimeout:20. handler:nil];
    
    [self expectationForComScoreHiddenEventNotificationWithHandler:^BOOL(NSString *event, NSDictionary *labels) {
        XCTAssertEqualObjects(labels[@"ns_st_ev"], @"end");
        return YES;
    }];
    
    [self.mediaPlayerController reset];
    
    [self waitForExpectationsWithTimeout:20. handler:nil];
}

- (void)testPlayPausePlay
{
    __block NSInteger count1 = 0;
    id eventObserver1 = [[NSNotificationCenter defaultCenter] addObserverForComScoreHiddenEventNotificationUsingBlock:^(NSString * _Nonnull event, NSDictionary * _Nonnull labels) {
        ++count1;
    }];
    
    [self expectationForComScoreHiddenEventNotificationWithHandler:^BOOL(NSString *event, NSDictionary *labels) {
        return [event isEqualToString:@"play"];
    }];
    
    [self.mediaPlayerController playURL:OnDemandTestURL()];
    
    [self waitForExpectationsWithTimeout:30. handler:^(NSError * _Nullable error) {
        [[NSNotificationCenter defaultCenter] removeObserver:eventObserver1];
    }];
    
    // One event expected: play
    XCTAssertEqual(count1, 1);
    
    __block NSInteger count2 = 0;
    id eventObserver2 = [[NSNotificationCenter defaultCenter] addObserverForComScoreHiddenEventNotificationUsingBlock:^(NSString * _Nonnull event, NSDictionary * _Nonnull labels) {
        ++count2;
    }];
    
    [self expectationForComScoreHiddenEventNotificationWithHandler:^BOOL(NSString *event, NSDictionary *labels) {
        return [event isEqualToString:@"pause"];
    }];
    
    [self.mediaPlayerController pause];
    
    [self waitForExpectationsWithTimeout:30. handler:^(NSError * _Nullable error) {
        [[NSNotificationCenter defaultCenter] removeObserver:eventObserver2];
    }];
    
    // One event expected: pause
    XCTAssertEqual(count2, 1);
    
    __block NSInteger count3 = 0;
    id eventObserver3 = [[NSNotificationCenter defaultCenter] addObserverForComScoreHiddenEventNotificationUsingBlock:^(NSString * _Nonnull event, NSDictionary * _Nonnull labels) {
        ++count3;
    }];
    
    [self expectationForComScoreHiddenEventNotificationWithHandler:^BOOL(NSString *event, NSDictionary *labels) {
        return [event isEqualToString:@"play"];
    }];
    
    [self.mediaPlayerController play];
    
    [self waitForExpectationsWithTimeout:30. handler:^(NSError * _Nullable error) {
        [[NSNotificationCenter defaultCenter] removeObserver:eventObserver3];
    }];
    
    [self expectationForElapsedTimeInterval:3. withHandler:nil];
    
    id eventObserver4 = [[NSNotificationCenter defaultCenter] addObserverForComScoreHiddenEventNotificationUsingBlock:^(NSString * _Nonnull event, NSDictionary * _Nonnull labels) {
        // Also see http://stackoverflow.com/questions/14565405/avplayer-pauses-for-no-obvious-reason and
        // the demo project https://github.com/defagos/radars/tree/master/unexpected-player-rate-changes
        NSLog(@"[AVPlayer probable bug]: Unexpected state change to %@. Fast play - pause sequences can induce unexpected rate changes "
              "captured via KVO in our implementation. Those changes do not harm but cannot be tested reliably", @(self.mediaPlayerController.playbackState));
    }];
    
    [self waitForExpectationsWithTimeout:30. handler:^(NSError * _Nullable error) {
        [[NSNotificationCenter defaultCenter] removeObserver:eventObserver4];
    }];
}

- (void)testConsecutiveMedia
{
    [self expectationForComScoreHiddenEventNotificationWithHandler:^BOOL(NSString *event, NSDictionary *labels) {
        XCTAssertEqualObjects(labels[@"ns_st_ev"], @"play");
        return YES;
    }];
    
    [self.mediaPlayerController playURL:OnDemandTestURL()];
    
    [self waitForExpectationsWithTimeout:20. handler:nil];
    
    [self expectationForComScoreHiddenEventNotificationWithHandler:^BOOL(NSString *event, NSDictionary *labels) {
        XCTAssertEqualObjects(labels[@"ns_st_ev"], @"end");
        return YES;
    }];
    
    [self.mediaPlayerController playURL:LiveTestURL()];
    
    [self waitForExpectationsWithTimeout:20. handler:nil];
    
    [self expectationForComScoreHiddenEventNotificationWithHandler:^BOOL(NSString *event, NSDictionary *labels) {
        XCTAssertEqualObjects(labels[@"ns_st_ev"], @"play");
        return YES;
    }];
    
    [self waitForExpectationsWithTimeout:20. handler:nil];
    
    [self expectationForComScoreHiddenEventNotificationWithHandler:^BOOL(NSString *event, NSDictionary *labels) {
        XCTAssertEqualObjects(labels[@"ns_st_ev"], @"end");
        return YES;
    }];
    
    [self.mediaPlayerController reset];
    
    [self waitForExpectationsWithTimeout:20. handler:nil];
}

- (void)testMediaError
{
    id eventObserver = [[NSNotificationCenter defaultCenter] addObserverForComScoreHiddenEventNotificationUsingBlock:^(NSString * _Nonnull event, NSDictionary * _Nonnull labels) {
        XCTFail(@"No event must be received");
    }];
    
    [self expectationForNotification:SRGMediaPlayerPlaybackDidFailNotification object:self.mediaPlayerController handler:^BOOL (NSNotification *notification) {
        return YES;
    }];
    
    [self.mediaPlayerController playURL:[NSURL URLWithString:@"http://httpbin.org/status/403"]];
    
    [self waitForExpectationsWithTimeout:20. handler:^(NSError * _Nullable error) {
        [[NSNotificationCenter defaultCenter] removeObserver:eventObserver];
    }];
}

- (void)testCommonLabels
{
    [self expectationForComScoreHiddenEventNotificationWithHandler:^BOOL(NSString *event, NSDictionary *labels) {
        XCTAssertEqualObjects(labels[@"ns_st_ev"], @"play");
        
        XCTAssertEqualObjects(labels[@"ns_st_mp"], @"SRGMediaPlayer");
        XCTAssertEqualObjects(labels[@"ns_st_mv"], SRGMediaPlayerMarketingVersion());
        XCTAssertEqualObjects(labels[@"ns_st_it"], @"c");
        XCTAssertEqualObjects(labels[@"srg_ptype"], @"p_app_ios");
        return YES;
    }];
    
    [self.mediaPlayerController playURL:OnDemandTestURL()];
    
    [self waitForExpectationsWithTimeout:20. handler:nil];
}

- (void)testOnDemandLabels
{
    // Check that these labels are constant between states (for some, the value might differ, but they must
    // in which case we test they are constantly availble or unavailable)
    void (^checkMainLabels)(NSDictionary *) = ^(NSDictionary *labels) {
        XCTAssertNotNil(labels[@"ns_st_br"]);
        XCTAssertEqualObjects(labels[@"ns_st_ws"], @"norm");
        XCTAssertNotNil(labels[@"ns_st_vo"]);
        XCTAssertNil(labels[@"ns_ap_ot"]);
        
        XCTAssertEqualObjects(labels[@"ns_st_cs"], @"0x0");
        XCTAssertEqualObjects(labels[@"srg_screen_type"], @"default");
    };
    
    [self expectationForComScoreHiddenEventNotificationWithHandler:^BOOL(NSString *event, NSDictionary *labels) {
        XCTAssertEqualObjects(labels[@"ns_st_ev"], @"play");
        XCTAssertNil(labels[@"srg_timeshift"]);
        checkMainLabels(labels);
        return YES;
    }];
    
    [self.mediaPlayerController playURL:OnDemandTestURL()];
    
    [self waitForExpectationsWithTimeout:20. handler:nil];
    
    [self expectationForComScoreHiddenEventNotificationWithHandler:^BOOL(NSString *event, NSDictionary *labels) {
        XCTAssertEqualObjects(labels[@"ns_st_ev"], @"pause");
        XCTAssertNil(labels[@"srg_timeshift"]);
        checkMainLabels(labels);
        return YES;
    }];
    
    [self.mediaPlayerController pause];
    
    [self waitForExpectationsWithTimeout:20. handler:nil];
    
    [self expectationForComScoreHiddenEventNotificationWithHandler:^BOOL(NSString *event, NSDictionary *labels) {
        XCTAssertEqualObjects(labels[@"ns_st_ev"], @"end");
        XCTAssertNil(labels[@"srg_timeshift"]);
        checkMainLabels(labels);
        return YES;
    }];
    
    [self.mediaPlayerController reset];
    
    [self waitForExpectationsWithTimeout:20. handler:nil];
}

- (void)testLiveLabels
{
    // Check that these labels are constant between states (for some, the value might differ, but they must
    // in which case we test they are constantly availble or unavailable)
    void (^checkMainLabels)(NSDictionary *) = ^(NSDictionary *labels) {
        XCTAssertNotNil(labels[@"ns_st_br"]);
        XCTAssertEqualObjects(labels[@"ns_st_ws"], @"norm");
        XCTAssertNotNil(labels[@"ns_st_vo"]);
        XCTAssertNil(labels[@"ns_ap_ot"]);
        
        XCTAssertEqualObjects(labels[@"ns_st_cs"], @"0x0");
        XCTAssertEqualObjects(labels[@"srg_screen_type"], @"default");
    };
    
    [self expectationForComScoreHiddenEventNotificationWithHandler:^BOOL(NSString *event, NSDictionary *labels) {
        XCTAssertEqualObjects(labels[@"ns_st_ev"], @"play");
        XCTAssertEqualObjects(labels[@"srg_timeshift"], @"0");
        checkMainLabels(labels);
        return YES;
    }];
    
    SRGAnalyticsPlayerLabels *labels = [[SRGAnalyticsPlayerLabels alloc] init];
    labels.comScoreCustomInfo = @{ @"test_info" : @"test" };
    
    [self.mediaPlayerController playURL:LiveTestURL()
                                 atTime:kCMTimeZero
                           withSegments:nil
                        analyticsLabels:labels
                               userInfo:nil];
    
    [self waitForExpectationsWithTimeout:20. handler:nil];
    
    [self expectationForComScoreHiddenEventNotificationWithHandler:^BOOL(NSString *event, NSDictionary *labels) {
        XCTAssertEqualObjects(labels[@"ns_st_ev"], @"pause");
        XCTAssertEqualObjects(labels[@"srg_timeshift"], @"0");
        checkMainLabels(labels);
        return YES;
    }];
    
    [self.mediaPlayerController pause];
    
    [self waitForExpectationsWithTimeout:20. handler:nil];
    
    [self expectationForComScoreHiddenEventNotificationWithHandler:^BOOL(NSString *event, NSDictionary *labels) {
        XCTAssertEqualObjects(labels[@"ns_st_ev"], @"end");
        XCTAssertNil(labels[@"srg_timeshift"]);
        checkMainLabels(labels);
        return YES;
    }];
    
    [self.mediaPlayerController reset];
    
    [self waitForExpectationsWithTimeout:20. handler:nil];
}

- (void)testDVRLabels
{
    // Check that these labels are constant between states (for some, the value might differ, but they must
    // in which case we test they are constantly availble or unavailable)
    void (^checkMainLabels)(NSDictionary *) = ^(NSDictionary *labels) {
        XCTAssertNotNil(labels[@"ns_st_br"]);
        XCTAssertEqualObjects(labels[@"ns_st_ws"], @"norm");
        XCTAssertNotNil(labels[@"ns_st_vo"]);
        XCTAssertNil(labels[@"ns_ap_ot"]);
        
        XCTAssertEqualObjects(labels[@"ns_st_cs"], @"0x0");
        XCTAssertEqualObjects(labels[@"srg_screen_type"], @"default");
    };
    
    [self expectationForComScoreHiddenEventNotificationWithHandler:^BOOL(NSString *event, NSDictionary *labels) {
        XCTAssertEqualObjects(labels[@"ns_st_ev"], @"play");
        XCTAssertEqualObjects(labels[@"srg_timeshift"], @"0");
        checkMainLabels(labels);
        return YES;
    }];
    
    [self.mediaPlayerController playURL:DVRTestURL()];
    
    [self waitForExpectationsWithTimeout:20. handler:nil];
    
    [self expectationForComScoreHiddenEventNotificationWithHandler:^BOOL(NSString *event, NSDictionary *labels) {
        XCTAssertEqualObjects(labels[@"ns_st_ev"], @"pause");
        XCTAssertEqualObjects(labels[@"srg_timeshift"], @"0");
        checkMainLabels(labels);
        return YES;
    }];
    
    // Live tolerance has been set to 10 for tests, duration of the DVR window for the test stream is about 45 seconds
    CMTime pastTime = CMTimeSubtract(CMTimeRangeGetEnd(self.mediaPlayerController.timeRange), CMTimeMakeWithSeconds(20., NSEC_PER_SEC));
    [self.mediaPlayerController seekPreciselyToTime:pastTime withCompletionHandler:nil];
    
    [self waitForExpectationsWithTimeout:20. handler:nil];
    
    [self expectationForComScoreHiddenEventNotificationWithHandler:^BOOL(NSString *event, NSDictionary *labels) {
        XCTAssertEqualObjects(labels[@"ns_st_ev"], @"play");
        XCTAssertNotNil(labels[@"srg_timeshift"]);
        XCTAssertNotEqualObjects(labels[@"srg_timeshift"], @"0");
        checkMainLabels(labels);
        return YES;
    }];
    [self waitForExpectationsWithTimeout:20. handler:nil];
    
    [self expectationForComScoreHiddenEventNotificationWithHandler:^BOOL(NSString *event, NSDictionary *labels) {
        XCTAssertEqualObjects(labels[@"ns_st_ev"], @"end");
        XCTAssertNil(labels[@"srg_timeshift"]);
        checkMainLabels(labels);
        return YES;
    }];
    
    [self.mediaPlayerController reset];
    
    [self waitForExpectationsWithTimeout:20. handler:nil];
}

- (void)testVolumeLabel
{
    [self expectationForComScoreHiddenEventNotificationWithHandler:^BOOL(NSString *event, NSDictionary *labels) {
        XCTAssertEqualObjects(labels[@"ns_st_ev"], @"play");
        XCTAssertEqualObjects(labels[@"ns_st_vo"], @"0");
        return YES;
    }];
    
    self.mediaPlayerController.playerCreationBlock = ^(AVPlayer *player) {
        player.muted = YES;
    };
    [self.mediaPlayerController playURL:OnDemandTestURL()];
    
    [self waitForExpectationsWithTimeout:20. handler:nil];
    
    [self expectationForComScoreHiddenEventNotificationWithHandler:^BOOL(NSString *event, NSDictionary *labels) {
        XCTAssertEqualObjects(labels[@"ns_st_ev"], @"pause");
        XCTAssertNotEqualObjects(labels[@"ns_st_vo"], @"0");
        return YES;
    }];
    
    self.mediaPlayerController.player.muted = NO;
    [self.mediaPlayerController pause];
    
    [self waitForExpectationsWithTimeout:20. handler:nil];
}

- (void)testNonSelectedSegmentPlayback
{
    [self expectationForComScoreHiddenEventNotificationWithHandler:^BOOL(NSString *event, NSDictionary *labels) {
        XCTAssertEqualObjects(labels[@"ns_st_ev"], @"play");
        XCTAssertEqualObjects(labels[@"stream_name"], @"full");
        XCTAssertNil(labels[@"segment_name"]);
        XCTAssertEqualObjects(labels[@"overridable_name"], @"full");
        return YES;
    }];
    
    SRGAnalyticsPlayerLabels *labels = [[SRGAnalyticsPlayerLabels alloc] init];
    labels.comScoreCustomInfo = @{ @"stream_name" : @"full",
                                   @"overridable_name" : @"full" };
    
    Segment *segment = [Segment segmentWithName:@"segment" timeRange:CMTimeRangeMake(CMTimeMakeWithSeconds(2., NSEC_PER_SEC), CMTimeMakeWithSeconds(3., NSEC_PER_SEC))];
    [self.mediaPlayerController playURL:OnDemandTestURL()
                                 atTime:kCMTimeZero
                           withSegments:@[segment]
                        analyticsLabels:labels
                               userInfo:nil];
    
    [self waitForExpectationsWithTimeout:20. handler:nil];
    
    // Let the segment be played through. No events must be received
    id eventObserver = [[NSNotificationCenter defaultCenter] addObserverForComScoreHiddenEventNotificationUsingBlock:^(NSString * _Nonnull event, NSDictionary * _Nonnull labels) {
        XCTFail(@"No event must be received");
    }];
    
    [self expectationForElapsedTimeInterval:3. withHandler:nil];
    
    [self waitForExpectationsWithTimeout:20. handler:^(NSError * _Nullable error) {
        [[NSNotificationCenter defaultCenter] removeObserver:eventObserver];
    }];
    
    // Pause playback. Expect full-length information
    [self expectationForComScoreHiddenEventNotificationWithHandler:^BOOL(NSString *event, NSDictionary *labels) {
        XCTAssertEqualObjects(labels[@"ns_st_ev"], @"pause");
        XCTAssertEqualObjects(labels[@"stream_name"], @"full");
        XCTAssertNil(labels[@"segment_name"]);
        XCTAssertEqualObjects(labels[@"overridable_name"], @"full");
        return YES;
    }];
    
    [self.mediaPlayerController pause];
    
    [self waitForExpectationsWithTimeout:20. handler:nil];
    
    // Resume playback. Expect full-length information
    [self expectationForComScoreHiddenEventNotificationWithHandler:^BOOL(NSString *event, NSDictionary *labels) {
        XCTAssertEqualObjects(labels[@"ns_st_ev"], @"play");
        XCTAssertEqualObjects(labels[@"stream_name"], @"full");
        XCTAssertNil(labels[@"segment_name"]);
        XCTAssertEqualObjects(labels[@"overridable_name"], @"full");
        return YES;
    }];
    
    [self.mediaPlayerController play];
    
    [self waitForExpectationsWithTimeout:20. handler:nil];
    
    id eventObserver2 = [[NSNotificationCenter defaultCenter] addObserverForComScoreHiddenEventNotificationUsingBlock:^(NSString * _Nonnull event, NSDictionary * _Nonnull labels) {
        // Also see http://stackoverflow.com/questions/14565405/avplayer-pauses-for-no-obvious-reason and
        // the demo project https://github.com/defagos/radars/tree/master/unexpected-player-rate-changes
        NSLog(@"[AVPlayer probable bug]: Unexpected state change to %@. Fast play - pause sequences can induce unexpected rate changes "
              "captured via KVO in our implementation. Those changes do not harm but cannot be tested reliably", @(self.mediaPlayerController.playbackState));
    }];
    
    [self expectationForElapsedTimeInterval:3. withHandler:nil];
    
    [self waitForExpectationsWithTimeout:30. handler:^(NSError * _Nullable error) {
        [[NSNotificationCenter defaultCenter] removeObserver:eventObserver2];
    }];
}

- (void)testSelectedSegmentPlayback
{
    [self expectationForComScoreHiddenEventNotificationWithHandler:^BOOL(NSString *event, NSDictionary *labels) {
        XCTAssertEqualObjects(labels[@"ns_st_ev"], @"play");
        XCTAssertEqualObjects(labels[@"stream_name"], @"full");
        XCTAssertEqualObjects(labels[@"segment_name"], @"segment");
        XCTAssertEqualObjects(labels[@"overridable_name"], @"segment");
        return YES;
    }];
    
    Segment *segment = [Segment segmentWithName:@"segment" timeRange:CMTimeRangeMake(CMTimeMakeWithSeconds(2., NSEC_PER_SEC), CMTimeMakeWithSeconds(10., NSEC_PER_SEC))];
    
    SRGAnalyticsPlayerLabels *labels = [[SRGAnalyticsPlayerLabels alloc] init];
    labels.comScoreCustomInfo = @{ @"stream_name" : @"full",
                                   @"overridable_name" : @"full" };
    
    [self.mediaPlayerController playURL:OnDemandTestURL()
                                atIndex:0
                             inSegments:@[segment]
                    withAnalyticsLabels:labels
                               userInfo:nil];
    
    [self waitForExpectationsWithTimeout:20. handler:nil];
    
    // Pause playback. Expect segment information
    [self expectationForComScoreHiddenEventNotificationWithHandler:^BOOL(NSString *event, NSDictionary *labels) {
        XCTAssertEqualObjects(labels[@"ns_st_ev"], @"pause");
        XCTAssertEqualObjects(labels[@"stream_name"], @"full");
        XCTAssertEqualObjects(labels[@"segment_name"], @"segment");
        XCTAssertEqualObjects(labels[@"overridable_name"], @"segment");
        return YES;
    }];
    
    [self.mediaPlayerController pause];
    
    [self waitForExpectationsWithTimeout:20. handler:nil];
    
    // Resume playback. Expect segment information
    [self expectationForComScoreHiddenEventNotificationWithHandler:^BOOL(NSString *event, NSDictionary *labels) {
        XCTAssertEqualObjects(labels[@"ns_st_ev"], @"play");
        XCTAssertEqualObjects(labels[@"stream_name"], @"full");
        XCTAssertEqualObjects(labels[@"segment_name"], @"segment");
        XCTAssertEqualObjects(labels[@"overridable_name"], @"segment");
        return YES;
    }];
    
    [self.mediaPlayerController play];
    
    [self waitForExpectationsWithTimeout:20. handler:nil];
}

- (void)testInitialSegmentSelectionAndPlaythrough
{
    // No end on full since we start with the segment, only a play for the segment
    [self expectationForComScoreHiddenEventNotificationWithHandler:^BOOL(NSString *event, NSDictionary *labels) {
        XCTAssertEqualObjects(labels[@"ns_st_ev"], @"play");
        XCTAssertEqualObjects(labels[@"stream_name"], @"full");
        XCTAssertEqualObjects(labels[@"segment_name"], @"segment");
        XCTAssertEqualObjects(labels[@"overridable_name"], @"segment");
        return YES;
    }];
    
    Segment *segment = [Segment segmentWithName:@"segment" timeRange:CMTimeRangeMake(CMTimeMakeWithSeconds(50., NSEC_PER_SEC), CMTimeMakeWithSeconds(3., NSEC_PER_SEC))];
    
    SRGAnalyticsPlayerLabels *labels = [[SRGAnalyticsPlayerLabels alloc] init];
    labels.comScoreCustomInfo = @{ @"stream_name" : @"full",
                                   @"overridable_name" : @"full" };
    
    [self.mediaPlayerController playURL:OnDemandTestURL()
                                atIndex:0
                             inSegments:@[segment]
                    withAnalyticsLabels:labels
                               userInfo:nil];
    
    [self waitForExpectationsWithTimeout:20. handler:nil];
    
    // Let the segment be played through until we receive the transition notifications (since both are the same, capture
    // them with a single expectation)
    
    __block BOOL segmentEndReceived = NO;
    __block BOOL fullPlayReceived = NO;
    
    [self expectationForComScoreHiddenEventNotificationWithHandler:^BOOL(NSString *event, NSDictionary *labels) {
        if ([event isEqualToString:@"end"]) {
            XCTAssertFalse(segmentEndReceived);
            XCTAssertFalse(fullPlayReceived);
            
            XCTAssertEqualObjects(labels[@"stream_name"], @"full");
            XCTAssertEqualObjects(labels[@"segment_name"], @"segment");
            XCTAssertEqualObjects(labels[@"overridable_name"], @"segment");
            segmentEndReceived = YES;
        }
        else if ([event isEqualToString:@"play"]) {
            XCTAssertFalse(fullPlayReceived);
            
            XCTAssertEqualObjects(labels[@"stream_name"], @"full");
            XCTAssertNil(labels[@"segment_name"]);
            XCTAssertEqualObjects(labels[@"overridable_name"], @"full");
            fullPlayReceived = YES;
        }
        else {
            XCTFail(@"Unexpected event %@", event);
        }
        
        return segmentEndReceived && fullPlayReceived;
    }];
    
    [self waitForExpectationsWithTimeout:20. handler:nil];
}

- (void)testSegmentSelectionAfterStartOnFullLength
{
    [self expectationForComScoreHiddenEventNotificationWithHandler:^BOOL(NSString *event, NSDictionary *labels) {
        XCTAssertEqualObjects(labels[@"ns_st_ev"], @"play");
        XCTAssertEqualObjects(labels[@"stream_name"], @"full");
        XCTAssertNil(labels[@"segment_name"]);
        XCTAssertEqualObjects(labels[@"overridable_name"], @"full");
        return YES;
    }];
    
    Segment *segment = [Segment segmentWithName:@"segment" timeRange:CMTimeRangeMake(CMTimeMakeWithSeconds(50., NSEC_PER_SEC), CMTimeMakeWithSeconds(3., NSEC_PER_SEC))];
    
    SRGAnalyticsPlayerLabels *labels = [[SRGAnalyticsPlayerLabels alloc] init];
    labels.comScoreCustomInfo = @{ @"stream_name" : @"full",
                                   @"overridable_name" : @"full" };
    
    [self.mediaPlayerController playURL:OnDemandTestURL()
                                 atTime:kCMTimeZero
                           withSegments:@[segment]
                        analyticsLabels:labels
                               userInfo:nil];
    
    [self waitForExpectationsWithTimeout:20. handler:nil];
    
    // When selecting a segment, usual playback events due to seeking must be inhibited
    
    __block BOOL fullEndReceived = NO;
    __block BOOL segmentPlayReceived = NO;
    
    [self expectationForComScoreHiddenEventNotificationWithHandler:^BOOL(NSString *event, NSDictionary *labels) {
        if ([event isEqualToString:@"end"]) {
            XCTAssertFalse(fullEndReceived);
            XCTAssertFalse(segmentPlayReceived);
            
            XCTAssertEqualObjects(labels[@"stream_name"], @"full");
            XCTAssertNil(labels[@"segment_name"]);
            XCTAssertEqualObjects(labels[@"overridable_name"], @"full");
            fullEndReceived = YES;
        }
        else if ([event isEqualToString:@"play"]) {
            XCTAssertFalse(segmentPlayReceived);
            
            XCTAssertEqualObjects(labels[@"stream_name"], @"full");
            XCTAssertEqualObjects(labels[@"segment_name"], @"segment");
            XCTAssertEqualObjects(labels[@"overridable_name"], @"segment");
            segmentPlayReceived = YES;
        }
        else {
            XCTFail(@"Unexpected event %@", event);
        }
        
        return fullEndReceived && segmentPlayReceived;
    }];
    
    [self.mediaPlayerController seekToSegment:segment withCompletionHandler:nil];
    
    [self waitForExpectationsWithTimeout:20. handler:nil];
}

- (void)testSegmentSelectionWhilePlayingSelectedSegment
{
    [self expectationForComScoreHiddenEventNotificationWithHandler:^BOOL(NSString *event, NSDictionary *labels) {
        XCTAssertEqualObjects(labels[@"ns_st_ev"], @"play");
        XCTAssertEqualObjects(labels[@"stream_name"], @"full");
        XCTAssertEqualObjects(labels[@"segment_name"], @"segment1");
        XCTAssertEqualObjects(labels[@"overridable_name"], @"segment1");
        return YES;
    }];
    
    Segment *segment1 = [Segment segmentWithName:@"segment1" timeRange:CMTimeRangeMake(CMTimeMakeWithSeconds(50., NSEC_PER_SEC), CMTimeMakeWithSeconds(10., NSEC_PER_SEC))];
    Segment *segment2 = [Segment segmentWithName:@"segment2" timeRange:CMTimeRangeMake(CMTimeMakeWithSeconds(100., NSEC_PER_SEC), CMTimeMakeWithSeconds(10., NSEC_PER_SEC))];
    
    SRGAnalyticsPlayerLabels *labels = [[SRGAnalyticsPlayerLabels alloc] init];
    labels.comScoreCustomInfo = @{ @"stream_name" : @"full",
                                   @"overridable_name" : @"full" };
    
    [self.mediaPlayerController playURL:OnDemandTestURL()
                                atIndex:0
                             inSegments:@[segment1, segment2]
                    withAnalyticsLabels:labels
                               userInfo:nil];
    
    [self waitForExpectationsWithTimeout:20. handler:nil];
    
    // Expect segment transition (but no playback events) when selecting another segment
    
    __block BOOL segment1EndReceived = NO;
    __block BOOL segment2PlayReceived = NO;
    
    [self expectationForComScoreHiddenEventNotificationWithHandler:^BOOL(NSString *event, NSDictionary *labels) {
        if ([event isEqualToString:@"end"]) {
            XCTAssertFalse(segment1EndReceived);
            XCTAssertFalse(segment2PlayReceived);
            
            XCTAssertEqualObjects(labels[@"stream_name"], @"full");
            XCTAssertEqualObjects(labels[@"segment_name"], @"segment1");
            XCTAssertEqualObjects(labels[@"overridable_name"], @"segment1");
            segment1EndReceived = YES;
        }
        else if ([event isEqualToString:@"play"]) {
            XCTAssertFalse(segment2PlayReceived);
            
            XCTAssertEqualObjects(labels[@"stream_name"], @"full");
            XCTAssertEqualObjects(labels[@"segment_name"], @"segment2");
            XCTAssertEqualObjects(labels[@"overridable_name"], @"segment2");
            segment2PlayReceived = YES;
        }
        else {
            XCTFail(@"Unexpected event %@", event);
        }
        
        return segment1EndReceived && segment2PlayReceived;
    }];
    
    [self.mediaPlayerController seekToSegment:segment2 withCompletionHandler:nil];
    
    [self waitForExpectationsWithTimeout:20. handler:nil];
}

- (void)testTransitionFromSelectedSegmentIntoNonSelectedContiguousSegment
{
    [self expectationForComScoreHiddenEventNotificationWithHandler:^BOOL(NSString *event, NSDictionary *labels) {
        XCTAssertEqualObjects(labels[@"ns_st_ev"], @"play");
        XCTAssertEqualObjects(labels[@"stream_name"], @"full");
        XCTAssertEqualObjects(labels[@"segment_name"], @"segment1");
        XCTAssertEqualObjects(labels[@"overridable_name"], @"segment1");
        return YES;
    }];
    
    Segment *segment1 = [Segment segmentWithName:@"segment1" timeRange:CMTimeRangeMake(CMTimeMakeWithSeconds(20., NSEC_PER_SEC), CMTimeMakeWithSeconds(3., NSEC_PER_SEC))];
    Segment *segment2 = [Segment segmentWithName:@"segment2" timeRange:CMTimeRangeMake(CMTimeMakeWithSeconds(23., NSEC_PER_SEC), CMTimeMakeWithSeconds(3., NSEC_PER_SEC))];
    
    SRGAnalyticsPlayerLabels *labels = [[SRGAnalyticsPlayerLabels alloc] init];
    labels.comScoreCustomInfo = @{ @"stream_name" : @"full",
                                   @"overridable_name" : @"full" };
    
    [self.mediaPlayerController playURL:OnDemandTestURL()
                                atIndex:0
                             inSegments:@[segment1, segment2]
                    withAnalyticsLabels:labels
                               userInfo:nil];
    
    [self waitForExpectationsWithTimeout:20. handler:nil];
    
    // Let the segment be played through. A transition into the full-length is expected since the second segment
    // is not selected
    
    __block BOOL segment1EndReceived = NO;
    __block BOOL fullLengthPlayReceived = NO;
    
    [self expectationForComScoreHiddenEventNotificationWithHandler:^BOOL(NSString *event, NSDictionary *labels) {
        if ([event isEqualToString:@"end"]) {
            XCTAssertFalse(segment1EndReceived);
            XCTAssertFalse(fullLengthPlayReceived);
            
            XCTAssertEqualObjects(labels[@"stream_name"], @"full");
            XCTAssertEqualObjects(labels[@"segment_name"], @"segment1");
            XCTAssertEqualObjects(labels[@"overridable_name"], @"segment1");
            segment1EndReceived = YES;
        }
        else if ([event isEqualToString:@"play"]) {
            XCTAssertFalse(fullLengthPlayReceived);
            
            XCTAssertEqualObjects(labels[@"stream_name"], @"full");
            XCTAssertNil(labels[@"segment_name"]);
            XCTAssertEqualObjects(labels[@"overridable_name"], @"full");
            fullLengthPlayReceived = YES;
        }
        else {
            XCTFail(@"Unexpected event %@", event);
        }
        
        return segment1EndReceived && fullLengthPlayReceived;
    }];
    
    [self waitForExpectationsWithTimeout:20. handler:nil];
}

- (void)testSegmentRepeatedSelection
{
    [self expectationForComScoreHiddenEventNotificationWithHandler:^BOOL(NSString *event, NSDictionary *labels) {
        XCTAssertEqualObjects(labels[@"ns_st_ev"], @"play");
        XCTAssertEqualObjects(labels[@"stream_name"], @"full");
        XCTAssertEqualObjects(labels[@"segment_name"], @"segment");
        XCTAssertEqualObjects(labels[@"overridable_name"], @"segment");
        return YES;
    }];
    
    Segment *segment = [Segment segmentWithName:@"segment" timeRange:CMTimeRangeMake(CMTimeMakeWithSeconds(50., NSEC_PER_SEC), CMTimeMakeWithSeconds(10., NSEC_PER_SEC))];
    
    SRGAnalyticsPlayerLabels *labels = [[SRGAnalyticsPlayerLabels alloc] init];
    labels.comScoreCustomInfo = @{ @"stream_name" : @"full",
                                   @"overridable_name" : @"full" };
    
    [self.mediaPlayerController playURL:OnDemandTestURL()
                                atIndex:0
                             inSegments:@[segment]
                    withAnalyticsLabels:labels
                               userInfo:nil];
    
    [self waitForExpectationsWithTimeout:20. handler:nil];
    
    // Expect segment transition (but no playback events) when selecting another segment
    
    __block BOOL segmentEndReceived = NO;
    __block BOOL segmentPlayReceived = NO;
    
    [self expectationForComScoreHiddenEventNotificationWithHandler:^BOOL(NSString *event, NSDictionary *labels) {
        if ([event isEqualToString:@"end"]) {
            XCTAssertFalse(segmentEndReceived);
            XCTAssertFalse(segmentPlayReceived);
            
            XCTAssertEqualObjects(labels[@"stream_name"], @"full");
            XCTAssertEqualObjects(labels[@"segment_name"], @"segment");
            XCTAssertEqualObjects(labels[@"overridable_name"], @"segment");
            segmentEndReceived = YES;
        }
        else if ([event isEqualToString:@"play"]) {
            XCTAssertFalse(segmentPlayReceived);
            
            XCTAssertEqualObjects(labels[@"stream_name"], @"full");
            XCTAssertEqualObjects(labels[@"segment_name"], @"segment");
            XCTAssertEqualObjects(labels[@"overridable_name"], @"segment");
            segmentPlayReceived = YES;
        }
        else {
            XCTFail(@"Unexpected event %@", event);
        }
        
        return segmentEndReceived && segmentPlayReceived;
    }];
    
    [self.mediaPlayerController seekToSegment:segment withCompletionHandler:nil];
    
    [self waitForExpectationsWithTimeout:20. handler:nil];
}

- (void)testSeekOutsideSelectedSegment
{
    [self expectationForComScoreHiddenEventNotificationWithHandler:^BOOL(NSString *event, NSDictionary *labels) {
        XCTAssertEqualObjects(labels[@"ns_st_ev"], @"play");
        XCTAssertEqualObjects(labels[@"stream_name"], @"full");
        XCTAssertEqualObjects(labels[@"segment_name"], @"segment1");
        XCTAssertEqualObjects(labels[@"overridable_name"], @"segment1");
        return YES;
    }];
    
    Segment *segment1 = [Segment segmentWithName:@"segment1" timeRange:CMTimeRangeMake(CMTimeMakeWithSeconds(50., NSEC_PER_SEC), CMTimeMakeWithSeconds(10., NSEC_PER_SEC))];
    Segment *segment2 = [Segment segmentWithName:@"segment2" timeRange:CMTimeRangeMake(CMTimeMakeWithSeconds(60., NSEC_PER_SEC), CMTimeMakeWithSeconds(20., NSEC_PER_SEC))];
    
    SRGAnalyticsPlayerLabels *labels = [[SRGAnalyticsPlayerLabels alloc] init];
    labels.comScoreCustomInfo = @{ @"stream_name" : @"full",
                                   @"overridable_name" : @"full" };
    
    [self.mediaPlayerController playURL:OnDemandTestURL()
                                atIndex:0
                             inSegments:@[segment1, segment2]
                    withAnalyticsLabels:labels
                               userInfo:nil];
    
    [self waitForExpectationsWithTimeout:20. handler:nil];
    
    // Expect transition into the full-length since, even if seeking resumes in another segment (since this segment has
    // not been selected, we don't want to track it). Because of a seek, a pause in the segment is expected first
    
    __block BOOL segment1PauseReceived = NO;
    __block BOOL segment1EndReceived = NO;
    __block BOOL fullLengthPlayReceived = NO;
    
    [self expectationForComScoreHiddenEventNotificationWithHandler:^BOOL(NSString *event, NSDictionary *labels) {
        if ([event isEqualToString:@"pause"]) {
            XCTAssertFalse(segment1PauseReceived);
            XCTAssertFalse(segment1EndReceived);
            XCTAssertFalse(fullLengthPlayReceived);
            
            XCTAssertEqualObjects(labels[@"stream_name"], @"full");
            XCTAssertEqualObjects(labels[@"segment_name"], @"segment1");
            XCTAssertEqualObjects(labels[@"overridable_name"], @"segment1");
            segment1PauseReceived = YES;
        }
        else if ([event isEqualToString:@"end"]) {
            XCTAssertFalse(segment1EndReceived);
            XCTAssertFalse(fullLengthPlayReceived);
            
            XCTAssertEqualObjects(labels[@"stream_name"], @"full");
            XCTAssertEqualObjects(labels[@"segment_name"], @"segment1");
            XCTAssertEqualObjects(labels[@"overridable_name"], @"segment1");
            segment1EndReceived = YES;
        }
        else if ([event isEqualToString:@"play"]) {
            XCTAssertFalse(fullLengthPlayReceived);
            
            XCTAssertEqualObjects(labels[@"stream_name"], @"full");
            XCTAssertNil(labels[@"segment_name"]);
            XCTAssertEqualObjects(labels[@"overridable_name"], @"full");
            fullLengthPlayReceived = YES;
        }
        
        return segment1PauseReceived && segment1EndReceived && fullLengthPlayReceived;
    }];
    
    [self.mediaPlayerController seekPreciselyToTime:CMTimeAdd(CMTimeRangeGetEnd(segment1.srg_timeRange), CMTimeMakeWithSeconds(10., NSEC_PER_SEC)) withCompletionHandler:nil];
    
    [self waitForExpectationsWithTimeout:20. handler:nil];
}

- (void)testSeekWithinSelectedSegment
{
    [self expectationForComScoreHiddenEventNotificationWithHandler:^BOOL(NSString *event, NSDictionary *labels) {
        XCTAssertEqualObjects(labels[@"ns_st_ev"], @"play");
        XCTAssertEqualObjects(labels[@"stream_name"], @"full");
        XCTAssertEqualObjects(labels[@"segment_name"], @"segment");
        XCTAssertEqualObjects(labels[@"overridable_name"], @"segment");
        return YES;
    }];
    
    Segment *segment = [Segment segmentWithName:@"segment" timeRange:CMTimeRangeMake(CMTimeMakeWithSeconds(50., NSEC_PER_SEC), CMTimeMakeWithSeconds(10., NSEC_PER_SEC))];
    
    SRGAnalyticsPlayerLabels *labels = [[SRGAnalyticsPlayerLabels alloc] init];
    labels.comScoreCustomInfo = @{ @"stream_name" : @"full",
                                   @"overridable_name" : @"full" };
    
    [self.mediaPlayerController playURL:OnDemandTestURL()
                                atIndex:0
                             inSegments:@[segment]
                    withAnalyticsLabels:labels
                               userInfo:nil];
    
    [self waitForExpectationsWithTimeout:20. handler:nil];
    
    // Expect play - pause transition with segment labels
    
    __block BOOL segmentPauseReceived = NO;
    __block BOOL segmentPlayReceived = NO;
    
    [self expectationForComScoreHiddenEventNotificationWithHandler:^BOOL(NSString *event, NSDictionary *labels) {
        if ([event isEqualToString:@"pause"]) {
            XCTAssertFalse(segmentPauseReceived);
            XCTAssertFalse(segmentPlayReceived);
            
            XCTAssertEqualObjects(labels[@"stream_name"], @"full");
            XCTAssertEqualObjects(labels[@"segment_name"], @"segment");
            XCTAssertEqualObjects(labels[@"overridable_name"], @"segment");
            segmentPauseReceived = YES;
        }
        else if ([event isEqualToString:@"play"]) {
            XCTAssertFalse(segmentPlayReceived);
            
            XCTAssertEqualObjects(labels[@"stream_name"], @"full");
            XCTAssertEqualObjects(labels[@"segment_name"], @"segment");
            XCTAssertEqualObjects(labels[@"overridable_name"], @"segment");
            segmentPlayReceived = YES;
        }
        else {
            XCTFail(@"Unexpected event %@", event);
        }
        
        return segmentPauseReceived && segmentPlayReceived;
    }];
    
    [self.mediaPlayerController seekPreciselyToTime:CMTimeAdd(segment.srg_timeRange.start, CMTimeMakeWithSeconds(3., NSEC_PER_SEC)) withCompletionHandler:nil];
    
    [self waitForExpectationsWithTimeout:20. handler:nil];
}

- (void)testSelectedSegmentAtStreamEnd
{
    // Precise timing information gathered from the stream itself
    Segment *segment = [Segment segmentWithName:@"segment" timeRange:CMTimeRangeMake(CMTimeMakeWithSeconds(1795.045, NSEC_PER_SEC), CMTimeMakeWithSeconds(5., NSEC_PER_SEC))];
    
    [self expectationForComScoreHiddenEventNotificationWithHandler:^BOOL(NSString *event, NSDictionary *labels) {
        XCTAssertEqualObjects(labels[@"ns_st_ev"], @"play");
        XCTAssertEqualObjects(labels[@"stream_name"], @"full");
        XCTAssertEqualObjects(labels[@"segment_name"], @"segment");
        XCTAssertEqualObjects(labels[@"overridable_name"], @"segment");
        return YES;
    }];
    
    SRGAnalyticsPlayerLabels *labels = [[SRGAnalyticsPlayerLabels alloc] init];
    labels.comScoreCustomInfo = @{ @"stream_name" : @"full",
                                   @"overridable_name" : @"full" };
    
    [self.mediaPlayerController playURL:OnDemandTestURL()
                                atIndex:0
                             inSegments:@[segment]
                    withAnalyticsLabels:labels
                               userInfo:nil];
    
    [self waitForExpectationsWithTimeout:20. handler:nil];
    
    XCTAssertEqualObjects(self.mediaPlayerController.currentSegment, segment);
    XCTAssertEqualObjects(self.mediaPlayerController.selectedSegment, segment);
    
    // Expect end of segment and play / end for the full-length (which does not harm for statistics)
    
    __block BOOL segmentEndReceived = NO;
    __block BOOL fullLengthPlayReceived = NO;
    __block BOOL fullLengthEndReceived = NO;
    
    [self expectationForComScoreHiddenEventNotificationWithHandler:^BOOL(NSString *event, NSDictionary *labels) {
        if ([event isEqualToString:@"end"]) {
            if (! segmentEndReceived) {
                XCTAssertFalse(fullLengthPlayReceived);
                XCTAssertFalse(fullLengthEndReceived);
                
                XCTAssertEqualObjects(labels[@"stream_name"], @"full");
                XCTAssertEqualObjects(labels[@"segment_name"], @"segment");
                XCTAssertEqualObjects(labels[@"overridable_name"], @"segment");
                segmentEndReceived = YES;
            }
            else {
                XCTAssertFalse(fullLengthEndReceived);
                
                XCTAssertEqualObjects(labels[@"stream_name"], @"full");
                XCTAssertNil(labels[@"segment_name"]);
                XCTAssertEqualObjects(labels[@"overridable_name"], @"full");
                fullLengthEndReceived = YES;
            }
        }
        else if ([event isEqualToString:@"play"]) {
            XCTAssertFalse(fullLengthPlayReceived);
            XCTAssertFalse(fullLengthEndReceived);
            
            XCTAssertEqualObjects(labels[@"stream_name"], @"full");
            XCTAssertNil(labels[@"segment_name"]);
            XCTAssertEqualObjects(labels[@"overridable_name"], @"full");
            fullLengthPlayReceived = YES;
        }
        else {
            XCTFail(@"Unexpected event %@", event);
        }
        
        return segmentEndReceived && fullLengthPlayReceived && fullLengthEndReceived;
    }];
    
    [self waitForExpectationsWithTimeout:20. handler:nil];
    
    XCTAssertNil(self.mediaPlayerController.currentSegment);
    XCTAssertNil(self.mediaPlayerController.selectedSegment);
}

- (void)testResetWhilePlayingSegment
{
    [self expectationForComScoreHiddenEventNotificationWithHandler:^BOOL(NSString *event, NSDictionary *labels) {
        XCTAssertEqualObjects(labels[@"ns_st_ev"], @"play");
        XCTAssertEqualObjects(labels[@"stream_name"], @"full");
        XCTAssertEqualObjects(labels[@"segment_name"], @"segment");
        XCTAssertEqualObjects(labels[@"overridable_name"], @"segment");
        return YES;
    }];
    
    Segment *segment = [Segment segmentWithName:@"segment" timeRange:CMTimeRangeMake(CMTimeMakeWithSeconds(50., NSEC_PER_SEC), CMTimeMakeWithSeconds(10., NSEC_PER_SEC))];
    
    SRGAnalyticsPlayerLabels *labels = [[SRGAnalyticsPlayerLabels alloc] init];
    labels.comScoreCustomInfo = @{ @"stream_name" : @"full",
                                   @"overridable_name" : @"full" };
    
    [self.mediaPlayerController playURL:OnDemandTestURL()
                                atIndex:0
                             inSegments:@[segment]
                    withAnalyticsLabels:labels
                               userInfo:nil];
    
    [self waitForExpectationsWithTimeout:20. handler:nil];
    
    // Expect end event with segment labels
    
    [self expectationForComScoreHiddenEventNotificationWithHandler:^BOOL(NSString *event, NSDictionary *labels) {
        XCTAssertEqualObjects(labels[@"ns_st_ev"], @"end");
        XCTAssertEqualObjects(labels[@"stream_name"], @"full");
        XCTAssertEqualObjects(labels[@"segment_name"], @"segment");
        XCTAssertEqualObjects(labels[@"overridable_name"], @"segment");
        return YES;
    }];
    
    [self.mediaPlayerController reset];
    
    [self waitForExpectationsWithTimeout:20. handler:nil];
}

- (void)testBlockedSegmentSelection
{
    [self expectationForComScoreHiddenEventNotificationWithHandler:^BOOL(NSString *event, NSDictionary *labels) {
        XCTAssertEqualObjects(labels[@"ns_st_ev"], @"play");
        XCTAssertEqualObjects(labels[@"stream_name"], @"full");
        XCTAssertNil(labels[@"segment_name"]);
        XCTAssertEqualObjects(labels[@"overridable_name"], @"full");
        return YES;
    }];
    
    Segment *segment = [Segment blockedSegmentWithName:@"segment" timeRange:CMTimeRangeMake(CMTimeMakeWithSeconds(50., NSEC_PER_SEC), CMTimeMakeWithSeconds(10., NSEC_PER_SEC))];
    
    SRGAnalyticsPlayerLabels *labels = [[SRGAnalyticsPlayerLabels alloc] init];
    labels.comScoreCustomInfo = @{ @"stream_name" : @"full",
                                   @"overridable_name" : @"full" };
    
    [self.mediaPlayerController playURL:OnDemandTestURL()
                                 atTime:kCMTimeZero
                           withSegments:@[segment]
                        analyticsLabels:labels
                               userInfo:nil];
    
    [self waitForExpectationsWithTimeout:20. handler:nil];
    
    // Expect pause and play on the full-length (corresponding to the segment being skipped)
    
    __block BOOL fullLengthPauseReceived = NO;
    __block BOOL fullLengthPlayReceived = NO;
    
    [self expectationForComScoreHiddenEventNotificationWithHandler:^BOOL(NSString *event, NSDictionary *labels) {
        if ([event isEqualToString:@"pause"]) {
            XCTAssertFalse(fullLengthPauseReceived);
            XCTAssertFalse(fullLengthPlayReceived);
            
            XCTAssertEqualObjects(labels[@"stream_name"], @"full");
            XCTAssertNil(labels[@"segment_name"]);
            XCTAssertEqualObjects(labels[@"overridable_name"], @"full");
            fullLengthPauseReceived = YES;
        }
        else if ([event isEqualToString:@"play"]) {
            XCTAssertFalse(fullLengthPlayReceived);
            
            XCTAssertEqualObjects(labels[@"stream_name"], @"full");
            XCTAssertNil(labels[@"segment_name"]);
            XCTAssertEqualObjects(labels[@"overridable_name"], @"full");
            fullLengthPlayReceived = YES;
        }
        else {
            XCTFail(@"Unexpected event %@", event);
        }
        
        return fullLengthPauseReceived && fullLengthPlayReceived;
    }];
    
    [self.mediaPlayerController seekToSegment:segment withCompletionHandler:nil];
    
    [self waitForExpectationsWithTimeout:20. handler:nil];
}

- (void)testSeekIntoBlockedSegment
{
    [self expectationForComScoreHiddenEventNotificationWithHandler:^BOOL(NSString *event, NSDictionary *labels) {
        XCTAssertEqualObjects(labels[@"ns_st_ev"], @"play");
        XCTAssertEqualObjects(labels[@"stream_name"], @"full");
        XCTAssertNil(labels[@"segment_name"]);
        XCTAssertEqualObjects(labels[@"overridable_name"], @"full");
        return YES;
    }];
    
    Segment *segment = [Segment blockedSegmentWithName:@"segment" timeRange:CMTimeRangeMake(CMTimeMakeWithSeconds(50., NSEC_PER_SEC), CMTimeMakeWithSeconds(10., NSEC_PER_SEC))];
    
    SRGAnalyticsPlayerLabels *labels = [[SRGAnalyticsPlayerLabels alloc] init];
    labels.comScoreCustomInfo = @{ @"stream_name" : @"full",
                                   @"overridable_name" : @"full" };
    
    [self.mediaPlayerController playURL:OnDemandTestURL()
                                 atTime:kCMTimeZero
                           withSegments:@[segment]
                        analyticsLabels:labels
                               userInfo:nil];
    
    [self waitForExpectationsWithTimeout:20. handler:nil];
    
    // Expect pause / play for the full-length
    
    __block BOOL fullLengthPauseReceived = NO;
    __block BOOL fullLengthPlayReceived = NO;
    
    [self expectationForComScoreHiddenEventNotificationWithHandler:^BOOL(NSString *event, NSDictionary *labels) {
        if ([event isEqualToString:@"pause"]) {
            XCTAssertFalse(fullLengthPauseReceived);
            XCTAssertFalse(fullLengthPlayReceived);
            
            XCTAssertEqualObjects(labels[@"stream_name"], @"full");
            XCTAssertNil(labels[@"segment_name"]);
            XCTAssertEqualObjects(labels[@"overridable_name"], @"full");
            fullLengthPauseReceived = YES;
        }
        else if ([event isEqualToString:@"play"]) {
            XCTAssertFalse(fullLengthPlayReceived);
            
            XCTAssertEqualObjects(labels[@"stream_name"], @"full");
            XCTAssertNil(labels[@"segment_name"]);
            XCTAssertEqualObjects(labels[@"overridable_name"], @"full");
            fullLengthPlayReceived = YES;
        }
        else {
            XCTFail(@"Unexpected event %@", event);
        }
        
        return fullLengthPauseReceived && fullLengthPlayReceived;
    }];
    
    [self.mediaPlayerController seekPreciselyToTime:CMTimeMakeWithSeconds(55., NSEC_PER_SEC) withCompletionHandler:nil];
    
    [self waitForExpectationsWithTimeout:20. handler:nil];
}

- (void)testPlayStartingWithBlockedSegment
{
    [self expectationForComScoreHiddenEventNotificationWithHandler:^BOOL(NSString *event, NSDictionary *labels) {
        XCTAssertEqualObjects(labels[@"ns_st_ev"], @"play");
        XCTAssertEqualObjects(labels[@"stream_name"], @"full");
        XCTAssertNil(labels[@"segment_name"]);
        XCTAssertEqualObjects(labels[@"overridable_name"], @"full");
        return YES;
    }];
    
    Segment *segment = [Segment blockedSegmentWithName:@"segment" timeRange:CMTimeRangeMake(CMTimeMakeWithSeconds(50., NSEC_PER_SEC), CMTimeMakeWithSeconds(10., NSEC_PER_SEC))];
    
    SRGAnalyticsPlayerLabels *labels = [[SRGAnalyticsPlayerLabels alloc] init];
    labels.comScoreCustomInfo = @{ @"stream_name" : @"full",
                                   @"overridable_name" : @"full" };
    
    [self.mediaPlayerController playURL:OnDemandTestURL()
                                atIndex:0
                             inSegments:@[segment]
                    withAnalyticsLabels:labels
                               userInfo:nil];
    
    [self waitForExpectationsWithTimeout:20. handler:nil];
    
    // Expect pause / play for the full-length
    
    __block BOOL fullLengthPauseReceived = NO;
    __block BOOL fullLengthPlayReceived = NO;
    
    [self expectationForComScoreHiddenEventNotificationWithHandler:^BOOL(NSString *event, NSDictionary *labels) {
        if ([event isEqualToString:@"pause"]) {
            XCTAssertFalse(fullLengthPauseReceived);
            XCTAssertFalse(fullLengthPlayReceived);
            
            XCTAssertEqualObjects(labels[@"stream_name"], @"full");
            XCTAssertNil(labels[@"segment_name"]);
            XCTAssertEqualObjects(labels[@"overridable_name"], @"full");
            fullLengthPauseReceived = YES;
        }
        else if ([event isEqualToString:@"play"]) {
            XCTAssertFalse(fullLengthPlayReceived);
            
            XCTAssertEqualObjects(labels[@"stream_name"], @"full");
            XCTAssertNil(labels[@"segment_name"]);
            XCTAssertEqualObjects(labels[@"overridable_name"], @"full");
            fullLengthPlayReceived = YES;
        }
        else {
            XCTFail(@"Unexpected event %@", event);
        }
        
        return fullLengthPauseReceived && fullLengthPlayReceived;
    }];
    
    [self.mediaPlayerController seekPreciselyToTime:CMTimeMakeWithSeconds(55., NSEC_PER_SEC) withCompletionHandler:nil];
    
    [self waitForExpectationsWithTimeout:20. handler:nil];
}

- (void)testBlockedSegmentPlaythrough
{
    [self expectationForComScoreHiddenEventNotificationWithHandler:^BOOL(NSString *event, NSDictionary *labels) {
        XCTAssertEqualObjects(labels[@"ns_st_ev"], @"play");
        XCTAssertEqualObjects(labels[@"stream_name"], @"full");
        XCTAssertNil(labels[@"segment_name"]);
        XCTAssertEqualObjects(labels[@"overridable_name"], @"full");
        return YES;
    }];
    
    Segment *segment = [Segment blockedSegmentWithName:@"segment" timeRange:CMTimeRangeMake(CMTimeMakeWithSeconds(2., NSEC_PER_SEC), CMTimeMakeWithSeconds(3., NSEC_PER_SEC))];
    
    SRGAnalyticsPlayerLabels *labels = [[SRGAnalyticsPlayerLabels alloc] init];
    labels.comScoreCustomInfo = @{ @"stream_name" : @"full",
                                   @"overridable_name" : @"full" };
    
    [self.mediaPlayerController playURL:OnDemandTestURL()
                                 atTime:kCMTimeZero
                           withSegments:@[segment]
                        analyticsLabels:labels
                               userInfo:nil];
    
    [self waitForExpectationsWithTimeout:20. handler:nil];
    
    // Play for a while. Expect pause / play for the full-length when skipping over the segment
    
    __block BOOL fullLengthPauseReceived = NO;
    __block BOOL fullLengthPlayReceived = NO;
    
    [self expectationForComScoreHiddenEventNotificationWithHandler:^BOOL(NSString *event, NSDictionary *labels) {
        if ([event isEqualToString:@"pause"]) {
            XCTAssertFalse(fullLengthPauseReceived);
            XCTAssertFalse(fullLengthPlayReceived);
            
            XCTAssertEqualObjects(labels[@"stream_name"], @"full");
            XCTAssertNil(labels[@"segment_name"]);
            XCTAssertEqualObjects(labels[@"overridable_name"], @"full");
            fullLengthPauseReceived = YES;
        }
        else if ([event isEqualToString:@"play"]) {
            XCTAssertFalse(fullLengthPlayReceived);
            
            XCTAssertEqualObjects(labels[@"stream_name"], @"full");
            XCTAssertNil(labels[@"segment_name"]);
            XCTAssertEqualObjects(labels[@"overridable_name"], @"full");
            fullLengthPlayReceived = YES;
        }
        else {
            XCTFail(@"Unexpected event %@", event);
        }
        
        return fullLengthPauseReceived && fullLengthPlayReceived;
    }];
    
    [self waitForExpectationsWithTimeout:20. handler:nil];
}

- (void)testDisableTrackingWhileIdle
{
    // Play for a while. No stream events must be received
    id eventObserver = [[NSNotificationCenter defaultCenter] addObserverForComScoreHiddenEventNotificationUsingBlock:^(NSString * _Nonnull event, NSDictionary * _Nonnull labels) {
        XCTFail(@"No event must be received when tracking has been disabled");
    }];
    
    [self expectationForElapsedTimeInterval:5. withHandler:nil];
    
    self.mediaPlayerController.tracked = NO;
    [self.mediaPlayerController playURL:OnDemandTestURL()];
    
    [self waitForExpectationsWithTimeout:20. handler:^(NSError * _Nullable error) {
        [[NSNotificationCenter defaultCenter] removeObserver:eventObserver];
    }];
}

- (void)testDisableTrackingWhilePreparing
{
    // Wait until the player is preparing to play
    [self expectationForNotification:SRGMediaPlayerPlaybackStateDidChangeNotification object:self.mediaPlayerController handler:^BOOL(NSNotification * _Nonnull notification) {
        XCTAssertEqual([notification.userInfo[SRGMediaPlayerPlaybackStateKey] integerValue], SRGMediaPlayerPlaybackStatePreparing);
        return YES;
    }];
    
    [self.mediaPlayerController playURL:OnDemandTestURL()];
    
    [self waitForExpectationsWithTimeout:20. handler:nil];
    
    // Play for a while. No stream events must be received
    id eventObserver = [[NSNotificationCenter defaultCenter] addObserverForComScoreHiddenEventNotificationUsingBlock:^(NSString * _Nonnull event, NSDictionary * _Nonnull labels) {
        XCTFail(@"No event must be received when tracking has been disabled");
    }];
    
    [self expectationForElapsedTimeInterval:5. withHandler:nil];
    
    XCTAssertEqual(self.mediaPlayerController.playbackState, SRGMediaPlayerPlaybackStatePreparing);
    self.mediaPlayerController.tracked = NO;
    
    [self waitForExpectationsWithTimeout:20. handler:^(NSError * _Nullable error) {
        [[NSNotificationCenter defaultCenter] removeObserver:eventObserver];
    }];
}

- (void)testDisableTrackingWhilePlaying
{
    // Wait until the media plays
    [self expectationForComScoreHiddenEventNotificationWithHandler:^BOOL(NSString *event, NSDictionary *labels) {
        XCTAssertEqualObjects(event, @"play");
        return YES;
    }];
    
    [self.mediaPlayerController playURL:OnDemandTestURL()];
    
    [self waitForExpectationsWithTimeout:20. handler:nil];
    
    // Stop tracking while playing. Expect an end to be received
    [self expectationForComScoreHiddenEventNotificationWithHandler:^BOOL(NSString *event, NSDictionary *labels) {
        XCTAssertEqualObjects(event, @"end");
        return YES;
    }];
    
    XCTAssertEqual(self.mediaPlayerController.playbackState, SRGMediaPlayerPlaybackStatePlaying);
    self.mediaPlayerController.tracked = NO;
    
    [self waitForExpectationsWithTimeout:20. handler:nil];
}

- (void)testDisableTrackingWhilePlayingSegment
{
    // Wait until the media plays. Expect segment labels
    [self expectationForComScoreHiddenEventNotificationWithHandler:^BOOL(NSString *event, NSDictionary *labels) {
        XCTAssertEqualObjects(labels[@"ns_st_ev"], @"play");
        XCTAssertEqualObjects(labels[@"stream_name"], @"full");
        XCTAssertEqualObjects(labels[@"segment_name"], @"segment");
        XCTAssertEqualObjects(labels[@"overridable_name"], @"segment");
        return YES;
    }];
    
    Segment *segment = [Segment segmentWithName:@"segment" timeRange:CMTimeRangeMake(CMTimeMakeWithSeconds(2., NSEC_PER_SEC), CMTimeMakeWithSeconds(3., NSEC_PER_SEC))];
    
    SRGAnalyticsPlayerLabels *labels = [[SRGAnalyticsPlayerLabels alloc] init];
    labels.comScoreCustomInfo = @{ @"stream_name" : @"full",
                                   @"overridable_name" : @"full" };
    
    [self.mediaPlayerController playURL:OnDemandTestURL()
                                atIndex:0
                             inSegments:@[segment]
                    withAnalyticsLabels:labels
                               userInfo:nil];
    
    [self waitForExpectationsWithTimeout:20. handler:nil];
    
    // Stop tracking while playing. Expect an end to be received with segment labels
    [self expectationForComScoreHiddenEventNotificationWithHandler:^BOOL(NSString *event, NSDictionary *labels) {
        XCTAssertEqualObjects(labels[@"ns_st_ev"], @"end");
        XCTAssertEqualObjects(labels[@"stream_name"], @"full");
        XCTAssertEqualObjects(labels[@"segment_name"], @"segment");
        XCTAssertEqualObjects(labels[@"overridable_name"], @"segment");
        return YES;
    }];
    
    XCTAssertEqual(self.mediaPlayerController.playbackState, SRGMediaPlayerPlaybackStatePlaying);
    self.mediaPlayerController.tracked = NO;
    
    [self waitForExpectationsWithTimeout:20. handler:nil];
}

- (void)testDisableTrackingWhilePaused
{
    // Wait until the media plays
    [self expectationForComScoreHiddenEventNotificationWithHandler:^BOOL(NSString *event, NSDictionary *labels) {
        XCTAssertEqualObjects(event, @"play");
        return YES;
    }];
    
    [self.mediaPlayerController playURL:OnDemandTestURL()];
    
    [self waitForExpectationsWithTimeout:20. handler:nil];
    
    // Pause playback
    [self expectationForComScoreHiddenEventNotificationWithHandler:^BOOL(NSString *event, NSDictionary *labels) {
        XCTAssertEqualObjects(event, @"pause");
        return YES;
    }];
    
    [self.mediaPlayerController pause];
    
    [self waitForExpectationsWithTimeout:20. handler:nil];
    
    // Stop tracking while paused. Expect an end to be received
    [self expectationForComScoreHiddenEventNotificationWithHandler:^BOOL(NSString *event, NSDictionary *labels) {
        XCTAssertEqualObjects(event, @"end");
        return YES;
    }];
    
    XCTAssertEqual(self.mediaPlayerController.playbackState, SRGMediaPlayerPlaybackStatePaused);
    self.mediaPlayerController.tracked = NO;
    
    [self waitForExpectationsWithTimeout:20. handler:nil];
}

- (void)testDisableTrackingWhilePausedInSegment
{
    // Wait until the media plays. Expect segment labels
    [self expectationForComScoreHiddenEventNotificationWithHandler:^BOOL(NSString *event, NSDictionary *labels) {
        XCTAssertEqualObjects(labels[@"ns_st_ev"], @"play");
        XCTAssertEqualObjects(labels[@"stream_name"], @"full");
        XCTAssertEqualObjects(labels[@"segment_name"], @"segment");
        XCTAssertEqualObjects(labels[@"overridable_name"], @"segment");
        return YES;
    }];
    
    Segment *segment = [Segment segmentWithName:@"segment" timeRange:CMTimeRangeMake(CMTimeMakeWithSeconds(2., NSEC_PER_SEC), CMTimeMakeWithSeconds(3., NSEC_PER_SEC))];
    
    SRGAnalyticsPlayerLabels *labels = [[SRGAnalyticsPlayerLabels alloc] init];
    labels.comScoreCustomInfo = @{ @"stream_name" : @"full",
                                   @"overridable_name" : @"full" };
    
    [self.mediaPlayerController playURL:OnDemandTestURL()
                                atIndex:0
                             inSegments:@[segment]
                    withAnalyticsLabels:labels
                               userInfo:nil];
    
    [self waitForExpectationsWithTimeout:20. handler:nil];
    
    // Pause playback. Expect a pause with segment labels
    [self expectationForComScoreHiddenEventNotificationWithHandler:^BOOL(NSString *event, NSDictionary *labels) {
        XCTAssertEqualObjects(labels[@"ns_st_ev"], @"pause");
        XCTAssertEqualObjects(labels[@"stream_name"], @"full");
        XCTAssertEqualObjects(labels[@"segment_name"], @"segment");
        XCTAssertEqualObjects(labels[@"overridable_name"], @"segment");
        return YES;
    }];
    
    [self.mediaPlayerController pause];
    
    [self waitForExpectationsWithTimeout:20. handler:nil];
    
    // Stop tracking while paused. Expect an end to be received with segment labels
    [self expectationForComScoreHiddenEventNotificationWithHandler:^BOOL(NSString *event, NSDictionary *labels) {
        XCTAssertEqualObjects(labels[@"ns_st_ev"], @"end");
        XCTAssertEqualObjects(labels[@"stream_name"], @"full");
        XCTAssertEqualObjects(labels[@"segment_name"], @"segment");
        XCTAssertEqualObjects(labels[@"overridable_name"], @"segment");
        return YES;
    }];
    
    XCTAssertEqual(self.mediaPlayerController.playbackState, SRGMediaPlayerPlaybackStatePaused);
    self.mediaPlayerController.tracked = NO;
    
    [self waitForExpectationsWithTimeout:20. handler:nil];
}

- (void)testEnableTrackingWhilePreparing
{
    // Wait until the player is preparing to play
    [self expectationForNotification:SRGMediaPlayerPlaybackStateDidChangeNotification object:self.mediaPlayerController handler:^BOOL(NSNotification * _Nonnull notification) {
        XCTAssertEqual([notification.userInfo[SRGMediaPlayerPlaybackStateKey] integerValue], SRGMediaPlayerPlaybackStatePreparing);
        return YES;
    }];
    
    self.mediaPlayerController.tracked = NO;
    [self.mediaPlayerController playURL:OnDemandTestURL()];
    
    [self waitForExpectationsWithTimeout:20. handler:nil];
    
    // Enable tracking. Expect plays to be received
    [self expectationForComScoreHiddenEventNotificationWithHandler:^BOOL(NSString *event, NSDictionary *labels) {
        XCTAssertEqualObjects(event, @"play");
        return YES;
    }];
    
    XCTAssertEqual(self.mediaPlayerController.playbackState, SRGMediaPlayerPlaybackStatePreparing);
    self.mediaPlayerController.tracked = YES;
    
    [self waitForExpectationsWithTimeout:20. handler:nil];
}

- (void)testEnableTrackingWhilePreparingToPlaySegment
{
    // Wait until the player is preparing to play
    [self expectationForNotification:SRGMediaPlayerPlaybackStateDidChangeNotification object:self.mediaPlayerController handler:^BOOL(NSNotification * _Nonnull notification) {
        XCTAssertEqual([notification.userInfo[SRGMediaPlayerPlaybackStateKey] integerValue], SRGMediaPlayerPlaybackStatePreparing);
        return YES;
    }];
    
    self.mediaPlayerController.tracked = NO;
    Segment *segment = [Segment segmentWithName:@"segment" timeRange:CMTimeRangeMake(CMTimeMakeWithSeconds(2., NSEC_PER_SEC), CMTimeMakeWithSeconds(3., NSEC_PER_SEC))];
    
    SRGAnalyticsPlayerLabels *labels = [[SRGAnalyticsPlayerLabels alloc] init];
    labels.comScoreCustomInfo = @{ @"stream_name" : @"full",
                                   @"overridable_name" : @"full" };
    
    [self.mediaPlayerController playURL:OnDemandTestURL()
                                atIndex:0
                             inSegments:@[segment]
                    withAnalyticsLabels:labels
                               userInfo:nil];
    
    [self waitForExpectationsWithTimeout:20. handler:nil];
    
    // Enable tracking. Expect plays to be received
    [self expectationForComScoreHiddenEventNotificationWithHandler:^BOOL(NSString *event, NSDictionary *labels) {
        XCTAssertEqualObjects(labels[@"ns_st_ev"], @"play");
        XCTAssertEqualObjects(labels[@"stream_name"], @"full");
        XCTAssertEqualObjects(labels[@"segment_name"], @"segment");
        XCTAssertEqualObjects(labels[@"overridable_name"], @"segment");
        return YES;
    }];
    
    XCTAssertEqual(self.mediaPlayerController.playbackState, SRGMediaPlayerPlaybackStatePreparing);
    self.mediaPlayerController.tracked = YES;
    
    [self waitForExpectationsWithTimeout:20. handler:nil];
}

- (void)testEnableTrackingWhilePlaying
{
    // Wait until the player is playing. No event must be received since tracking is not enabled yet
    id eventObserver = [[NSNotificationCenter defaultCenter] addObserverForComScoreHiddenEventNotificationUsingBlock:^(NSString * _Nonnull event, NSDictionary * _Nonnull labels) {
        XCTFail(@"No event must be received when tracking has been disabled");
    }];
    
    [self expectationForNotification:SRGMediaPlayerPlaybackStateDidChangeNotification object:self.mediaPlayerController handler:^BOOL(NSNotification * _Nonnull notification) {
        return [notification.userInfo[SRGMediaPlayerPlaybackStateKey] integerValue] == SRGMediaPlayerPlaybackStatePlaying;
    }];
    
    self.mediaPlayerController.tracked = NO;
    [self.mediaPlayerController playURL:OnDemandTestURL()];
    
    [self waitForExpectationsWithTimeout:20. handler:^(NSError * _Nullable error) {
        [[NSNotificationCenter defaultCenter] removeObserver:eventObserver];
    }];
    
    // Enable tracking. Expect a play to be received
    [self expectationForComScoreHiddenEventNotificationWithHandler:^BOOL(NSString *event, NSDictionary *labels) {
        XCTAssertEqualObjects(labels[@"ns_st_ev"], @"play");
        return YES;
    }];
    
    XCTAssertEqual(self.mediaPlayerController.playbackState, SRGMediaPlayerPlaybackStatePlaying);
    self.mediaPlayerController.tracked = YES;
    
    [self waitForExpectationsWithTimeout:20. handler:nil];
}

- (void)testEnableTrackingWhilePlayingSegment
{
    // Wait until the player is playing. No event must be received since tracking is not enabled yet
    id eventObserver = [[NSNotificationCenter defaultCenter] addObserverForComScoreHiddenEventNotificationUsingBlock:^(NSString * _Nonnull event, NSDictionary * _Nonnull labels) {
        XCTFail(@"No event must be received when tracking has been disabled");
    }];
    
    [self expectationForNotification:SRGMediaPlayerPlaybackStateDidChangeNotification object:self.mediaPlayerController handler:^BOOL(NSNotification * _Nonnull notification) {
        return [notification.userInfo[SRGMediaPlayerPlaybackStateKey] integerValue] == SRGMediaPlayerPlaybackStatePlaying;
    }];
    
    self.mediaPlayerController.tracked = NO;
    Segment *segment = [Segment segmentWithName:@"segment" timeRange:CMTimeRangeMake(CMTimeMakeWithSeconds(2., NSEC_PER_SEC), CMTimeMakeWithSeconds(3., NSEC_PER_SEC))];
    
    SRGAnalyticsPlayerLabels *labels = [[SRGAnalyticsPlayerLabels alloc] init];
    labels.comScoreCustomInfo = @{ @"stream_name" : @"full",
                                   @"overridable_name" : @"full" };
    
    [self.mediaPlayerController playURL:OnDemandTestURL()
                                atIndex:0
                             inSegments:@[segment]
                    withAnalyticsLabels:labels
                               userInfo:nil];
    
    [self waitForExpectationsWithTimeout:20. handler:^(NSError * _Nullable error) {
        [[NSNotificationCenter defaultCenter] removeObserver:eventObserver];
    }];
    
    // Enable tracking. Expect a play to be received, with segment labels
    [self expectationForComScoreHiddenEventNotificationWithHandler:^BOOL(NSString *event, NSDictionary *labels) {
        XCTAssertEqualObjects(labels[@"ns_st_ev"], @"play");
        XCTAssertEqualObjects(labels[@"stream_name"], @"full");
        XCTAssertEqualObjects(labels[@"segment_name"], @"segment");
        XCTAssertEqualObjects(labels[@"overridable_name"], @"segment");
        return YES;
    }];
    
    XCTAssertEqual(self.mediaPlayerController.playbackState, SRGMediaPlayerPlaybackStatePlaying);
    self.mediaPlayerController.tracked = YES;
    
    [self waitForExpectationsWithTimeout:20. handler:nil];
}

- (void)testEnableTrackingWhilePaused
{
    // Wait until the player is playing. No event must be received since tracking is not enabled yet
    id eventObserver = [[NSNotificationCenter defaultCenter] addObserverForComScoreHiddenEventNotificationUsingBlock:^(NSString * _Nonnull event, NSDictionary * _Nonnull labels) {
        XCTFail(@"No event must be received when tracking has been disabled");
    }];
    
    [self expectationForNotification:SRGMediaPlayerPlaybackStateDidChangeNotification object:self.mediaPlayerController handler:^BOOL(NSNotification * _Nonnull notification) {
        return [notification.userInfo[SRGMediaPlayerPlaybackStateKey] integerValue] == SRGMediaPlayerPlaybackStatePlaying;
    }];
    
    self.mediaPlayerController.tracked = NO;
    [self.mediaPlayerController playURL:OnDemandTestURL()];
    
    [self waitForExpectationsWithTimeout:20. handler:^(NSError * _Nullable error) {
        [[NSNotificationCenter defaultCenter] removeObserver:eventObserver];
    }];
    
    // Pause playback
    [self expectationForNotification:SRGMediaPlayerPlaybackStateDidChangeNotification object:self.mediaPlayerController handler:^BOOL(NSNotification * _Nonnull notification) {
        XCTAssertEqual([notification.userInfo[SRGMediaPlayerPlaybackStateKey] integerValue], SRGMediaPlayerPlaybackStatePaused);
        return YES;
    }];
    
    [self.mediaPlayerController pause];
    
    [self waitForExpectationsWithTimeout:20. handler:nil];
    
    // Wait a little bit in the paused state (to avoid the result of the pause notification immediately trapped below)
    [self expectationForElapsedTimeInterval:3. withHandler:nil];
    [self waitForExpectationsWithTimeout:20. handler:nil];
    
    // Enable tracking. Expect a play (because the tracker starts), then a pause (reflecting the current state of the player) to be received
    __block BOOL playReceived = NO;
    __block BOOL pauseReceived = NO;
    
    [self expectationForComScoreHiddenEventNotificationWithHandler:^BOOL(NSString *event, NSDictionary *labels) {
        if ([event isEqualToString:@"play"]) {
            XCTAssertFalse(playReceived);
            XCTAssertFalse(pauseReceived);
            playReceived = YES;
        }
        else if ([event isEqualToString:@"pause"]) {
            XCTAssertFalse(pauseReceived);
            pauseReceived = YES;
        }
        else {
            XCTFail(@"Unexpected event received");
        }
        
        return playReceived && pauseReceived;
    }];
    
    XCTAssertEqual(self.mediaPlayerController.playbackState, SRGMediaPlayerPlaybackStatePaused);
    self.mediaPlayerController.tracked = YES;
    
    [self waitForExpectationsWithTimeout:20. handler:nil];
}

- (void)testDisableTwiceTrackingWhilePlaying
{
    // Wait until the media plays
    [self expectationForComScoreHiddenEventNotificationWithHandler:^BOOL(NSString *event, NSDictionary *labels) {
        XCTAssertEqualObjects(event, @"play");
        return YES;
    }];
    
    [self.mediaPlayerController playURL:OnDemandTestURL()];
    
    [self waitForExpectationsWithTimeout:20. handler:nil];
    
    // Stop tracking twice while playing. Expect a single end to be received
    __block NSInteger endEventCount = 0;
    id endEventObserver = [[NSNotificationCenter defaultCenter] addObserverForComScoreHiddenEventNotificationUsingBlock:^(NSString * _Nonnull event, NSDictionary * _Nonnull labels) {
        if ([event isEqualToString:@"end"]) {
            ++endEventCount;
        }
        else {
            XCTFail(@"Unexpected event received");
        }
    }];
    
    XCTAssertEqual(self.mediaPlayerController.playbackState, SRGMediaPlayerPlaybackStatePlaying);
    self.mediaPlayerController.tracked = NO;
    self.mediaPlayerController.tracked = NO;
    
    // Wait a little bit to collect potential events
    [self expectationForElapsedTimeInterval:5. withHandler:nil];
    [self waitForExpectationsWithTimeout:20. handler:^(NSError * _Nullable error) {
        [[NSNotificationCenter defaultCenter] removeObserver:endEventObserver];
    }];
    
    // Check we have received the end notification only once
    XCTAssertEqual(endEventCount, 1);
}

- (void)testEnableTrackingTwiceWhilePlaying
{
    // Wait until the media plays
    [self expectationForNotification:SRGMediaPlayerPlaybackStateDidChangeNotification object:self.mediaPlayerController handler:^BOOL(NSNotification * _Nonnull notification) {
        return [notification.userInfo[SRGMediaPlayerPlaybackStateKey] integerValue] == SRGMediaPlayerPlaybackStatePlaying;
    }];
    
    self.mediaPlayerController.tracked = NO;
    [self.mediaPlayerController playURL:OnDemandTestURL()];
    
    [self waitForExpectationsWithTimeout:20. handler:nil];
    
    // Start tracking twice while playing. Expect a single play to be received
    __block NSInteger playEventCount = 0;
    id endEventObserver = [[NSNotificationCenter defaultCenter] addObserverForComScoreHiddenEventNotificationUsingBlock:^(NSString * _Nonnull event, NSDictionary * _Nonnull labels) {
        if ([event isEqualToString:@"play"]) {
            ++playEventCount;
        }
        else {
            XCTFail(@"Unexpected event received");
        }
    }];
    
    XCTAssertEqual(self.mediaPlayerController.playbackState, SRGMediaPlayerPlaybackStatePlaying);
    self.mediaPlayerController.tracked = YES;
    self.mediaPlayerController.tracked = YES;
    
    // Wait a little bit to collect potential events
    [self expectationForElapsedTimeInterval:5. withHandler:nil];
    [self waitForExpectationsWithTimeout:20. handler:^(NSError * _Nullable error) {
        [[NSNotificationCenter defaultCenter] removeObserver:endEventObserver];
    }];
    
    // Check we have received the end notification only once
    XCTAssertEqual(playEventCount, 1);
}

@end
