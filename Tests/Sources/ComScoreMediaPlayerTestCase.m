//
//  Copyright (c) SRG SSR. All rights reserved.
//
//  License information is available from the LICENSE file.
//

#import "NSNotificationCenter+Tests.h"
#import "Segment.h"
#import "XCTestCase+Tests.h"

#import <SRGAnalytics_MediaPlayer/SRGAnalytics_MediaPlayer.h>
#import <ComScore/ComScore.h>

typedef BOOL (^EventExpectationHandler)(NSString *event, NSDictionary *labels);

static NSURL *OnDemandTestURL(void)
{
    return [NSURL URLWithString:@"http://devimages.apple.com.edgekey.net/streaming/examples/bipbop_16x9/bipbop_16x9_variant.m3u8"];
}

static NSURL *LiveTestURL(void)
{
    return [NSURL URLWithString:@"http://tagesschau-lh.akamaihd.net/i/tagesschau_1@119231/master.m3u8?dw=0"];
}

static NSURL *DVRTestURL(void)
{
    return [NSURL URLWithString:@"http://tagesschau-lh.akamaihd.net/i/tagesschau_1@119231/master.m3u8"];
}

@interface ComScoreMediaPlayerTestCase : XCTestCase

@property (nonatomic) SRGMediaPlayerController *mediaPlayerController;

@end

@implementation ComScoreMediaPlayerTestCase

#pragma mark Setup and teardown

+ (void)setUp
{
    // The comScore SDK caches events recorded during the initial ~5 seconds after it has been initialized. Then events
    // are sent as they are recorded. For this reason, to get reliable timings, we just wait ~5 seconds at the beginning
    // of the test suite.
    [NSThread sleepForTimeInterval:6.];
}

- (void)setUp
{
    self.mediaPlayerController = [[SRGMediaPlayerController alloc] init];
    self.mediaPlayerController.liveTolerance = 10.;
}

- (void)tearDown
{
    // Ensure each test ends in an expected state. Since we have no control over when the comScore singleton
    // processes events, we must ensure that the player is properly reset before moving to the next test, and
    // that the associated event has been received.
    if (self.mediaPlayerController.tracked && self.mediaPlayerController.playbackState != SRGMediaPlayerPlaybackStateIdle
            && self.mediaPlayerController.playbackState != SRGMediaPlayerPlaybackStateEnded) {
        [self expectationForComScorePlayerEventNotificationWithHandler:^BOOL(NSString * _Nonnull event, NSDictionary * _Nonnull labels) {
            return [event isEqualToString:@"end"];
        }];
        
        [self.mediaPlayerController reset];
        
        [self waitForExpectationsWithTimeout:20. handler:nil];
    }
    self.mediaPlayerController = nil;
}

#pragma mark Tests

- (void)testPrepareToPlay
{
    // If the player starts in a paused state, no event needs to be emitted (there is no measurable media consumption
    // after all)
    id prepareObserver = [NSNotificationCenter.defaultCenter addObserverForComScorePlayerEventNotificationUsingBlock:^(NSString * _Nonnull event, NSDictionary * _Nonnull labels) {
        XCTFail(@"No event must be received when preparing a player");
    }];
    
    [self expectationForElapsedTimeInterval:3. withHandler:nil];
    
    [self.mediaPlayerController prepareToPlayURL:OnDemandTestURL() withCompletionHandler:nil];
    
    [self waitForExpectationsWithTimeout:20. handler:^(NSError * _Nullable error) {
        [NSNotificationCenter.defaultCenter removeObserver:prepareObserver];
    }];
    
    [self expectationForComScorePlayerEventNotificationWithHandler:^BOOL(NSString *event, NSDictionary *labels) {
        XCTAssertEqualObjects(labels[@"ns_st_ev"], @"play");
        return YES;
    }];
    
    [self.mediaPlayerController play];
    
    [self waitForExpectationsWithTimeout:20. handler:nil];
    
    [self expectationForComScorePlayerEventNotificationWithHandler:^BOOL(NSString *event, NSDictionary *labels) {
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
    
    [self expectationForComScorePlayerEventNotificationWithHandler:^BOOL(NSString *event, NSDictionary *labels) {
        XCTAssertEqualObjects(labels[@"ns_st_ev"], @"play");
        
        // comScore internal duration labels
        XCTAssertEqualObjects(labels[@"ns_st_pa"], @"0");
        XCTAssertEqualObjects(labels[@"ns_st_pt"], @"0");
        return YES;
    }];
    
    [self.mediaPlayerController playURL:OnDemandTestURL()];
    
    [self waitForExpectationsWithTimeout:20. handler:nil];
    
    [self expectationForComScorePlayerEventNotificationWithHandler:^BOOL(NSString *event, NSDictionary *labels) {
        XCTAssertEqualObjects(labels[@"ns_st_ev"], @"pause");
        
        // comScore internal duration labels
        XCTAssertNotNil(labels[@"ns_st_pa"]);
        XCTAssertNotEqualObjects(labels[@"ns_st_pa"], @"0");
        XCTAssertNotEqualObjects(labels[@"ns_st_pt"], @"0");
        return YES;
    }];
    
    // Seek near the end of the video
    CMTime pastTime = CMTimeSubtract(CMTimeRangeGetEnd(self.mediaPlayerController.timeRange), CMTimeMakeWithSeconds(5., NSEC_PER_SEC));
    [self.mediaPlayerController seekToPosition:[SRGPosition positionAtTime:pastTime] withCompletionHandler:nil];
    
    [self waitForExpectationsWithTimeout:20. handler:nil];
    
    [self expectationForComScorePlayerEventNotificationWithHandler:^BOOL(NSString *event, NSDictionary *labels) {
        XCTAssertEqualObjects(labels[@"ns_st_ev"], @"play");
        
        // comScore internal duration labels
        XCTAssertNotEqualObjects(labels[@"ns_st_pa"], @"0");
        XCTAssertNotEqualObjects(labels[@"ns_st_pt"], @"0");
        return YES;
    }];
    
    [self waitForExpectationsWithTimeout:20. handler:nil];
    
    // Let playback finish normally
    
    [self expectationForComScorePlayerEventNotificationWithHandler:^BOOL(NSString *event, NSDictionary *labels) {
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
    [self expectationForComScorePlayerEventNotificationWithHandler:^BOOL(NSString *event, NSDictionary *labels) {
        XCTAssertEqualObjects(labels[@"ns_st_ev"], @"play");
        return YES;
    }];
    
    [self.mediaPlayerController playURL:OnDemandTestURL()];
    
    [self waitForExpectationsWithTimeout:20. handler:nil];
    
    [self expectationForComScorePlayerEventNotificationWithHandler:^BOOL(NSString *event, NSDictionary *labels) {
        XCTAssertEqualObjects(labels[@"ns_st_ev"], @"end");
        return YES;
    }];
    
    [self.mediaPlayerController stop];
    
    [self waitForExpectationsWithTimeout:20. handler:nil];
}

- (void)testPlayReset
{
    [self expectationForComScorePlayerEventNotificationWithHandler:^BOOL(NSString *event, NSDictionary *labels) {
        XCTAssertEqualObjects(labels[@"ns_st_ev"], @"play");
        return YES;
    }];
    
    [self.mediaPlayerController playURL:OnDemandTestURL()];
    
    [self waitForExpectationsWithTimeout:20. handler:nil];
    
    [self expectationForComScorePlayerEventNotificationWithHandler:^BOOL(NSString *event, NSDictionary *labels) {
        XCTAssertEqualObjects(labels[@"ns_st_ev"], @"end");
        return YES;
    }];
    
    [self.mediaPlayerController reset];
    
    [self waitForExpectationsWithTimeout:20. handler:nil];
}

- (void)testPlayPausePlay
{
    [self expectationForComScorePlayerEventNotificationWithHandler:^BOOL(NSString *event, NSDictionary *labels) {
        return [event isEqualToString:@"play"];
    }];
    
    [self.mediaPlayerController playURL:OnDemandTestURL()];
    
    [self waitForExpectationsWithTimeout:20. handler:nil];
    
    [self expectationForComScorePlayerEventNotificationWithHandler:^BOOL(NSString *event, NSDictionary *labels) {
        return [event isEqualToString:@"pause"];
    }];
    
    [self.mediaPlayerController pause];
    
    [self waitForExpectationsWithTimeout:20. handler:nil];
    
    [self expectationForComScorePlayerEventNotificationWithHandler:^BOOL(NSString *event, NSDictionary *labels) {
        return [event isEqualToString:@"play"];
    }];
    
    [self.mediaPlayerController play];
    
    [self waitForExpectationsWithTimeout:20. handler:nil];
    
    [self expectationForElapsedTimeInterval:3. withHandler:nil];
    
    id eventObserver4 = [NSNotificationCenter.defaultCenter addObserverForComScorePlayerEventNotificationUsingBlock:^(NSString * _Nonnull event, NSDictionary * _Nonnull labels) {
        // Also see http://stackoverflow.com/questions/14565405/avplayer-pauses-for-no-obvious-reason and
        // the demo project https://github.com/defagos/radars/tree/master/unexpected-player-rate-changes
        NSLog(@"[AVPlayer probable bug]: Unexpected state change to %@. Fast play - pause sequences can induce unexpected rate changes "
              "captured via KVO in our implementation. Those changes do not harm but cannot be tested reliably", @(self.mediaPlayerController.playbackState));
    }];
    
    [self waitForExpectationsWithTimeout:20. handler:^(NSError * _Nullable error) {
        [NSNotificationCenter.defaultCenter removeObserver:eventObserver4];
    }];
}

- (void)testConsecutiveMedia
{
    [self expectationForComScorePlayerEventNotificationWithHandler:^BOOL(NSString *event, NSDictionary *labels) {
        XCTAssertEqualObjects(labels[@"ns_st_ev"], @"play");
        return YES;
    }];
    
    [self.mediaPlayerController playURL:OnDemandTestURL()];
    
    [self waitForExpectationsWithTimeout:20. handler:nil];
    
    [self expectationForComScorePlayerEventNotificationWithHandler:^BOOL(NSString *event, NSDictionary *labels) {
        XCTAssertEqualObjects(labels[@"ns_st_ev"], @"end");
        return YES;
    }];
    
    [self.mediaPlayerController playURL:LiveTestURL()];
    
    [self waitForExpectationsWithTimeout:20. handler:nil];
    
    [self expectationForComScorePlayerEventNotificationWithHandler:^BOOL(NSString *event, NSDictionary *labels) {
        XCTAssertEqualObjects(labels[@"ns_st_ev"], @"play");
        return YES;
    }];
    
    [self waitForExpectationsWithTimeout:20. handler:nil];
    
    [self expectationForComScorePlayerEventNotificationWithHandler:^BOOL(NSString *event, NSDictionary *labels) {
        XCTAssertEqualObjects(labels[@"ns_st_ev"], @"end");
        return YES;
    }];
    
    [self.mediaPlayerController reset];
    
    [self waitForExpectationsWithTimeout:20. handler:nil];
}

- (void)testMediaError
{
    id eventObserver = [NSNotificationCenter.defaultCenter addObserverForComScorePlayerEventNotificationUsingBlock:^(NSString * _Nonnull event, NSDictionary * _Nonnull labels) {
        XCTFail(@"No event must be received");
    }];
    
    [self expectationForSingleNotification:SRGMediaPlayerPlaybackDidFailNotification object:self.mediaPlayerController handler:^BOOL (NSNotification *notification) {
        return YES;
    }];
    
    [self.mediaPlayerController playURL:[NSURL URLWithString:@"http://httpbin.org/status/403"]];
    
    [self waitForExpectationsWithTimeout:20. handler:^(NSError * _Nullable error) {
        [NSNotificationCenter.defaultCenter removeObserver:eventObserver];
    }];
}

- (void)testCommonLabels
{
    [self expectationForComScorePlayerEventNotificationWithHandler:^BOOL(NSString *event, NSDictionary *labels) {
        XCTAssertEqualObjects(labels[@"ns_st_ev"], @"play");
        
        XCTAssertEqualObjects(labels[@"ns_st_mp"], @"SRGMediaPlayer");
        XCTAssertEqualObjects(labels[@"ns_st_mv"], SRGMediaPlayerMarketingVersion());
        XCTAssertEqualObjects(labels[@"ns_st_it"], @"c");
        return YES;
    }];
    
    [self.mediaPlayerController playURL:OnDemandTestURL()];
    
    [self waitForExpectationsWithTimeout:20. handler:nil];
}

- (void)testOnDemandPlayback
{
    [self expectationForComScorePlayerEventNotificationWithHandler:^BOOL(NSString *event, NSDictionary *labels) {
        XCTAssertEqualObjects(labels[@"ns_st_ev"], @"play");
        XCTAssertEqual([labels[@"ns_st_po"] integerValue] / 1000, 0);
        return YES;
    }];
    
    [self.mediaPlayerController playURL:OnDemandTestURL()];
    
    [self waitForExpectationsWithTimeout:20. handler:nil];
    
    [self expectationForComScorePlayerEventNotificationWithHandler:^BOOL(NSString *event, NSDictionary *labels) {
        XCTAssertEqualObjects(labels[@"ns_st_ev"], @"pause");
        XCTAssertEqual([labels[@"ns_st_po"] integerValue] / 1000, 0);
        return YES;
    }];
    
    [self.mediaPlayerController pause];
    
    [self waitForExpectationsWithTimeout:20. handler:nil];
    
    [self expectationForComScorePlayerEventNotificationWithHandler:^BOOL(NSString *event, NSDictionary *labels) {
        XCTAssertEqualObjects(labels[@"ns_st_ev"], @"end");
        XCTAssertEqual([labels[@"ns_st_po"] integerValue] / 1000, 0);
        return YES;
    }];
    
    [self.mediaPlayerController reset];
    
    [self waitForExpectationsWithTimeout:20. handler:nil];
}

- (void)testLivePlayback
{
    // FIXME: See https://github.com/SRGSSR/SRGMediaPlayer-iOS/issues/50. Workaround so that the test passes on iOS >= 11.3.
    NSOperatingSystemVersion operatingSystemVersion = [NSProcessInfo processInfo].operatingSystemVersion;
    if (operatingSystemVersion.majorVersion == 11 && operatingSystemVersion.minorVersion >= 3) {
        self.mediaPlayerController.minimumDVRWindowLength = 40.;
    }
    
    [self expectationForComScorePlayerEventNotificationWithHandler:^BOOL(NSString *event, NSDictionary *labels) {
        XCTAssertEqualObjects(labels[@"ns_st_ev"], @"play");
        return YES;
    }];
    
    [self.mediaPlayerController playURL:LiveTestURL() atPosition:nil withSegments:nil analyticsLabels:nil userInfo:nil];
    
    [self waitForExpectationsWithTimeout:20. handler:nil];
    
    [self expectationForComScorePlayerEventNotificationWithHandler:^BOOL(NSString *event, NSDictionary *labels) {
        XCTAssertEqualObjects(labels[@"ns_st_ev"], @"pause");
        return YES;
    }];
    
    [self.mediaPlayerController pause];
    
    [self waitForExpectationsWithTimeout:20. handler:nil];
    
    [self expectationForComScorePlayerEventNotificationWithHandler:^BOOL(NSString *event, NSDictionary *labels) {
        XCTAssertEqualObjects(labels[@"ns_st_ev"], @"end");
        return YES;
    }];
    
    [self.mediaPlayerController reset];
    
    [self waitForExpectationsWithTimeout:20. handler:nil];
}

- (void)testDVRPlayback
{
    [self expectationForComScorePlayerEventNotificationWithHandler:^BOOL(NSString *event, NSDictionary *labels) {
        XCTAssertEqualObjects(labels[@"ns_st_ev"], @"play");
        XCTAssertEqualObjects(labels[@"ns_st_ldo"], @"0");
        return YES;
    }];
    
    [self.mediaPlayerController playURL:DVRTestURL()];
    
    [self waitForExpectationsWithTimeout:20. handler:nil];
    
    [self expectationForComScorePlayerEventNotificationWithHandler:^BOOL(NSString *event, NSDictionary *labels) {
        XCTAssertEqualObjects(labels[@"ns_st_ev"], @"pause");
        XCTAssertEqualObjects(labels[@"ns_st_ldo"], @"0");
        return YES;
    }];
    
    CMTime pastTime = CMTimeSubtract(CMTimeRangeGetEnd(self.mediaPlayerController.timeRange), CMTimeMakeWithSeconds(45., NSEC_PER_SEC));
    [self.mediaPlayerController seekToPosition:[SRGPosition positionAtTime:pastTime] withCompletionHandler:nil];
    
    [self waitForExpectationsWithTimeout:20. handler:nil];
    
    [self expectationForComScorePlayerEventNotificationWithHandler:^BOOL(NSString *event, NSDictionary *labels) {
        XCTAssertEqualObjects(labels[@"ns_st_ev"], @"play");
        XCTAssertEqualObjects(labels[@"ns_st_ldo"], @"45000");
        return YES;
    }];
    [self waitForExpectationsWithTimeout:20. handler:nil];
    
    [self expectationForComScorePlayerEventNotificationWithHandler:^BOOL(NSString *event, NSDictionary *labels) {
        XCTAssertEqualObjects(labels[@"ns_st_ev"], @"end");
        XCTAssertEqualObjects(labels[@"ns_st_ldo"], @"44000");             // Not 45000 because of chunks
        return YES;
    }];
    
    [self.mediaPlayerController reset];
    
    [self waitForExpectationsWithTimeout:20. handler:nil];
}

- (void)testLiveStopLive
{
    [self expectationForComScorePlayerEventNotificationWithHandler:^BOOL(NSString *event, NSDictionary *labels) {
        XCTAssertEqualObjects(labels[@"ns_st_ev"], @"play");
        XCTAssertEqualObjects(labels[@"ns_st_ldo"], @"0");
        return YES;
    }];
    
    [self.mediaPlayerController playURL:LiveTestURL() atPosition:nil withSegments:nil analyticsLabels:nil userInfo:nil];
    
    [self waitForExpectationsWithTimeout:20. handler:nil];
    
    // Play for a while. No stream events must be received
    id eventObserver = [NSNotificationCenter.defaultCenter addObserverForComScorePlayerEventNotificationUsingBlock:^(NSString * _Nonnull event, NSDictionary * _Nonnull labels) {
        XCTFail(@"No event must be received when playing");
    }];
    
    [self expectationForElapsedTimeInterval:1. withHandler:nil];
    [self waitForExpectationsWithTimeout:20. handler:^(NSError * _Nullable error) {
        [NSNotificationCenter.defaultCenter removeObserver:eventObserver];
    }];
    
    [self expectationForComScorePlayerEventNotificationWithHandler:^BOOL(NSString *event, NSDictionary *labels) {
        XCTAssertEqualObjects(labels[@"ns_st_ev"], @"end");
        XCTAssertEqualObjects(labels[@"ns_st_ldo"], @"0");
        return YES;
    }];
    
    [self.mediaPlayerController stop];
    
    [self waitForExpectationsWithTimeout:20. handler:nil];
    
    [self expectationForComScorePlayerEventNotificationWithHandler:^BOOL(NSString *event, NSDictionary *labels) {
        XCTAssertEqualObjects(labels[@"ns_st_ev"], @"play");
        XCTAssertEqualObjects(labels[@"ns_st_ldo"], @"0");
        return YES;
    }];
    
    [self.mediaPlayerController play];
    
    [self waitForExpectationsWithTimeout:20. handler:nil];
    
    // Pause for a while. No stream events must be received
    eventObserver = [NSNotificationCenter.defaultCenter addObserverForComScorePlayerEventNotificationUsingBlock:^(NSString * _Nonnull event, NSDictionary * _Nonnull labels) {
        XCTFail(@"No event must be received when paused");
    }];
    
    [self expectationForElapsedTimeInterval:1. withHandler:nil];
    [self waitForExpectationsWithTimeout:20. handler:^(NSError * _Nullable error) {
        [NSNotificationCenter.defaultCenter removeObserver:eventObserver];
    }];
    
    [self expectationForComScorePlayerEventNotificationWithHandler:^BOOL(NSString *event, NSDictionary *labels) {
        XCTAssertEqualObjects(labels[@"ns_st_ev"], @"end");
        XCTAssertEqualObjects(labels[@"ns_st_ldo"], @"0");
        return YES;
    }];
    
    [self.mediaPlayerController reset];
    
    [self waitForExpectationsWithTimeout:20. handler:nil];
}

- (void)testNonSelectedSegmentPlayback
{
    [self expectationForComScorePlayerEventNotificationWithHandler:^BOOL(NSString *event, NSDictionary *labels) {
        XCTAssertEqualObjects(labels[@"ns_st_ev"], @"play");
        XCTAssertEqualObjects(labels[@"stream_name"], @"full");
        XCTAssertNil(labels[@"segment_name"]);
        XCTAssertEqualObjects(labels[@"overridable_name"], @"full");
        return YES;
    }];
    
    SRGAnalyticsStreamLabels *labels = [[SRGAnalyticsStreamLabels alloc] init];
    labels.comScoreCustomInfo = @{ @"stream_name" : @"full",
                                   @"overridable_name" : @"full" };
    
    Segment *segment = [Segment segmentWithName:@"segment" timeRange:CMTimeRangeMake(CMTimeMakeWithSeconds(2., NSEC_PER_SEC), CMTimeMakeWithSeconds(3., NSEC_PER_SEC))];
    [self.mediaPlayerController playURL:OnDemandTestURL() atPosition:nil withSegments:@[segment] analyticsLabels:labels userInfo:nil];
    
    [self waitForExpectationsWithTimeout:20. handler:nil];
    
    // Let the segment be played through. No events must be received
    id eventObserver = [NSNotificationCenter.defaultCenter addObserverForComScorePlayerEventNotificationUsingBlock:^(NSString * _Nonnull event, NSDictionary * _Nonnull labels) {
        XCTFail(@"No event must be received");
    }];
    
    [self expectationForElapsedTimeInterval:3. withHandler:nil];
    
    [self waitForExpectationsWithTimeout:20. handler:^(NSError * _Nullable error) {
        [NSNotificationCenter.defaultCenter removeObserver:eventObserver];
    }];
    
    // Pause playback. Expect full-length information
    [self expectationForComScorePlayerEventNotificationWithHandler:^BOOL(NSString *event, NSDictionary *labels) {
        XCTAssertEqualObjects(labels[@"ns_st_ev"], @"pause");
        XCTAssertEqualObjects(labels[@"stream_name"], @"full");
        XCTAssertNil(labels[@"segment_name"]);
        XCTAssertEqualObjects(labels[@"overridable_name"], @"full");
        return YES;
    }];
    
    [self.mediaPlayerController pause];
    
    [self waitForExpectationsWithTimeout:20. handler:nil];
    
    // Resume playback. Expect full-length information
    [self expectationForComScorePlayerEventNotificationWithHandler:^BOOL(NSString *event, NSDictionary *labels) {
        XCTAssertEqualObjects(labels[@"ns_st_ev"], @"play");
        XCTAssertEqualObjects(labels[@"stream_name"], @"full");
        XCTAssertNil(labels[@"segment_name"]);
        XCTAssertEqualObjects(labels[@"overridable_name"], @"full");
        return YES;
    }];
    
    [self.mediaPlayerController play];
    
    [self waitForExpectationsWithTimeout:20. handler:nil];
    
    id eventObserver2 = [NSNotificationCenter.defaultCenter addObserverForComScorePlayerEventNotificationUsingBlock:^(NSString * _Nonnull event, NSDictionary * _Nonnull labels) {
        // Also see http://stackoverflow.com/questions/14565405/avplayer-pauses-for-no-obvious-reason and
        // the demo project https://github.com/defagos/radars/tree/master/unexpected-player-rate-changes
        NSLog(@"[AVPlayer probable bug]: Unexpected state change to %@. Fast play - pause sequences can induce unexpected rate changes "
              "captured via KVO in our implementation. Those changes do not harm but cannot be tested reliably", @(self.mediaPlayerController.playbackState));
    }];
    
    [self expectationForElapsedTimeInterval:3. withHandler:nil];
    
    [self waitForExpectationsWithTimeout:20. handler:^(NSError * _Nullable error) {
        [NSNotificationCenter.defaultCenter removeObserver:eventObserver2];
    }];
}

- (void)testSelectedSegmentPlayback
{
    [self expectationForComScorePlayerEventNotificationWithHandler:^BOOL(NSString *event, NSDictionary *labels) {
        XCTAssertEqualObjects(labels[@"ns_st_ev"], @"play");
        XCTAssertEqualObjects(labels[@"stream_name"], @"full");
        XCTAssertNil(labels[@"segment_name"], @"segment");
        XCTAssertEqualObjects(labels[@"overridable_name"], @"full");
        return YES;
    }];
    
    Segment *segment = [Segment segmentWithName:@"segment" timeRange:CMTimeRangeMake(CMTimeMakeWithSeconds(2., NSEC_PER_SEC), CMTimeMakeWithSeconds(10., NSEC_PER_SEC))];
    
    SRGAnalyticsStreamLabels *labels = [[SRGAnalyticsStreamLabels alloc] init];
    labels.comScoreCustomInfo = @{ @"stream_name" : @"full",
                                   @"overridable_name" : @"full" };
    
    [self.mediaPlayerController playURL:OnDemandTestURL() atIndex:0 position:nil inSegments:@[segment] withAnalyticsLabels:labels userInfo:nil];
    
    [self waitForExpectationsWithTimeout:20. handler:nil];
    
    [self expectationForComScorePlayerEventNotificationWithHandler:^BOOL(NSString *event, NSDictionary *labels) {
        XCTAssertEqualObjects(labels[@"ns_st_ev"], @"pause");
        XCTAssertEqualObjects(labels[@"stream_name"], @"full");
        XCTAssertNil(labels[@"segment_name"], @"segment");
        XCTAssertEqualObjects(labels[@"overridable_name"], @"full");
        return YES;
    }];
    
    [self.mediaPlayerController pause];
    
    [self waitForExpectationsWithTimeout:20. handler:nil];
    
    // Resume playback. Expect segment information
    [self expectationForComScorePlayerEventNotificationWithHandler:^BOOL(NSString *event, NSDictionary *labels) {
        XCTAssertEqualObjects(labels[@"ns_st_ev"], @"play");
        XCTAssertEqualObjects(labels[@"stream_name"], @"full");
        XCTAssertNil(labels[@"segment_name"], @"segment");
        XCTAssertEqualObjects(labels[@"overridable_name"], @"full");
        return YES;
    }];
    
    [self.mediaPlayerController play];
    
    [self waitForExpectationsWithTimeout:20. handler:nil];
}

- (void)testInitialSegmentSelectionAndPlaythrough
{
    [self expectationForComScorePlayerEventNotificationWithHandler:^BOOL(NSString *event, NSDictionary *labels) {
        XCTAssertEqualObjects(labels[@"ns_st_ev"], @"play");
        XCTAssertEqualObjects(labels[@"stream_name"], @"full");
        XCTAssertNil(labels[@"segment_name"], @"segment");
        XCTAssertEqualObjects(labels[@"overridable_name"], @"full");
        return YES;
    }];
    
    Segment *segment = [Segment segmentWithName:@"segment" timeRange:CMTimeRangeMake(CMTimeMakeWithSeconds(50., NSEC_PER_SEC), CMTimeMakeWithSeconds(3., NSEC_PER_SEC))];
    
    SRGAnalyticsStreamLabels *labels = [[SRGAnalyticsStreamLabels alloc] init];
    labels.comScoreCustomInfo = @{ @"stream_name" : @"full",
                                   @"overridable_name" : @"full" };
    
    [self.mediaPlayerController playURL:OnDemandTestURL() atIndex:0 position:nil inSegments:@[segment] withAnalyticsLabels:labels userInfo:nil];
    
    [self waitForExpectationsWithTimeout:20. handler:nil];
    
    id eventObserver = [NSNotificationCenter.defaultCenter addObserverForComScorePlayerEventNotificationUsingBlock:^(NSString * _Nonnull event, NSDictionary * _Nonnull labels) {
        XCTFail(@"No event must be received");
    }];
    
    [self expectationForElapsedTimeInterval:10. withHandler:nil];
    
    [self waitForExpectationsWithTimeout:20. handler:^(NSError * _Nullable error) {
        [NSNotificationCenter.defaultCenter removeObserver:eventObserver];
    }];
}

- (void)testSegmentSelectionAfterStartOnFullLength
{
    [self expectationForComScorePlayerEventNotificationWithHandler:^BOOL(NSString *event, NSDictionary *labels) {
        XCTAssertEqualObjects(labels[@"ns_st_ev"], @"play");
        XCTAssertEqualObjects(labels[@"stream_name"], @"full");
        XCTAssertNil(labels[@"segment_name"]);
        XCTAssertEqualObjects(labels[@"overridable_name"], @"full");
        return YES;
    }];
    
    Segment *segment = [Segment segmentWithName:@"segment" timeRange:CMTimeRangeMake(CMTimeMakeWithSeconds(50., NSEC_PER_SEC), CMTimeMakeWithSeconds(3., NSEC_PER_SEC))];
    
    SRGAnalyticsStreamLabels *labels = [[SRGAnalyticsStreamLabels alloc] init];
    labels.comScoreCustomInfo = @{ @"stream_name" : @"full",
                                   @"overridable_name" : @"full" };
    
    [self.mediaPlayerController playURL:OnDemandTestURL() atPosition:nil withSegments:@[segment] analyticsLabels:labels userInfo:nil];
    
    [self waitForExpectationsWithTimeout:20. handler:nil];
    
    __block BOOL pauseReceived = NO;
    __block BOOL playReceived = NO;
    
    [self expectationForComScorePlayerEventNotificationWithHandler:^BOOL(NSString * _Nonnull event, NSDictionary * _Nonnull labels) {
        if ([labels[@"ns_st_ev"] isEqualToString:@"pause"]) {
            XCTAssertFalse(playReceived);
            pauseReceived = YES;
        }
        else if([labels[@"ns_st_ev"] isEqualToString:@"play"]) {
            playReceived = YES;
        }
        
        XCTAssertEqualObjects(labels[@"stream_name"], @"full");
        XCTAssertNil(labels[@"segment_name"]);
        XCTAssertEqualObjects(labels[@"overridable_name"], @"full");
        
        return pauseReceived && playReceived;
    }];
    
    [self.mediaPlayerController seekToPosition:nil inSegment:segment withCompletionHandler:nil];
    
    [self waitForExpectationsWithTimeout:20. handler:nil];
}

- (void)testSegmentSelectionWhilePlayingSelectedSegment
{
    [self expectationForComScorePlayerEventNotificationWithHandler:^BOOL(NSString *event, NSDictionary *labels) {
        XCTAssertEqualObjects(labels[@"ns_st_ev"], @"play");
        XCTAssertEqualObjects(labels[@"stream_name"], @"full");
        XCTAssertNil(labels[@"segment_name"]);
        XCTAssertEqualObjects(labels[@"overridable_name"], @"full");
        return YES;
    }];
    
    Segment *segment1 = [Segment segmentWithName:@"segment1" timeRange:CMTimeRangeMake(CMTimeMakeWithSeconds(50., NSEC_PER_SEC), CMTimeMakeWithSeconds(10., NSEC_PER_SEC))];
    Segment *segment2 = [Segment segmentWithName:@"segment2" timeRange:CMTimeRangeMake(CMTimeMakeWithSeconds(100., NSEC_PER_SEC), CMTimeMakeWithSeconds(10., NSEC_PER_SEC))];
    
    SRGAnalyticsStreamLabels *labels = [[SRGAnalyticsStreamLabels alloc] init];
    labels.comScoreCustomInfo = @{ @"stream_name" : @"full",
                                   @"overridable_name" : @"full" };
    
    [self.mediaPlayerController playURL:OnDemandTestURL() atIndex:0 position:nil inSegments:@[segment1, segment2] withAnalyticsLabels:labels userInfo:nil];
    
    [self waitForExpectationsWithTimeout:20. handler:nil];
    
    __block BOOL pauseReceived = NO;
    __block BOOL playReceived = NO;
    
    [self expectationForComScorePlayerEventNotificationWithHandler:^BOOL(NSString * _Nonnull event, NSDictionary * _Nonnull labels) {
        if ([labels[@"ns_st_ev"] isEqualToString:@"pause"]) {
            XCTAssertFalse(playReceived);
            pauseReceived = YES;
        }
        else if([labels[@"ns_st_ev"] isEqualToString:@"play"]) {
            playReceived = YES;
        }
        
        XCTAssertEqualObjects(labels[@"stream_name"], @"full");
        XCTAssertNil(labels[@"segment_name"]);
        XCTAssertEqualObjects(labels[@"overridable_name"], @"full");
        
        return pauseReceived && playReceived;
    }];
    
    [self.mediaPlayerController seekToPosition:nil inSegment:segment2 withCompletionHandler:nil];
    
    [self waitForExpectationsWithTimeout:20. handler:nil];
}

- (void)testTransitionFromSelectedSegmentIntoNonSelectedContiguousSegment
{
    [self expectationForComScorePlayerEventNotificationWithHandler:^BOOL(NSString *event, NSDictionary *labels) {
        XCTAssertEqualObjects(labels[@"ns_st_ev"], @"play");
        XCTAssertEqualObjects(labels[@"stream_name"], @"full");
        XCTAssertNil(labels[@"segment_name"]);
        XCTAssertEqualObjects(labels[@"overridable_name"], @"full");
        return YES;
    }];
    
    Segment *segment1 = [Segment segmentWithName:@"segment1" timeRange:CMTimeRangeMake(CMTimeMakeWithSeconds(20., NSEC_PER_SEC), CMTimeMakeWithSeconds(3., NSEC_PER_SEC))];
    Segment *segment2 = [Segment segmentWithName:@"segment2" timeRange:CMTimeRangeMake(CMTimeMakeWithSeconds(23., NSEC_PER_SEC), CMTimeMakeWithSeconds(3., NSEC_PER_SEC))];
    
    SRGAnalyticsStreamLabels *labels = [[SRGAnalyticsStreamLabels alloc] init];
    labels.comScoreCustomInfo = @{ @"stream_name" : @"full",
                                   @"overridable_name" : @"full" };
    
    [self.mediaPlayerController playURL:OnDemandTestURL() atIndex:0 position:nil inSegments:@[segment1, segment2] withAnalyticsLabels:labels userInfo:nil];
    
    [self waitForExpectationsWithTimeout:20. handler:nil];
    
    id eventObserver = [NSNotificationCenter.defaultCenter addObserverForComScorePlayerEventNotificationUsingBlock:^(NSString * _Nonnull event, NSDictionary * _Nonnull labels) {
        XCTFail(@"No event must be received");
    }];
    
    [self expectationForElapsedTimeInterval:5. withHandler:nil];
    
    [self waitForExpectationsWithTimeout:20. handler:^(NSError * _Nullable error) {
        [NSNotificationCenter.defaultCenter removeObserver:eventObserver];
    }];
}

- (void)testSegmentRepeatedSelection
{
    [self expectationForComScorePlayerEventNotificationWithHandler:^BOOL(NSString *event, NSDictionary *labels) {
        XCTAssertEqualObjects(labels[@"ns_st_ev"], @"play");
        XCTAssertEqualObjects(labels[@"stream_name"], @"full");
        XCTAssertNil(labels[@"segment_name"]);
        XCTAssertEqualObjects(labels[@"overridable_name"], @"full");
        return YES;
    }];
    
    Segment *segment = [Segment segmentWithName:@"segment" timeRange:CMTimeRangeMake(CMTimeMakeWithSeconds(50., NSEC_PER_SEC), CMTimeMakeWithSeconds(10., NSEC_PER_SEC))];
    
    SRGAnalyticsStreamLabels *labels = [[SRGAnalyticsStreamLabels alloc] init];
    labels.comScoreCustomInfo = @{ @"stream_name" : @"full",
                                   @"overridable_name" : @"full" };
    
    [self.mediaPlayerController playURL:OnDemandTestURL() atIndex:0 position:nil inSegments:@[segment] withAnalyticsLabels:labels userInfo:nil];
    
    [self waitForExpectationsWithTimeout:20. handler:nil];
    
    __block BOOL pauseReceived = NO;
    __block BOOL playReceived = NO;
    
    [self expectationForComScorePlayerEventNotificationWithHandler:^BOOL(NSString * _Nonnull event, NSDictionary * _Nonnull labels) {
        if ([labels[@"ns_st_ev"] isEqualToString:@"pause"]) {
            XCTAssertFalse(playReceived);
            pauseReceived = YES;
        }
        else if([labels[@"ns_st_ev"] isEqualToString:@"play"]) {
            playReceived = YES;
        }
        
        XCTAssertEqualObjects(labels[@"stream_name"], @"full");
        XCTAssertNil(labels[@"segment_name"]);
        XCTAssertEqualObjects(labels[@"overridable_name"], @"full");
        
        return pauseReceived && playReceived;
    }];
    
    [self.mediaPlayerController seekToPosition:nil inSegment:segment withCompletionHandler:nil];
    
    [self waitForExpectationsWithTimeout:20. handler:nil];
}

- (void)testSeekOutsideSelectedSegment
{
    [self expectationForComScorePlayerEventNotificationWithHandler:^BOOL(NSString *event, NSDictionary *labels) {
        XCTAssertEqualObjects(labels[@"ns_st_ev"], @"play");
        XCTAssertEqualObjects(labels[@"stream_name"], @"full");
        XCTAssertNil(labels[@"segment_name"]);
        XCTAssertEqualObjects(labels[@"overridable_name"], @"full");
        return YES;
    }];
    
    Segment *segment1 = [Segment segmentWithName:@"segment1" timeRange:CMTimeRangeMake(CMTimeMakeWithSeconds(50., NSEC_PER_SEC), CMTimeMakeWithSeconds(10., NSEC_PER_SEC))];
    Segment *segment2 = [Segment segmentWithName:@"segment2" timeRange:CMTimeRangeMake(CMTimeMakeWithSeconds(60., NSEC_PER_SEC), CMTimeMakeWithSeconds(20., NSEC_PER_SEC))];
    
    SRGAnalyticsStreamLabels *labels = [[SRGAnalyticsStreamLabels alloc] init];
    labels.comScoreCustomInfo = @{ @"stream_name" : @"full",
                                   @"overridable_name" : @"full" };
    
    [self.mediaPlayerController playURL:OnDemandTestURL() atIndex:0 position:nil inSegments:@[segment1, segment2] withAnalyticsLabels:labels userInfo:nil];
    
    [self waitForExpectationsWithTimeout:20. handler:nil];
    
    __block BOOL pauseReceived = NO;
    __block BOOL playReceived = NO;
    
    [self expectationForComScorePlayerEventNotificationWithHandler:^BOOL(NSString * _Nonnull event, NSDictionary * _Nonnull labels) {
        if ([labels[@"ns_st_ev"] isEqualToString:@"pause"]) {
            XCTAssertFalse(playReceived);
            pauseReceived = YES;
        }
        else if([labels[@"ns_st_ev"] isEqualToString:@"play"]) {
            playReceived = YES;
        }
        
        XCTAssertEqualObjects(labels[@"stream_name"], @"full");
        XCTAssertNil(labels[@"segment_name"]);
        XCTAssertEqualObjects(labels[@"overridable_name"], @"full");
        
        return pauseReceived && playReceived;
    }];
    
    CMTime seekTime = CMTimeAdd(CMTimeRangeGetEnd(segment1.srg_timeRange), CMTimeMakeWithSeconds(10., NSEC_PER_SEC));
    [self.mediaPlayerController seekToPosition:[SRGPosition positionAtTime:seekTime] withCompletionHandler:nil];
    
    [self waitForExpectationsWithTimeout:20. handler:nil];
}

- (void)testSeekWithinSelectedSegment
{
    [self expectationForComScorePlayerEventNotificationWithHandler:^BOOL(NSString *event, NSDictionary *labels) {
        XCTAssertEqualObjects(labels[@"ns_st_ev"], @"play");
        XCTAssertEqualObjects(labels[@"stream_name"], @"full");
        XCTAssertNil(labels[@"segment_name"]);
        XCTAssertEqualObjects(labels[@"overridable_name"], @"full");
        return YES;
    }];
    
    Segment *segment = [Segment segmentWithName:@"segment" timeRange:CMTimeRangeMake(CMTimeMakeWithSeconds(50., NSEC_PER_SEC), CMTimeMakeWithSeconds(10., NSEC_PER_SEC))];
    
    SRGAnalyticsStreamLabels *labels = [[SRGAnalyticsStreamLabels alloc] init];
    labels.comScoreCustomInfo = @{ @"stream_name" : @"full",
                                   @"overridable_name" : @"full" };
    
    [self.mediaPlayerController playURL:OnDemandTestURL() atIndex:0 position:nil inSegments:@[segment] withAnalyticsLabels:labels userInfo:nil];
    
    [self waitForExpectationsWithTimeout:20. handler:nil];
    
    __block BOOL pauseReceived = NO;
    __block BOOL playReceived = NO;
    
    [self expectationForComScorePlayerEventNotificationWithHandler:^BOOL(NSString * _Nonnull event, NSDictionary * _Nonnull labels) {
        if ([labels[@"ns_st_ev"] isEqualToString:@"pause"]) {
            XCTAssertFalse(playReceived);
            pauseReceived = YES;
        }
        else if([labels[@"ns_st_ev"] isEqualToString:@"play"]) {
            playReceived = YES;
        }
        
        XCTAssertEqualObjects(labels[@"stream_name"], @"full");
        XCTAssertNil(labels[@"segment_name"]);
        XCTAssertEqualObjects(labels[@"overridable_name"], @"full");
        
        return pauseReceived && playReceived;
    }];
    
    CMTime seekTime = CMTimeAdd(segment.srg_timeRange.start, CMTimeMakeWithSeconds(3., NSEC_PER_SEC));
    [self.mediaPlayerController seekToPosition:[SRGPosition positionAtTime:seekTime] withCompletionHandler:nil];
    
    [self waitForExpectationsWithTimeout:20. handler:nil];
}

- (void)testSelectedSegmentAtStreamEnd
{
    // Precise timing information gathered from the stream itself
    Segment *segment = [Segment segmentWithName:@"segment" timeRange:CMTimeRangeMake(CMTimeMakeWithSeconds(1795.045, NSEC_PER_SEC), CMTimeMakeWithSeconds(5., NSEC_PER_SEC))];
    
    [self expectationForComScorePlayerEventNotificationWithHandler:^BOOL(NSString *event, NSDictionary *labels) {
        XCTAssertEqualObjects(labels[@"ns_st_ev"], @"play");
        XCTAssertEqualObjects(labels[@"stream_name"], @"full");
        XCTAssertNil(labels[@"segment_name"]);
        XCTAssertEqualObjects(labels[@"overridable_name"], @"full");
        return YES;
    }];
    
    SRGAnalyticsStreamLabels *labels = [[SRGAnalyticsStreamLabels alloc] init];
    labels.comScoreCustomInfo = @{ @"stream_name" : @"full",
                                   @"overridable_name" : @"full" };
    
    [self.mediaPlayerController playURL:OnDemandTestURL() atIndex:0 position:nil inSegments:@[segment] withAnalyticsLabels:labels userInfo:nil];
    
    [self waitForExpectationsWithTimeout:20. handler:nil];
    
    XCTAssertEqualObjects(self.mediaPlayerController.currentSegment, segment);
    XCTAssertEqualObjects(self.mediaPlayerController.selectedSegment, segment);
    
    [self expectationForComScorePlayerEventNotificationWithHandler:^BOOL(NSString *event, NSDictionary *labels) {
        XCTAssertEqualObjects(labels[@"ns_st_ev"], @"end");
        XCTAssertEqualObjects(labels[@"stream_name"], @"full");
        XCTAssertNil(labels[@"segment_name"]);
        XCTAssertEqualObjects(labels[@"overridable_name"], @"full");
        return YES;
    }];
    
    [self waitForExpectationsWithTimeout:20. handler:nil];
    
    XCTAssertNil(self.mediaPlayerController.currentSegment);
    XCTAssertNil(self.mediaPlayerController.selectedSegment);
}

- (void)testResetWhilePlayingSegment
{
    [self expectationForComScorePlayerEventNotificationWithHandler:^BOOL(NSString *event, NSDictionary *labels) {
        XCTAssertEqualObjects(labels[@"ns_st_ev"], @"play");
        XCTAssertEqualObjects(labels[@"stream_name"], @"full");
        XCTAssertNil(labels[@"segment_name"]);
        XCTAssertEqualObjects(labels[@"overridable_name"], @"full");
        return YES;
    }];
    
    Segment *segment = [Segment segmentWithName:@"segment" timeRange:CMTimeRangeMake(CMTimeMakeWithSeconds(50., NSEC_PER_SEC), CMTimeMakeWithSeconds(10., NSEC_PER_SEC))];
    
    SRGAnalyticsStreamLabels *labels = [[SRGAnalyticsStreamLabels alloc] init];
    labels.comScoreCustomInfo = @{ @"stream_name" : @"full",
                                   @"overridable_name" : @"full" };
    
    [self.mediaPlayerController playURL:OnDemandTestURL() atIndex:0 position:nil inSegments:@[segment] withAnalyticsLabels:labels userInfo:nil];
    
    [self waitForExpectationsWithTimeout:20. handler:nil];
    
    [self expectationForComScorePlayerEventNotificationWithHandler:^BOOL(NSString *event, NSDictionary *labels) {
        XCTAssertEqualObjects(labels[@"ns_st_ev"], @"end");
        XCTAssertEqualObjects(labels[@"stream_name"], @"full");
        XCTAssertNil(labels[@"segment_name"]);
        XCTAssertEqualObjects(labels[@"overridable_name"], @"full");
        return YES;
    }];
    
    [self.mediaPlayerController reset];
    
    [self waitForExpectationsWithTimeout:20. handler:nil];
}

- (void)testBlockedSegmentSelection
{
    [self expectationForComScorePlayerEventNotificationWithHandler:^BOOL(NSString *event, NSDictionary *labels) {
        XCTAssertEqualObjects(labels[@"ns_st_ev"], @"play");
        XCTAssertEqualObjects(labels[@"stream_name"], @"full");
        XCTAssertNil(labels[@"segment_name"]);
        XCTAssertEqualObjects(labels[@"overridable_name"], @"full");
        return YES;
    }];
    
    Segment *segment = [Segment blockedSegmentWithName:@"segment" timeRange:CMTimeRangeMake(CMTimeMakeWithSeconds(50., NSEC_PER_SEC), CMTimeMakeWithSeconds(10., NSEC_PER_SEC))];
    
    SRGAnalyticsStreamLabels *labels = [[SRGAnalyticsStreamLabels alloc] init];
    labels.comScoreCustomInfo = @{ @"stream_name" : @"full",
                                   @"overridable_name" : @"full" };
    
    [self.mediaPlayerController playURL:OnDemandTestURL() atPosition:nil withSegments:@[segment] analyticsLabels:labels userInfo:nil];
    
    [self waitForExpectationsWithTimeout:20. handler:nil];
    
    // Expect pause and play on the full-length (corresponding to the segment being skipped)
    
    __block BOOL fullLengthPauseReceived = NO;
    __block BOOL fullLengthPlayReceived = NO;
    
    [self expectationForComScorePlayerEventNotificationWithHandler:^BOOL(NSString *event, NSDictionary *labels) {
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
    
    [self.mediaPlayerController seekToPosition:nil inSegment:segment withCompletionHandler:nil];
    
    [self waitForExpectationsWithTimeout:20. handler:nil];
}

- (void)testSeekIntoBlockedSegment
{
    [self expectationForComScorePlayerEventNotificationWithHandler:^BOOL(NSString *event, NSDictionary *labels) {
        XCTAssertEqualObjects(labels[@"ns_st_ev"], @"play");
        XCTAssertEqualObjects(labels[@"stream_name"], @"full");
        XCTAssertNil(labels[@"segment_name"]);
        XCTAssertEqualObjects(labels[@"overridable_name"], @"full");
        return YES;
    }];
    
    Segment *segment = [Segment blockedSegmentWithName:@"segment" timeRange:CMTimeRangeMake(CMTimeMakeWithSeconds(50., NSEC_PER_SEC), CMTimeMakeWithSeconds(10., NSEC_PER_SEC))];
    
    SRGAnalyticsStreamLabels *labels = [[SRGAnalyticsStreamLabels alloc] init];
    labels.comScoreCustomInfo = @{ @"stream_name" : @"full",
                                   @"overridable_name" : @"full" };
    
    [self.mediaPlayerController playURL:OnDemandTestURL() atPosition:nil withSegments:@[segment] analyticsLabels:labels userInfo:nil];
    
    [self waitForExpectationsWithTimeout:20. handler:nil];
    
    // Expect pause / play for the full-length
    
    __block BOOL fullLengthPauseReceived = NO;
    __block BOOL fullLengthPlayReceived = NO;
    
    [self expectationForComScorePlayerEventNotificationWithHandler:^BOOL(NSString *event, NSDictionary *labels) {
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
    
    [self.mediaPlayerController seekToPosition:[SRGPosition positionAtTimeInSeconds:55.] withCompletionHandler:nil];
    
    [self waitForExpectationsWithTimeout:20. handler:nil];
}

- (void)testPlayStartingWithBlockedSegment
{
    // Expect a play attempt at 50, then a pause / play transition to 60 because of the blocked segment
    
    __block BOOL fullLengthPlayAt50Received = NO;
    __block BOOL fullLengthPauseAt50Received = NO;
    __block BOOL fullLengthPlayAt60Received = NO;
    
    [self expectationForComScorePlayerEventNotificationWithHandler:^BOOL(NSString *event, NSDictionary *labels) {
        if ([event isEqualToString:@"play"]) {
            if ([labels[@"ns_st_po"] integerValue] / 1000 == 50) {
                XCTAssertFalse(fullLengthPauseAt50Received);
                XCTAssertFalse(fullLengthPlayAt60Received);
                
                XCTAssertEqualObjects(labels[@"stream_name"], @"full");
                XCTAssertNil(labels[@"segment_name"]);
                XCTAssertEqualObjects(labels[@"overridable_name"], @"full");
                
                fullLengthPlayAt50Received = YES;
            }
            else if ([labels[@"ns_st_po"] integerValue] / 1000 == 60) {
                XCTAssertEqualObjects(labels[@"stream_name"], @"full");
                XCTAssertNil(labels[@"segment_name"]);
                XCTAssertEqualObjects(labels[@"overridable_name"], @"full");
                
                fullLengthPlayAt60Received = YES;
            }
            else {
                XCTFail(@"Unexpected event %@", event);
            }
        }
        else if ([event isEqualToString:@"pause"]) {
            XCTAssertFalse(fullLengthPlayAt60Received);
            
            XCTAssertEqual([labels[@"ns_st_po"] integerValue] / 1000, 50);
            XCTAssertEqualObjects(labels[@"stream_name"], @"full");
            XCTAssertNil(labels[@"segment_name"]);
            XCTAssertEqualObjects(labels[@"overridable_name"], @"full");
            
            fullLengthPauseAt50Received = YES;
        }
        else {
            XCTFail(@"Unexpected event %@", event);
        }
        
        return fullLengthPlayAt50Received && fullLengthPauseAt50Received && fullLengthPlayAt60Received;
    }];
    
    Segment *segment = [Segment blockedSegmentWithName:@"segment" timeRange:CMTimeRangeMake(CMTimeMakeWithSeconds(50., NSEC_PER_SEC), CMTimeMakeWithSeconds(10., NSEC_PER_SEC))];
    
    SRGAnalyticsStreamLabels *labels = [[SRGAnalyticsStreamLabels alloc] init];
    labels.comScoreCustomInfo = @{ @"stream_name" : @"full",
                                   @"overridable_name" : @"full" };
    
    [self.mediaPlayerController playURL:OnDemandTestURL() atIndex:0 position:nil inSegments:@[segment] withAnalyticsLabels:labels userInfo:nil];
    
    [self waitForExpectationsWithTimeout:20. handler:nil];
}

- (void)testBlockedSegmentPlaythrough
{
    [self expectationForComScorePlayerEventNotificationWithHandler:^BOOL(NSString *event, NSDictionary *labels) {
        XCTAssertEqualObjects(labels[@"ns_st_ev"], @"play");
        XCTAssertEqualObjects(labels[@"stream_name"], @"full");
        XCTAssertNil(labels[@"segment_name"]);
        XCTAssertEqualObjects(labels[@"overridable_name"], @"full");
        return YES;
    }];
    
    Segment *segment = [Segment blockedSegmentWithName:@"segment" timeRange:CMTimeRangeMake(CMTimeMakeWithSeconds(2., NSEC_PER_SEC), CMTimeMakeWithSeconds(3., NSEC_PER_SEC))];
    
    SRGAnalyticsStreamLabels *labels = [[SRGAnalyticsStreamLabels alloc] init];
    labels.comScoreCustomInfo = @{ @"stream_name" : @"full",
                                   @"overridable_name" : @"full" };
    
    [self.mediaPlayerController playURL:OnDemandTestURL() atPosition:nil withSegments:@[segment] analyticsLabels:labels userInfo:nil];
    
    [self waitForExpectationsWithTimeout:20. handler:nil];
    
    // Play for a while. Expect pause / play for the full-length when skipping over the segment
    
    __block BOOL fullLengthPauseReceived = NO;
    __block BOOL fullLengthPlayReceived = NO;
    
    [self expectationForComScorePlayerEventNotificationWithHandler:^BOOL(NSString *event, NSDictionary *labels) {
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
    id eventObserver = [NSNotificationCenter.defaultCenter addObserverForComScorePlayerEventNotificationUsingBlock:^(NSString * _Nonnull event, NSDictionary * _Nonnull labels) {
        XCTFail(@"No event must be received when tracking has been disabled");
    }];
    
    [self expectationForElapsedTimeInterval:5. withHandler:nil];
    
    self.mediaPlayerController.tracked = NO;
    [self.mediaPlayerController playURL:OnDemandTestURL()];
    
    [self waitForExpectationsWithTimeout:20. handler:^(NSError * _Nullable error) {
        [NSNotificationCenter.defaultCenter removeObserver:eventObserver];
    }];
}

- (void)testDisableTrackingWhilePreparing
{
    // Wait until the player is preparing to play
    [self expectationForSingleNotification:SRGMediaPlayerPlaybackStateDidChangeNotification object:self.mediaPlayerController handler:^BOOL(NSNotification * _Nonnull notification) {
        XCTAssertEqual([notification.userInfo[SRGMediaPlayerPlaybackStateKey] integerValue], SRGMediaPlayerPlaybackStatePreparing);
        return YES;
    }];
    
    [self.mediaPlayerController playURL:OnDemandTestURL()];
    
    [self waitForExpectationsWithTimeout:20. handler:nil];
    
    // Play for a while. No stream events must be received
    id eventObserver = [NSNotificationCenter.defaultCenter addObserverForComScorePlayerEventNotificationUsingBlock:^(NSString * _Nonnull event, NSDictionary * _Nonnull labels) {
        XCTFail(@"No event must be received when tracking has been disabled");
    }];
    
    [self expectationForElapsedTimeInterval:5. withHandler:nil];
    
    XCTAssertEqual(self.mediaPlayerController.playbackState, SRGMediaPlayerPlaybackStatePreparing);
    self.mediaPlayerController.tracked = NO;
    
    [self waitForExpectationsWithTimeout:20. handler:^(NSError * _Nullable error) {
        [NSNotificationCenter.defaultCenter removeObserver:eventObserver];
    }];
}

- (void)testDisableTrackingWhilePlaying
{
    // Wait until the media plays
    [self expectationForComScorePlayerEventNotificationWithHandler:^BOOL(NSString *event, NSDictionary *labels) {
        XCTAssertEqualObjects(event, @"play");
        return YES;
    }];
    
    [self.mediaPlayerController playURL:OnDemandTestURL()];
    
    [self waitForExpectationsWithTimeout:20. handler:nil];
    
    // Stop tracking while playing. Expect an end to be received
    [self expectationForComScorePlayerEventNotificationWithHandler:^BOOL(NSString *event, NSDictionary *labels) {
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
    [self expectationForComScorePlayerEventNotificationWithHandler:^BOOL(NSString *event, NSDictionary *labels) {
        XCTAssertEqualObjects(labels[@"ns_st_ev"], @"play");
        XCTAssertEqualObjects(labels[@"stream_name"], @"full");
        XCTAssertEqualObjects(labels[@"segment_name"], @"segment");
        XCTAssertEqualObjects(labels[@"overridable_name"], @"segment");
        return YES;
    }];
    
    Segment *segment = [Segment segmentWithName:@"segment" timeRange:CMTimeRangeMake(CMTimeMakeWithSeconds(2., NSEC_PER_SEC), CMTimeMakeWithSeconds(3., NSEC_PER_SEC))];
    
    SRGAnalyticsStreamLabels *labels = [[SRGAnalyticsStreamLabels alloc] init];
    labels.comScoreCustomInfo = @{ @"stream_name" : @"full",
                                   @"overridable_name" : @"full" };
    
    [self.mediaPlayerController playURL:OnDemandTestURL() atIndex:0 position:nil inSegments:@[segment] withAnalyticsLabels:labels userInfo:nil];
    
    [self waitForExpectationsWithTimeout:20. handler:nil];
    
    // Stop tracking while playing. Expect an end to be received with segment labels
    [self expectationForComScorePlayerEventNotificationWithHandler:^BOOL(NSString *event, NSDictionary *labels) {
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
    [self expectationForComScorePlayerEventNotificationWithHandler:^BOOL(NSString *event, NSDictionary *labels) {
        XCTAssertEqualObjects(event, @"play");
        return YES;
    }];
    
    [self.mediaPlayerController playURL:OnDemandTestURL()];
    
    [self waitForExpectationsWithTimeout:20. handler:nil];
    
    // Pause playback
    [self expectationForComScorePlayerEventNotificationWithHandler:^BOOL(NSString *event, NSDictionary *labels) {
        XCTAssertEqualObjects(event, @"pause");
        return YES;
    }];
    
    [self.mediaPlayerController pause];
    
    [self waitForExpectationsWithTimeout:20. handler:nil];
    
    // Stop tracking while paused. Expect an end to be received
    [self expectationForComScorePlayerEventNotificationWithHandler:^BOOL(NSString *event, NSDictionary *labels) {
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
    [self expectationForComScorePlayerEventNotificationWithHandler:^BOOL(NSString *event, NSDictionary *labels) {
        XCTAssertEqualObjects(labels[@"ns_st_ev"], @"play");
        XCTAssertEqualObjects(labels[@"stream_name"], @"full");
        XCTAssertEqualObjects(labels[@"segment_name"], @"segment");
        XCTAssertEqualObjects(labels[@"overridable_name"], @"segment");
        return YES;
    }];
    
    Segment *segment = [Segment segmentWithName:@"segment" timeRange:CMTimeRangeMake(CMTimeMakeWithSeconds(2., NSEC_PER_SEC), CMTimeMakeWithSeconds(3., NSEC_PER_SEC))];
    
    SRGAnalyticsStreamLabels *labels = [[SRGAnalyticsStreamLabels alloc] init];
    labels.comScoreCustomInfo = @{ @"stream_name" : @"full",
                                   @"overridable_name" : @"full" };
    
    [self.mediaPlayerController playURL:OnDemandTestURL() atIndex:0 position:nil inSegments:@[segment] withAnalyticsLabels:labels userInfo:nil];
    
    [self waitForExpectationsWithTimeout:20. handler:nil];
    
    // Pause playback. Expect a pause with segment labels
    [self expectationForComScorePlayerEventNotificationWithHandler:^BOOL(NSString *event, NSDictionary *labels) {
        XCTAssertEqualObjects(labels[@"ns_st_ev"], @"pause");
        XCTAssertEqualObjects(labels[@"stream_name"], @"full");
        XCTAssertEqualObjects(labels[@"segment_name"], @"segment");
        XCTAssertEqualObjects(labels[@"overridable_name"], @"segment");
        return YES;
    }];
    
    [self.mediaPlayerController pause];
    
    [self waitForExpectationsWithTimeout:20. handler:nil];
    
    // Stop tracking while paused. Expect an end to be received with segment labels
    [self expectationForComScorePlayerEventNotificationWithHandler:^BOOL(NSString *event, NSDictionary *labels) {
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
    [self expectationForSingleNotification:SRGMediaPlayerPlaybackStateDidChangeNotification object:self.mediaPlayerController handler:^BOOL(NSNotification * _Nonnull notification) {
        XCTAssertEqual([notification.userInfo[SRGMediaPlayerPlaybackStateKey] integerValue], SRGMediaPlayerPlaybackStatePreparing);
        return YES;
    }];
    
    self.mediaPlayerController.tracked = NO;
    [self.mediaPlayerController playURL:OnDemandTestURL()];
    
    [self waitForExpectationsWithTimeout:20. handler:nil];
    
    // Enable tracking. Expect plays to be received
    [self expectationForComScorePlayerEventNotificationWithHandler:^BOOL(NSString *event, NSDictionary *labels) {
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
    [self expectationForSingleNotification:SRGMediaPlayerPlaybackStateDidChangeNotification object:self.mediaPlayerController handler:^BOOL(NSNotification * _Nonnull notification) {
        XCTAssertEqual([notification.userInfo[SRGMediaPlayerPlaybackStateKey] integerValue], SRGMediaPlayerPlaybackStatePreparing);
        return YES;
    }];
    
    self.mediaPlayerController.tracked = NO;
    Segment *segment = [Segment segmentWithName:@"segment" timeRange:CMTimeRangeMake(CMTimeMakeWithSeconds(2., NSEC_PER_SEC), CMTimeMakeWithSeconds(3., NSEC_PER_SEC))];
    
    SRGAnalyticsStreamLabels *labels = [[SRGAnalyticsStreamLabels alloc] init];
    labels.comScoreCustomInfo = @{ @"stream_name" : @"full",
                                   @"overridable_name" : @"full" };
    
    [self.mediaPlayerController playURL:OnDemandTestURL() atIndex:0 position:nil inSegments:@[segment] withAnalyticsLabels:labels userInfo:nil];
    
    [self waitForExpectationsWithTimeout:20. handler:nil];
    
    // Enable tracking. Expect plays to be received
    [self expectationForComScorePlayerEventNotificationWithHandler:^BOOL(NSString *event, NSDictionary *labels) {
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
    id eventObserver = [NSNotificationCenter.defaultCenter addObserverForComScorePlayerEventNotificationUsingBlock:^(NSString * _Nonnull event, NSDictionary * _Nonnull labels) {
        XCTFail(@"No event must be received when tracking has been disabled");
    }];
    
    [self expectationForSingleNotification:SRGMediaPlayerPlaybackStateDidChangeNotification object:self.mediaPlayerController handler:^BOOL(NSNotification * _Nonnull notification) {
        return [notification.userInfo[SRGMediaPlayerPlaybackStateKey] integerValue] == SRGMediaPlayerPlaybackStatePlaying;
    }];
    
    self.mediaPlayerController.tracked = NO;
    [self.mediaPlayerController playURL:OnDemandTestURL()];
    
    [self waitForExpectationsWithTimeout:20. handler:^(NSError * _Nullable error) {
        [NSNotificationCenter.defaultCenter removeObserver:eventObserver];
    }];
    
    // Enable tracking. Expect a play to be received
    [self expectationForComScorePlayerEventNotificationWithHandler:^BOOL(NSString *event, NSDictionary *labels) {
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
    id eventObserver = [NSNotificationCenter.defaultCenter addObserverForComScorePlayerEventNotificationUsingBlock:^(NSString * _Nonnull event, NSDictionary * _Nonnull labels) {
        XCTFail(@"No event must be received when tracking has been disabled");
    }];
    
    [self expectationForSingleNotification:SRGMediaPlayerPlaybackStateDidChangeNotification object:self.mediaPlayerController handler:^BOOL(NSNotification * _Nonnull notification) {
        return [notification.userInfo[SRGMediaPlayerPlaybackStateKey] integerValue] == SRGMediaPlayerPlaybackStatePlaying;
    }];
    
    self.mediaPlayerController.tracked = NO;
    Segment *segment = [Segment segmentWithName:@"segment" timeRange:CMTimeRangeMake(CMTimeMakeWithSeconds(2., NSEC_PER_SEC), CMTimeMakeWithSeconds(3., NSEC_PER_SEC))];
    
    SRGAnalyticsStreamLabels *labels = [[SRGAnalyticsStreamLabels alloc] init];
    labels.comScoreCustomInfo = @{ @"stream_name" : @"full",
                                   @"overridable_name" : @"full" };
    
    [self.mediaPlayerController playURL:OnDemandTestURL() atIndex:0 position:nil inSegments:@[segment] withAnalyticsLabels:labels userInfo:nil];
    
    [self waitForExpectationsWithTimeout:20. handler:^(NSError * _Nullable error) {
        [NSNotificationCenter.defaultCenter removeObserver:eventObserver];
    }];
    
    // Enable tracking. Expect a play to be received, with segment labels
    [self expectationForComScorePlayerEventNotificationWithHandler:^BOOL(NSString *event, NSDictionary *labels) {
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
    id eventObserver = [NSNotificationCenter.defaultCenter addObserverForComScorePlayerEventNotificationUsingBlock:^(NSString * _Nonnull event, NSDictionary * _Nonnull labels) {
        XCTFail(@"No event must be received when tracking has been disabled");
    }];
    
    [self expectationForSingleNotification:SRGMediaPlayerPlaybackStateDidChangeNotification object:self.mediaPlayerController handler:^BOOL(NSNotification * _Nonnull notification) {
        return [notification.userInfo[SRGMediaPlayerPlaybackStateKey] integerValue] == SRGMediaPlayerPlaybackStatePlaying;
    }];
    
    self.mediaPlayerController.tracked = NO;
    [self.mediaPlayerController playURL:OnDemandTestURL()];
    
    [self waitForExpectationsWithTimeout:20. handler:^(NSError * _Nullable error) {
        [NSNotificationCenter.defaultCenter removeObserver:eventObserver];
    }];
    
    // Pause playback
    [self expectationForSingleNotification:SRGMediaPlayerPlaybackStateDidChangeNotification object:self.mediaPlayerController handler:^BOOL(NSNotification * _Nonnull notification) {
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
    
    [self expectationForComScorePlayerEventNotificationWithHandler:^BOOL(NSString *event, NSDictionary *labels) {
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
    [self expectationForComScorePlayerEventNotificationWithHandler:^BOOL(NSString *event, NSDictionary *labels) {
        XCTAssertEqualObjects(event, @"play");
        return YES;
    }];
    
    [self.mediaPlayerController playURL:OnDemandTestURL()];
    
    [self waitForExpectationsWithTimeout:20. handler:nil];
    
    // Stop tracking twice while playing. Expect a single end to be received
    __block NSInteger endEventCount = 0;
    id endEventObserver = [NSNotificationCenter.defaultCenter addObserverForComScorePlayerEventNotificationUsingBlock:^(NSString * _Nonnull event, NSDictionary * _Nonnull labels) {
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
        [NSNotificationCenter.defaultCenter removeObserver:endEventObserver];
    }];
    
    // Check we have received the end notification only once
    XCTAssertEqual(endEventCount, 1);
}

- (void)testEnableTrackingTwiceWhilePlaying
{
    // Wait until the media plays
    [self expectationForSingleNotification:SRGMediaPlayerPlaybackStateDidChangeNotification object:self.mediaPlayerController handler:^BOOL(NSNotification * _Nonnull notification) {
        return [notification.userInfo[SRGMediaPlayerPlaybackStateKey] integerValue] == SRGMediaPlayerPlaybackStatePlaying;
    }];
    
    self.mediaPlayerController.tracked = NO;
    [self.mediaPlayerController playURL:OnDemandTestURL()];
    
    [self waitForExpectationsWithTimeout:20. handler:nil];
    
    // Start tracking twice while playing. Expect a single play to be received
    __block NSInteger playEventCount = 0;
    id endEventObserver = [NSNotificationCenter.defaultCenter addObserverForComScorePlayerEventNotificationUsingBlock:^(NSString * _Nonnull event, NSDictionary * _Nonnull labels) {
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
        [NSNotificationCenter.defaultCenter removeObserver:endEventObserver];
    }];
    
    // Check we have received the end notification only once
    XCTAssertEqual(playEventCount, 1);
}

@end
