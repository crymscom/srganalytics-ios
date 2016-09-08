//
//  Copyright (c) SRG SSR. All rights reserved.
//
//  License information is available from the LICENSE file.
//

#import "AnalyticsTestCase.h"
#import "NSNotificationCenter+Tests.h"

#import <SRGAnalytics_MediaPlayer/SRGAnalytics_MediaPlayer.h>

static NSURL *OnDemandTestURL(void)
{
    return [NSURL URLWithString:@"https://devimages.apple.com.edgekey.net/streaming/examples/bipbop_16x9/bipbop_16x9_variant.m3u8"];
}

static NSURL *LiveTestURL(void)
{
    return [NSURL URLWithString:@"http://esioslive6-i.akamaihd.net/hls/live/202892/AL_P_ESP1_FR_FRA/playlist.m3u8"];
}

static NSURL *DVRTestURL(void)
{
    return [NSURL URLWithString:@"http://vevoplaylist-live.hls.adaptive.level3.net/vevo/ch1/appleman.m3u8"];
}

@interface MediaPlayerTestCase : AnalyticsTestCase

@property (nonatomic) SRGMediaPlayerController *mediaPlayerController;

@end

@implementation MediaPlayerTestCase

#pragma mark Setup and teardown

+ (void)setUp
{
    // Setup analytics for all tests
    SRGAnalyticsTracker *analyticsTracker = [SRGAnalyticsTracker sharedTracker];
    [analyticsTracker startTrackingForBusinessUnit:SSRBusinessUnitRTS withComScoreVirtualSite:@"rts-app-test-v" netMetrixIdentifier:@"test" debugMode:NO];
}

// Since the comScore request notifications we observe are emitted at the comScore level (i.e. we have lost the identity
// of the player for which the request has been sent), we must properly ensure that notifications do not fall from one
// test onto another one when several tests are run. To avoid such issues, we always properly reset the media player
// at the end of each test (if it wasn't already)
//
// Remark: We currently use a single media player reference in our tests. If this somehow changes, be sure to reset other
// players here as well!

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
    id prepareObserver = [[NSNotificationCenter defaultCenter] addObserverForHiddenEventNotificationUsingBlock:^(NSString * _Nonnull event, NSDictionary * _Nonnull labels) {
        XCTFail(@"No event must be received when preparing a player");
    }];
    
    [self.mediaPlayerController prepareToPlayURL:OnDemandTestURL() withCompletionHandler:^{
        [[NSNotificationCenter defaultCenter] removeObserver:prepareObserver];
    }];
    
    // Now playing must trigger a play event
    [self expectationForHiddenEventNotificationWithHandler:^BOOL(NSString *event, NSDictionary *labels) {
        XCTAssertEqualObjects(labels[@"ns_st_ev"], @"play");
        return YES;
    }];
    
    [self.mediaPlayerController play];
    
    [self waitForExpectationsWithTimeout:20. handler:nil];
    
    [self expectationForHiddenEventNotificationWithHandler:^BOOL(NSString *event, NSDictionary *labels) {
        XCTAssertEqualObjects(labels[@"ns_st_ev"], @"end");
        return YES;
    }];
    
    [self.mediaPlayerController reset];
    
    [self waitForExpectationsWithTimeout:20. handler:nil];
}

- (void)testPlayStop
{
    [self expectationForHiddenEventNotificationWithHandler:^BOOL(NSString *event, NSDictionary *labels) {
        XCTAssertEqualObjects(labels[@"ns_st_ev"], @"play");
        return YES;
    }];
    
    [self.mediaPlayerController playURL:OnDemandTestURL()];
    
    [self waitForExpectationsWithTimeout:20. handler:nil];
    
    [self expectationForHiddenEventNotificationWithHandler:^BOOL(NSString *event, NSDictionary *labels) {
        XCTAssertEqualObjects(labels[@"ns_st_ev"], @"end");
        return YES;
    }];
    
    [self.mediaPlayerController stop];
    
    [self waitForExpectationsWithTimeout:20. handler:nil];
}

- (void)testPlayReset
{
    [self expectationForHiddenEventNotificationWithHandler:^BOOL(NSString *event, NSDictionary *labels) {
        XCTAssertEqualObjects(labels[@"ns_st_ev"], @"play");
        return YES;
    }];
    
    [self.mediaPlayerController playURL:OnDemandTestURL()];
    
    [self waitForExpectationsWithTimeout:20. handler:nil];
    
    [self expectationForHiddenEventNotificationWithHandler:^BOOL(NSString *event, NSDictionary *labels) {
        XCTAssertEqualObjects(labels[@"ns_st_ev"], @"end");
        return YES;
    }];
    
    [self.mediaPlayerController reset];
    
    [self waitForExpectationsWithTimeout:20. handler:nil];
}

- (void)testConsecutiveMedia
{
    [self expectationForHiddenEventNotificationWithHandler:^BOOL(NSString *event, NSDictionary *labels) {
        XCTAssertEqualObjects(labels[@"ns_st_ev"], @"play");
        return YES;
    }];
    
    [self.mediaPlayerController playURL:OnDemandTestURL()];
    
    [self waitForExpectationsWithTimeout:20. handler:nil];
    
    [self expectationForHiddenEventNotificationWithHandler:^BOOL(NSString *event, NSDictionary *labels) {
        XCTAssertEqualObjects(labels[@"ns_st_ev"], @"end");
        return YES;
    }];
    
    [self.mediaPlayerController playURL:LiveTestURL()];
    
    [self waitForExpectationsWithTimeout:20. handler:nil];
    
    [self expectationForHiddenEventNotificationWithHandler:^BOOL(NSString *event, NSDictionary *labels) {
        XCTAssertEqualObjects(labels[@"ns_st_ev"], @"play");
        return YES;
    }];
    
    [self waitForExpectationsWithTimeout:20. handler:nil];
    
    [self expectationForHiddenEventNotificationWithHandler:^BOOL(NSString *event, NSDictionary *labels) {
        XCTAssertEqualObjects(labels[@"ns_st_ev"], @"end");
        return YES;
    }];
    
    [self.mediaPlayerController reset];
    
    [self waitForExpectationsWithTimeout:20. handler:nil];
}

- (void)testOnDemandLabels
{
    // Check that these labels are constant between states (for some, the value might differ, but they must
    // in which case we test they are constantly availble or unavailable)
    void (^checkLabels)(NSDictionary *) = ^(NSDictionary *labels) {
        XCTAssertNotNil(labels[@"ns_st_br"]);
        XCTAssertEqualObjects(labels[@"ns_st_ws"], @"norm");
        XCTAssertNotNil(labels[@"ns_st_vo"]);
        XCTAssertNil(labels[@"ns_ap_ot"]);
        
        XCTAssertEqualObjects(labels[@"ns_st_cs"], @"0x0");
        XCTAssertNil(labels[@"srg_timeshift"]);
        XCTAssertEqualObjects(labels[@"srg_screen_type"], @"default");
    };
    
    [self expectationForHiddenEventNotificationWithHandler:^BOOL(NSString *event, NSDictionary *labels) {
        XCTAssertEqualObjects(labels[@"ns_st_ev"], @"play");
        checkLabels(labels);
        return YES;
    }];
    
    [self.mediaPlayerController playURL:OnDemandTestURL()];
    
    [self waitForExpectationsWithTimeout:20. handler:nil];
    
    [self expectationForHiddenEventNotificationWithHandler:^BOOL(NSString *event, NSDictionary *labels) {
        XCTAssertEqualObjects(labels[@"ns_st_ev"], @"pause");
        checkLabels(labels);
        return YES;
    }];
    
    [self.mediaPlayerController pause];
    
    [self waitForExpectationsWithTimeout:20. handler:nil];
    
    [self expectationForHiddenEventNotificationWithHandler:^BOOL(NSString *event, NSDictionary *labels) {
        XCTAssertEqualObjects(labels[@"ns_st_ev"], @"end");
        checkLabels(labels);
        return YES;
    }];
    
    [self.mediaPlayerController reset];
    
    [self waitForExpectationsWithTimeout:20. handler:nil];
}

- (void)testLiveLabels
{
    // Check that these labels are constant between states (for some, the value might differ, but they must
    // in which case we test they are constantly availble or unavailable)
    void (^checkLabels)(NSDictionary *) = ^(NSDictionary *labels) {
        XCTAssertNotNil(labels[@"ns_st_br"]);
        XCTAssertEqualObjects(labels[@"ns_st_ws"], @"norm");
        XCTAssertNotNil(labels[@"ns_st_vo"]);
        XCTAssertNil(labels[@"ns_ap_ot"]);
        
        XCTAssertEqualObjects(labels[@"ns_st_cs"], @"0x0");
        XCTAssertEqualObjects(labels[@"srg_timeshift"], @"0");
        XCTAssertEqualObjects(labels[@"srg_screen_type"], @"default");
    };
    
    [self expectationForHiddenEventNotificationWithHandler:^BOOL(NSString *event, NSDictionary *labels) {
        XCTAssertEqualObjects(labels[@"ns_st_ev"], @"play");
        checkLabels(labels);
        return YES;
    }];
    
    [self.mediaPlayerController playURL:LiveTestURL()];
    
    [self waitForExpectationsWithTimeout:20. handler:nil];
    
    [self expectationForHiddenEventNotificationWithHandler:^BOOL(NSString *event, NSDictionary *labels) {
        XCTAssertEqualObjects(labels[@"ns_st_ev"], @"pause");
        checkLabels(labels);
        return YES;
    }];
    
    [self.mediaPlayerController pause];
    
    [self waitForExpectationsWithTimeout:20. handler:nil];
    
    [self expectationForHiddenEventNotificationWithHandler:^BOOL(NSString *event, NSDictionary *labels) {
        XCTAssertEqualObjects(labels[@"ns_st_ev"], @"end");
        checkLabels(labels);
        return YES;
    }];
    
    [self.mediaPlayerController reset];
    
    [self waitForExpectationsWithTimeout:20. handler:nil];
}

- (void)testDVRLabels
{
    // Check that these labels are constant between states (for some, the value might differ, but they must
    // in which case we test they are constantly availble or unavailable)
    void (^checkLabels)(NSDictionary *) = ^(NSDictionary *labels) {
        XCTAssertNotNil(labels[@"ns_st_br"]);
        XCTAssertEqualObjects(labels[@"ns_st_ws"], @"norm");
        XCTAssertNotNil(labels[@"ns_st_vo"]);
        XCTAssertNil(labels[@"ns_ap_ot"]);
        
        XCTAssertEqualObjects(labels[@"ns_st_cs"], @"0x0");
        XCTAssertEqualObjects(labels[@"srg_screen_type"], @"default");
    };
    
    [self expectationForHiddenEventNotificationWithHandler:^BOOL(NSString *event, NSDictionary *labels) {
        XCTAssertEqualObjects(labels[@"ns_st_ev"], @"play");
        checkLabels(labels);
        return YES;
    }];
    
    [self.mediaPlayerController playURL:DVRTestURL()];
    
    [self waitForExpectationsWithTimeout:20. handler:nil];
    
    [self expectationForHiddenEventNotificationWithHandler:^BOOL(NSString *event, NSDictionary *labels) {
        XCTAssertEqualObjects(labels[@"ns_st_ev"], @"pause");
        checkLabels(labels);
        XCTAssertEqualObjects(labels[@"srg_timeshift"], @"0");
        return YES;
    }];
    
    // Live tolerance has been set to 10 for tests, duration of the DVR window for the test stream is about 45 seconds
    CMTime pastTime = CMTimeSubtract(CMTimeRangeGetEnd(self.mediaPlayerController.timeRange), CMTimeMakeWithSeconds(20., NSEC_PER_SEC));
    [self.mediaPlayerController seekPreciselyToTime:pastTime withCompletionHandler:nil];
    
    [self waitForExpectationsWithTimeout:20. handler:nil];
    
    [self expectationForHiddenEventNotificationWithHandler:^BOOL(NSString *event, NSDictionary *labels) {
        XCTAssertEqualObjects(labels[@"ns_st_ev"], @"play");
        checkLabels(labels);
        XCTAssertNotEqualObjects(labels[@"srg_timeshift"], @"0");
        return YES;
    }];
    [self waitForExpectationsWithTimeout:20. handler:nil];
    
    [self expectationForHiddenEventNotificationWithHandler:^BOOL(NSString *event, NSDictionary *labels) {
        XCTAssertEqualObjects(labels[@"ns_st_ev"], @"end");
        XCTAssertNotEqualObjects(labels[@"srg_timeshift"], @"0");
        checkLabels(labels);
        return YES;
    }];
    
    [self.mediaPlayerController reset];
    
    [self waitForExpectationsWithTimeout:20. handler:nil];
}

- (void)testVolumeLabel
{

}

@end
