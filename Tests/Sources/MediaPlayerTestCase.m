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

@interface MediaPlayerTestCase : AnalyticsTestCase

@property (nonatomic) SRGMediaPlayerController *mediaPlayerController;

@end

@implementation MediaPlayerTestCase

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
    id prepareObserver = [[NSNotificationCenter defaultCenter] addObserverForPlayerSingleHiddenEventNotificationUsingBlock:^(NSString * _Nonnull event, NSDictionary * _Nonnull labels) {
        XCTFail(@"No event must be received when preparing a player");
    }];
    
    [self.mediaPlayerController prepareToPlayURL:OnDemandTestURL() withCompletionHandler:^{
        [[NSNotificationCenter defaultCenter] removeObserver:prepareObserver];
    }];
    
    // Now playing must trigger a play event
    [self expectationForPlayerSingleHiddenEventNotificationWithHandler:^BOOL(NSString *event, NSDictionary *labels) {
        XCTAssertEqualObjects(labels[@"event_id"], @"play");
        return YES;
    }];
    
    [self.mediaPlayerController play];
    
    [self waitForExpectationsWithTimeout:20. handler:nil];
    
    [self expectationForPlayerSingleHiddenEventNotificationWithHandler:^BOOL(NSString *event, NSDictionary *labels) {
        XCTAssertEqualObjects(labels[@"event_id"], @"stop");
        return YES;
    }];
    
    [self.mediaPlayerController reset];
    
    [self waitForExpectationsWithTimeout:20. handler:nil];
}

- (void)testPlaybackToEnd
{
    [self expectationForPlayerSingleHiddenEventNotificationWithHandler:^BOOL(NSString *event, NSDictionary *labels) {
        XCTAssertEqualObjects(labels[@"event_id"], @"play");
        XCTAssertEqualObjects(labels[@"media_position"], @"0");
        return YES;
    }];
    
    [self.mediaPlayerController playURL:OnDemandTestURL()];
    
    [self waitForExpectationsWithTimeout:20. handler:nil];
    
    [self expectationForPlayerSingleHiddenEventNotificationWithHandler:^BOOL(NSString *event, NSDictionary *labels) {
        XCTAssertEqualObjects(labels[@"event_id"], @"seek");
        XCTAssertEqualObjects(labels[@"media_position"], @"0");
        return YES;
    }];
    
    // Seek near the end of the video
    CMTime pastTime = CMTimeSubtract(CMTimeRangeGetEnd(self.mediaPlayerController.timeRange), CMTimeMakeWithSeconds(5., NSEC_PER_SEC));
    [self.mediaPlayerController seekPreciselyToTime:pastTime withCompletionHandler:nil];
    
    [self waitForExpectationsWithTimeout:20. handler:nil];
    
    [self expectationForPlayerSingleHiddenEventNotificationWithHandler:^BOOL(NSString *event, NSDictionary *labels) {
        XCTAssertEqualObjects(labels[@"event_id"], @"play");
        XCTAssertNotEqualObjects(labels[@"media_position"], @"0");
        return YES;
    }];
    
    [self waitForExpectationsWithTimeout:20. handler:nil];
    
    // Let playback finish normally
    
    [self expectationForPlayerSingleHiddenEventNotificationWithHandler:^BOOL(NSString *event, NSDictionary *labels) {
        XCTAssertEqualObjects(labels[@"event_id"], @"eof");
        XCTAssertNotEqualObjects(labels[@"media_position"], @"0");
        return YES;
    }];
    
    [self waitForExpectationsWithTimeout:20. handler:nil];
}

- (void)testPlayStop
{
    [self expectationForPlayerSingleHiddenEventNotificationWithHandler:^BOOL(NSString *event, NSDictionary *labels) {
        XCTAssertEqualObjects(labels[@"event_id"], @"play");
        XCTAssertEqualObjects(labels[@"media_position"], @"0");
        return YES;
    }];
    
    [self.mediaPlayerController playURL:OnDemandTestURL()];
    
    [self waitForExpectationsWithTimeout:20. handler:nil];
    
    // Play for a while. No stream events must be received
    id eventObserver = [[NSNotificationCenter defaultCenter] addObserverForPlayerSingleHiddenEventNotificationUsingBlock:^(NSString * _Nonnull event, NSDictionary * _Nonnull labels) {
        XCTFail(@"No event must be received when playing");
    }];
    // Wait 1 second
    [self expectationForElapsedTimeInterval:1. withHandler:nil];
    [self waitForExpectationsWithTimeout:20. handler:^(NSError * _Nullable error) {
        [[NSNotificationCenter defaultCenter] removeObserver:eventObserver];
    }];
    
    [self expectationForPlayerSingleHiddenEventNotificationWithHandler:^BOOL(NSString *event, NSDictionary *labels) {
        XCTAssertEqualObjects(labels[@"event_id"], @"stop");
        XCTAssertEqualObjects(labels[@"media_position"], @"1");
        return YES;
    }];
    
    [self.mediaPlayerController stop];
    
    [self waitForExpectationsWithTimeout:20. handler:nil];
}

- (void)testPlayReset
{
    [self expectationForPlayerSingleHiddenEventNotificationWithHandler:^BOOL(NSString *event, NSDictionary *labels) {
        XCTAssertEqualObjects(labels[@"event_id"], @"play");
        XCTAssertEqualObjects(labels[@"media_position"], @"0");
        return YES;
    }];
    
    [self.mediaPlayerController playURL:OnDemandTestURL()];
    
    [self waitForExpectationsWithTimeout:20. handler:nil];
    
    // Play for a while. No stream events must be received
    id eventObserver = [[NSNotificationCenter defaultCenter] addObserverForPlayerSingleHiddenEventNotificationUsingBlock:^(NSString * _Nonnull event, NSDictionary * _Nonnull labels) {
        XCTFail(@"No event must be received when playing");
    }];
    // Wait 1 second
    [self expectationForElapsedTimeInterval:1. withHandler:nil];
    [self waitForExpectationsWithTimeout:20. handler:^(NSError * _Nullable error) {
        [[NSNotificationCenter defaultCenter] removeObserver:eventObserver];
    }];
    
    [self expectationForPlayerSingleHiddenEventNotificationWithHandler:^BOOL(NSString *event, NSDictionary *labels) {
        XCTAssertEqualObjects(labels[@"event_id"], @"stop");
        XCTAssertEqualObjects(labels[@"media_position"], @"1");
        return YES;
    }];
    
    [self.mediaPlayerController reset];
    
    [self waitForExpectationsWithTimeout:20. handler:nil];
}

- (void)testPlayPausePlay
{
    __block NSInteger count1 = 0;
    id eventObserver1 = [[NSNotificationCenter defaultCenter] addObserverForPlayerSingleHiddenEventNotificationUsingBlock:^(NSString * _Nonnull event, NSDictionary * _Nonnull labels) {
        ++count1;
    }];
    
    [self expectationForPlayerSingleHiddenEventNotificationWithHandler:^BOOL(NSString *event, NSDictionary *labels) {
        return [event isEqualToString:@"play"];
    }];
    
    [self.mediaPlayerController playURL:OnDemandTestURL()];
    
    [self waitForExpectationsWithTimeout:30. handler:^(NSError * _Nullable error) {
        [[NSNotificationCenter defaultCenter] removeObserver:eventObserver1];
    }];
    
    // One event expected: play
    XCTAssertEqual(count1, 1);
    
    __block NSInteger count2 = 0;
    id eventObserver2 = [[NSNotificationCenter defaultCenter] addObserverForPlayerSingleHiddenEventNotificationUsingBlock:^(NSString * _Nonnull event, NSDictionary * _Nonnull labels) {
        ++count2;
    }];
    
    [self expectationForPlayerSingleHiddenEventNotificationWithHandler:^BOOL(NSString *event, NSDictionary *labels) {
        return [event isEqualToString:@"pause"];
    }];
    
    [self.mediaPlayerController pause];
    
    [self waitForExpectationsWithTimeout:30. handler:^(NSError * _Nullable error) {
        [[NSNotificationCenter defaultCenter] removeObserver:eventObserver2];
    }];
    
    // One event expected: pause
    XCTAssertEqual(count2, 1);
    
    __block NSInteger count3 = 0;
    id eventObserver3 = [[NSNotificationCenter defaultCenter] addObserverForPlayerSingleHiddenEventNotificationUsingBlock:^(NSString * _Nonnull event, NSDictionary * _Nonnull labels) {
        ++count3;
    }];
    
    [self expectationForPlayerSingleHiddenEventNotificationWithHandler:^BOOL(NSString *event, NSDictionary *labels) {
        return [event isEqualToString:@"play"];
    }];
    
    [self.mediaPlayerController play];
    
    [self waitForExpectationsWithTimeout:30. handler:^(NSError * _Nullable error) {
        [[NSNotificationCenter defaultCenter] removeObserver:eventObserver3];
    }];
    
    [self expectationForElapsedTimeInterval:3. withHandler:nil];
    
    id eventObserver4 = [[NSNotificationCenter defaultCenter] addObserverForPlayerSingleHiddenEventNotificationUsingBlock:^(NSString * _Nonnull event, NSDictionary * _Nonnull labels) {
        // Also see http://stackoverflow.com/questions/14565405/avplayer-pauses-for-no-obvious-reason and
        // the demo project https://github.com/defagos/radars/tree/master/unexpected-player-rate-changes
        NSLog(@"[AVPlayer probable bug]: Unexpected state change to %@. Fast play - pause sequences can induce unexpected rate changes "
              "captured via KVO in our implementation. Those changes do not harm but cannot be tested reliably", @(self.mediaPlayerController.playbackState));
    }];
    
    [self waitForExpectationsWithTimeout:30. handler:^(NSError * _Nullable error) {
        [[NSNotificationCenter defaultCenter] removeObserver:eventObserver4];
    }];
}

- (void)testPlaySeekPlay
{
    __block NSInteger count1 = 0;
    id eventObserver1 = [[NSNotificationCenter defaultCenter] addObserverForPlayerSingleHiddenEventNotificationUsingBlock:^(NSString * _Nonnull event, NSDictionary * _Nonnull labels) {
        ++count1;
    }];
    
    [self expectationForPlayerSingleHiddenEventNotificationWithHandler:^BOOL(NSString *event, NSDictionary *labels) {
        return [event isEqualToString:@"play"];
    }];
    
    [self.mediaPlayerController playURL:OnDemandTestURL()];
    
    [self waitForExpectationsWithTimeout:30. handler:^(NSError * _Nullable error) {
        [[NSNotificationCenter defaultCenter] removeObserver:eventObserver1];
    }];
    
    // One event expected: play
    XCTAssertEqual(count1, 1);
    
    __block NSInteger count2 = 0;
    id eventObserver2 = [[NSNotificationCenter defaultCenter] addObserverForPlayerSingleHiddenEventNotificationUsingBlock:^(NSString * _Nonnull event, NSDictionary * _Nonnull labels) {
        ++count2;
    }];
    
    // Expect seek - play transition with labels
    
    __block BOOL seekReceived = NO;
    __block BOOL playReceived = NO;
    
    [self expectationForPlayerSingleHiddenEventNotificationWithHandler:^BOOL(NSString *event, NSDictionary *labels) {
        if ([event isEqualToString:@"seek"]) {
            XCTAssertFalse(seekReceived);
            XCTAssertFalse(playReceived);
            
            XCTAssertEqualObjects(labels[@"media_position"], @"0");
            seekReceived = YES;
        }
        else if ([event isEqualToString:@"play"]) {
            XCTAssertTrue(seekReceived);
            XCTAssertFalse(playReceived);
            
            XCTAssertEqualObjects(labels[@"media_position"], @"2");
            playReceived = YES;
        }
        else {
            XCTFail(@"Unexpected event %@", event);
        }
        
        return seekReceived && playReceived;
    }];
    
    [self.mediaPlayerController seekPreciselyToTime:CMTimeMakeWithSeconds(2., NSEC_PER_SEC) withCompletionHandler:nil];
    
    [self waitForExpectationsWithTimeout:30. handler:^(NSError * _Nullable error) {
        [[NSNotificationCenter defaultCenter] removeObserver:eventObserver2];
    }];
    
    // Two events expected: seek and play
    XCTAssertEqual(count2, 2);
    
    [self expectationForElapsedTimeInterval:3. withHandler:nil];
    
    id eventObserver4 = [[NSNotificationCenter defaultCenter] addObserverForPlayerSingleHiddenEventNotificationUsingBlock:^(NSString * _Nonnull event, NSDictionary * _Nonnull labels) {
        // Also see http://stackoverflow.com/questions/14565405/avplayer-pauses-for-no-obvious-reason and
        // the demo project https://github.com/defagos/radars/tree/master/unexpected-player-rate-changes
        NSLog(@"[AVPlayer probable bug]: Unexpected state change to %@. Fast play - pause sequences can induce unexpected rate changes "
              "captured via KVO in our implementation. Those changes do not harm but cannot be tested reliably", @(self.mediaPlayerController.playbackState));
    }];
    
    [self waitForExpectationsWithTimeout:30. handler:^(NSError * _Nullable error) {
        [[NSNotificationCenter defaultCenter] removeObserver:eventObserver4];
    }];
}

- (void)testPlayPauseSeekPause
{
    __block NSInteger count1 = 0;
    id eventObserver1 = [[NSNotificationCenter defaultCenter] addObserverForPlayerSingleHiddenEventNotificationUsingBlock:^(NSString * _Nonnull event, NSDictionary * _Nonnull labels) {
        ++count1;
    }];
    
    [self expectationForPlayerSingleHiddenEventNotificationWithHandler:^BOOL(NSString *event, NSDictionary *labels) {
        return [event isEqualToString:@"play"];
    }];
    
    [self.mediaPlayerController playURL:OnDemandTestURL()];
    
    [self waitForExpectationsWithTimeout:30. handler:^(NSError * _Nullable error) {
        [[NSNotificationCenter defaultCenter] removeObserver:eventObserver1];
    }];
    
    // One event expected: play
    XCTAssertEqual(count1, 1);
    
    __block NSInteger count2 = 0;
    id eventObserver2 = [[NSNotificationCenter defaultCenter] addObserverForPlayerSingleHiddenEventNotificationUsingBlock:^(NSString * _Nonnull event, NSDictionary * _Nonnull labels) {
        ++count2;
    }];
    
    [self expectationForPlayerSingleHiddenEventNotificationWithHandler:^BOOL(NSString *event, NSDictionary *labels) {
        return [event isEqualToString:@"pause"];
    }];
    
    [self.mediaPlayerController pause];
    
    [self waitForExpectationsWithTimeout:30. handler:^(NSError * _Nullable error) {
        [[NSNotificationCenter defaultCenter] removeObserver:eventObserver2];
    }];
    
    // One event expected: pause
    XCTAssertEqual(count2, 1);
    
    __block NSInteger count3 = 0;
    id eventObserver3 = [[NSNotificationCenter defaultCenter] addObserverForPlayerSingleHiddenEventNotificationUsingBlock:^(NSString * _Nonnull event, NSDictionary * _Nonnull labels) {
        ++count3;
    }];
    
    // Expect seek - pause transition with labels
    
    __block BOOL seekReceived = NO;
    __block BOOL pauseReceived = NO;
    
    [self expectationForPlayerSingleHiddenEventNotificationWithHandler:^BOOL(NSString *event, NSDictionary *labels) {
        if ([event isEqualToString:@"seek"]) {
            XCTAssertFalse(seekReceived);
            XCTAssertFalse(pauseReceived);
            
            XCTAssertEqualObjects(labels[@"media_position"], @"0");
            seekReceived = YES;
        }
        else if ([event isEqualToString:@"pause"]) {
            XCTAssertTrue(seekReceived);
            XCTAssertFalse(pauseReceived);
            XCTAssertEqualObjects(labels[@"media_position"], @"2");
            pauseReceived = YES;
        }
        else {
            XCTFail(@"Unexpected event %@", event);
        }
        
        return seekReceived && pauseReceived;
    }];
    
    [self.mediaPlayerController seekPreciselyToTime:CMTimeMakeWithSeconds(2., NSEC_PER_SEC) withCompletionHandler:nil];
    
    [self waitForExpectationsWithTimeout:30. handler:^(NSError * _Nullable error) {
        [[NSNotificationCenter defaultCenter] removeObserver:eventObserver3];
    }];
    
    // Two events expected: seek and pause
    XCTAssertEqual(count3, 2);
    
    [self expectationForElapsedTimeInterval:3. withHandler:nil];
    
    id eventObserver5 = [[NSNotificationCenter defaultCenter] addObserverForPlayerSingleHiddenEventNotificationUsingBlock:^(NSString * _Nonnull event, NSDictionary * _Nonnull labels) {
        // Also see http://stackoverflow.com/questions/14565405/avplayer-pauses-for-no-obvious-reason and
        // the demo project https://github.com/defagos/radars/tree/master/unexpected-player-rate-changes
        NSLog(@"[AVPlayer probable bug]: Unexpected state change to %@. Fast play - pause sequences can induce unexpected rate changes "
              "captured via KVO in our implementation. Those changes do not harm but cannot be tested reliably", @(self.mediaPlayerController.playbackState));
    }];
    
    [self waitForExpectationsWithTimeout:30. handler:^(NSError * _Nullable error) {
        [[NSNotificationCenter defaultCenter] removeObserver:eventObserver5];
    }];
}

- (void)testConsecutiveMedia
{
    [self expectationForPlayerSingleHiddenEventNotificationWithHandler:^BOOL(NSString *event, NSDictionary *labels) {
        XCTAssertEqualObjects(labels[@"event_id"], @"play");
        return YES;
    }];
    
    [self.mediaPlayerController playURL:OnDemandTestURL()];
    
    [self waitForExpectationsWithTimeout:20. handler:nil];
    
    [self expectationForPlayerSingleHiddenEventNotificationWithHandler:^BOOL(NSString *event, NSDictionary *labels) {
        XCTAssertEqualObjects(labels[@"event_id"], @"stop");
        return YES;
    }];
    
    [self.mediaPlayerController playURL:LiveTestURL()];
    
    [self waitForExpectationsWithTimeout:20. handler:nil];
    
    [self expectationForPlayerSingleHiddenEventNotificationWithHandler:^BOOL(NSString *event, NSDictionary *labels) {
        XCTAssertEqualObjects(labels[@"event_id"], @"play");
        return YES;
    }];
    
    [self waitForExpectationsWithTimeout:20. handler:nil];
    
    [self expectationForPlayerSingleHiddenEventNotificationWithHandler:^BOOL(NSString *event, NSDictionary *labels) {
        XCTAssertEqualObjects(labels[@"event_id"], @"stop");
        return YES;
    }];
    
    [self.mediaPlayerController reset];
    
    [self waitForExpectationsWithTimeout:20. handler:nil];
}

- (void)testMediaError
{
    id eventObserver = [[NSNotificationCenter defaultCenter] addObserverForPlayerSingleHiddenEventNotificationUsingBlock:^(NSString * _Nonnull event, NSDictionary * _Nonnull labels) {
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
    [self expectationForPlayerSingleHiddenEventNotificationWithHandler:^BOOL(NSString *event, NSDictionary *labels) {
        XCTAssertEqualObjects(labels[@"event_id"], @"play");
        XCTAssertEqualObjects(labels[@"media_player_display"], @"SRGMediaPlayer");
        XCTAssertEqualObjects(labels[@"media_player_version"], SRGMediaPlayerMarketingVersion());
        return YES;
    }];
    
    [self.mediaPlayerController playURL:OnDemandTestURL()];
    
    [self waitForExpectationsWithTimeout:20. handler:nil];
}

- (void)testOnDemandLabels
{
    [self expectationForPlayerSingleHiddenEventNotificationWithHandler:^BOOL(NSString *event, NSDictionary *labels) {
        XCTAssertEqualObjects(labels[@"event_id"], @"play");
        XCTAssertNil(labels[@"media_timeshift"]);
        XCTAssertNotNil(labels[@"media_bandwidth"]);
        XCTAssertNotNil(labels[@"media_volume"]);
        XCTAssertEqualObjects(labels[@"media_subtitles_on"], @"true");
        XCTAssertEqualObjects(labels[@"media_embedding_environment"], @"preprod");
        return YES;
    }];
    
    [self.mediaPlayerController playURL:OnDemandTestURL()];
    
    [self waitForExpectationsWithTimeout:20. handler:nil];
    
    [self expectationForPlayerSingleHiddenEventNotificationWithHandler:^BOOL(NSString *event, NSDictionary *labels) {
        XCTAssertEqualObjects(labels[@"event_id"], @"pause");
        XCTAssertNil(labels[@"media_timeshift"]);
        XCTAssertNotNil(labels[@"media_bandwidth"]);
        XCTAssertNotNil(labels[@"media_volume"]);
        XCTAssertEqualObjects(labels[@"media_subtitles_on"], @"true");
        XCTAssertEqualObjects(labels[@"media_embedding_environment"], @"preprod");
        return YES;
    }];
    
    [self.mediaPlayerController pause];
    
    [self waitForExpectationsWithTimeout:20. handler:nil];
    
    [self expectationForPlayerSingleHiddenEventNotificationWithHandler:^BOOL(NSString *event, NSDictionary *labels) {
        XCTAssertEqualObjects(labels[@"event_id"], @"stop");
        XCTAssertNil(labels[@"media_timeshift"]);
        XCTAssertNil(labels[@"media_bandwidth"]);
        XCTAssertNil(labels[@"media_volume"]);
        XCTAssertEqualObjects(labels[@"media_subtitles_on"], @"false");
        XCTAssertEqualObjects(labels[@"media_embedding_environment"], @"preprod");
        return YES;
    }];
    
    [self.mediaPlayerController reset];
    
    [self waitForExpectationsWithTimeout:20. handler:nil];
}

- (void)testLiveLabels
{
    [self expectationForPlayerSingleHiddenEventNotificationWithHandler:^BOOL(NSString *event, NSDictionary *labels) {
        XCTAssertEqualObjects(labels[@"event_id"], @"play");
        XCTAssertEqualObjects(labels[@"media_timeshift"], @"0");
        XCTAssertNotNil(labels[@"media_bandwidth"]);
        XCTAssertNotNil(labels[@"media_volume"]);
        XCTAssertEqualObjects(labels[@"media_subtitles_on"], @"false");
        XCTAssertEqualObjects(labels[@"media_embedding_environment"], @"preprod");
        return YES;
    }];
    
    SRGAnalyticsPlayerLabels *labels = [[SRGAnalyticsPlayerLabels alloc] init];
    labels.customInfo = @{ @"test_info" : @"test" };
    
    [self.mediaPlayerController playURL:LiveTestURL()
                                 atTime:kCMTimeZero
                           withSegments:nil
                        analyticsLabels:labels
                               userInfo:nil];
    
    [self waitForExpectationsWithTimeout:20. handler:nil];
    
    [self expectationForPlayerSingleHiddenEventNotificationWithHandler:^BOOL(NSString *event, NSDictionary *labels) {
        XCTAssertEqualObjects(labels[@"event_id"], @"pause");
        XCTAssertEqualObjects(labels[@"media_timeshift"], @"0");
        XCTAssertNotNil(labels[@"media_bandwidth"]);
        XCTAssertNotNil(labels[@"media_volume"]);
        XCTAssertEqualObjects(labels[@"media_subtitles_on"], @"false");
        XCTAssertEqualObjects(labels[@"media_embedding_environment"], @"preprod");
        return YES;
    }];
    
    [self.mediaPlayerController pause];
    
    [self waitForExpectationsWithTimeout:20. handler:nil];
    
    [self expectationForPlayerSingleHiddenEventNotificationWithHandler:^BOOL(NSString *event, NSDictionary *labels) {
        XCTAssertEqualObjects(labels[@"event_id"], @"stop");
        XCTAssertNil(labels[@"media_timeshift"]);
        XCTAssertNil(labels[@"media_bandwidth"]);
        XCTAssertNil(labels[@"media_volume"]);
        XCTAssertEqualObjects(labels[@"media_subtitles_on"], @"false");
        XCTAssertEqualObjects(labels[@"media_embedding_environment"], @"preprod");
        return YES;
    }];
    
    [self.mediaPlayerController reset];
    
    [self waitForExpectationsWithTimeout:20. handler:nil];
}

- (void)testDVRLabels
{
    [self expectationForPlayerSingleHiddenEventNotificationWithHandler:^BOOL(NSString *event, NSDictionary *labels) {
        XCTAssertEqualObjects(labels[@"event_id"], @"play");
        XCTAssertEqualObjects(labels[@"media_timeshift"], @"0");
        XCTAssertNotNil(labels[@"media_bandwidth"]);
        XCTAssertNotNil(labels[@"media_volume"]);
        XCTAssertEqualObjects(labels[@"media_subtitles_on"], @"false");
        XCTAssertEqualObjects(labels[@"media_embedding_environment"], @"preprod");
        return YES;
    }];
    
    [self.mediaPlayerController playURL:DVRTestURL()];
    
    [self waitForExpectationsWithTimeout:20. handler:nil];
    
    [self expectationForPlayerSingleHiddenEventNotificationWithHandler:^BOOL(NSString *event, NSDictionary *labels) {
        XCTAssertEqualObjects(labels[@"event_id"], @"seek");
        XCTAssertEqualObjects(labels[@"media_timeshift"], @"0");
        XCTAssertNotNil(labels[@"media_bandwidth"]);
        XCTAssertNotNil(labels[@"media_volume"]);
        XCTAssertEqualObjects(labels[@"media_subtitles_on"], @"false");
        XCTAssertEqualObjects(labels[@"media_embedding_environment"], @"preprod");
        return YES;
    }];
    
    // Live tolerance has been set to 10 for tests, duration of the DVR window for the test stream is about 45 seconds
    CMTime pastTime = CMTimeSubtract(CMTimeRangeGetEnd(self.mediaPlayerController.timeRange), CMTimeMakeWithSeconds(20., NSEC_PER_SEC));
    [self.mediaPlayerController seekPreciselyToTime:pastTime withCompletionHandler:nil];
    
    [self waitForExpectationsWithTimeout:20. handler:nil];
    
    [self expectationForPlayerSingleHiddenEventNotificationWithHandler:^BOOL(NSString *event, NSDictionary *labels) {
        XCTAssertEqualObjects(labels[@"event_id"], @"play");
        XCTAssertNotNil(labels[@"media_timeshift"]);
        XCTAssertEqualObjects(labels[@"media_timeshift"], @"20");
        XCTAssertNotNil(labels[@"media_bandwidth"]);
        XCTAssertNotNil(labels[@"media_volume"]);
        XCTAssertEqualObjects(labels[@"media_subtitles_on"], @"false");
        XCTAssertEqualObjects(labels[@"media_embedding_environment"], @"preprod");
        return YES;
    }];
    [self waitForExpectationsWithTimeout:20. handler:nil];
    
    [self expectationForPlayerSingleHiddenEventNotificationWithHandler:^BOOL(NSString *event, NSDictionary *labels) {
        XCTAssertEqualObjects(labels[@"event_id"], @"stop");
        XCTAssertNil(labels[@"media_timeshift"]);
        XCTAssertNil(labels[@"media_bandwidth"]);
        XCTAssertNil(labels[@"media_volume"]);
        XCTAssertEqualObjects(labels[@"media_embedding_environment"], @"preprod");
        return YES;
    }];
    
    [self.mediaPlayerController reset];
    
    [self waitForExpectationsWithTimeout:20. handler:nil];
}

- (void)testVolumeLabel
{
    [self expectationForPlayerSingleHiddenEventNotificationWithHandler:^BOOL(NSString *event, NSDictionary *labels) {
        XCTAssertEqualObjects(labels[@"event_id"], @"play");
        XCTAssertEqualObjects(labels[@"media_volume"], @"0");
        return YES;
    }];
    
    self.mediaPlayerController.playerCreationBlock = ^(AVPlayer *player) {
        player.muted = YES;
    };
    [self.mediaPlayerController playURL:OnDemandTestURL()];
    
    [self waitForExpectationsWithTimeout:20. handler:nil];
    
    [self expectationForPlayerSingleHiddenEventNotificationWithHandler:^BOOL(NSString *event, NSDictionary *labels) {
        XCTAssertEqualObjects(labels[@"event_id"], @"pause");
        XCTAssertNotEqualObjects(labels[@"media_volume"], @"0");
        return YES;
    }];
    
    self.mediaPlayerController.player.muted = NO;
    [self.mediaPlayerController pause];
    
    [self waitForExpectationsWithTimeout:20. handler:nil];
}

- (void)testNonSelectedSegmentPlayback
{
    [self expectationForPlayerSingleHiddenEventNotificationWithHandler:^BOOL(NSString *event, NSDictionary *labels) {
        XCTAssertEqualObjects(labels[@"event_id"], @"play");
        XCTAssertEqualObjects(labels[@"stream_name"], @"full");
        XCTAssertNil(labels[@"segment_name"]);
        XCTAssertEqualObjects(labels[@"overridable_name"], @"full");
        return YES;
    }];
    
    SRGAnalyticsPlayerLabels *labels = [[SRGAnalyticsPlayerLabels alloc] init];
    labels.customInfo = @{ @"stream_name" : @"full",
                           @"overridable_name" : @"full" };
    
    Segment *segment = [Segment segmentWithName:@"segment" timeRange:CMTimeRangeMake(CMTimeMakeWithSeconds(2., NSEC_PER_SEC), CMTimeMakeWithSeconds(3., NSEC_PER_SEC))];
    [self.mediaPlayerController playURL:OnDemandTestURL()
                                 atTime:kCMTimeZero
                           withSegments:@[segment]
                        analyticsLabels:labels
                               userInfo:nil];
    
    [self waitForExpectationsWithTimeout:20. handler:nil];
    
    // Let the segment be played through. No events must be received
    id eventObserver = [[NSNotificationCenter defaultCenter] addObserverForPlayerSingleHiddenEventNotificationUsingBlock:^(NSString * _Nonnull event, NSDictionary * _Nonnull labels) {
        XCTFail(@"No event must be received");
    }];
    
    [self expectationForElapsedTimeInterval:3. withHandler:nil];
    
    [self waitForExpectationsWithTimeout:20. handler:^(NSError * _Nullable error) {
        [[NSNotificationCenter defaultCenter] removeObserver:eventObserver];
    }];
    
    // Pause playback. Expect full-length information
    [self expectationForPlayerSingleHiddenEventNotificationWithHandler:^BOOL(NSString *event, NSDictionary *labels) {
        XCTAssertEqualObjects(labels[@"event_id"], @"pause");
        XCTAssertEqualObjects(labels[@"stream_name"], @"full");
        XCTAssertNil(labels[@"segment_name"]);
        XCTAssertEqualObjects(labels[@"overridable_name"], @"full");
        return YES;
    }];
    
    [self.mediaPlayerController pause];
    
    [self waitForExpectationsWithTimeout:20. handler:nil];
    
    // Resume playback. Expect full-length information
    [self expectationForPlayerSingleHiddenEventNotificationWithHandler:^BOOL(NSString *event, NSDictionary *labels) {
        XCTAssertEqualObjects(labels[@"event_id"], @"play");
        XCTAssertEqualObjects(labels[@"stream_name"], @"full");
        XCTAssertNil(labels[@"segment_name"]);
        XCTAssertEqualObjects(labels[@"overridable_name"], @"full");
        return YES;
    }];
    
    [self.mediaPlayerController play];
    
    [self waitForExpectationsWithTimeout:20. handler:nil];
    
    id eventObserver2 = [[NSNotificationCenter defaultCenter] addObserverForPlayerSingleHiddenEventNotificationUsingBlock:^(NSString * _Nonnull event, NSDictionary * _Nonnull labels) {
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
    [self expectationForPlayerSingleHiddenEventNotificationWithHandler:^BOOL(NSString *event, NSDictionary *labels) {
        XCTAssertEqualObjects(labels[@"event_id"], @"play");
        XCTAssertEqualObjects(labels[@"stream_name"], @"full");
        XCTAssertEqualObjects(labels[@"segment_name"], @"segment");
        XCTAssertEqualObjects(labels[@"overridable_name"], @"segment");
        XCTAssertEqualObjects(labels[@"media_position"], @"2");
        return YES;
    }];
    
    SRGAnalyticsPlayerLabels *labels = [[SRGAnalyticsPlayerLabels alloc] init];
    labels.customInfo = @{ @"stream_name" : @"full",
                           @"overridable_name" : @"full" };
    
    Segment *segment = [Segment segmentWithName:@"segment" timeRange:CMTimeRangeMake(CMTimeMakeWithSeconds(2., NSEC_PER_SEC), CMTimeMakeWithSeconds(10., NSEC_PER_SEC))];
    [self.mediaPlayerController playURL:OnDemandTestURL()
                                atIndex:0
                             inSegments:@[segment]
                    withAnalyticsLabels:labels
                               userInfo:nil];
    
    [self waitForExpectationsWithTimeout:20. handler:nil];
    
    // Pause playback. Expect segment information
    [self expectationForPlayerSingleHiddenEventNotificationWithHandler:^BOOL(NSString *event, NSDictionary *labels) {
        XCTAssertEqualObjects(labels[@"event_id"], @"pause");
        XCTAssertEqualObjects(labels[@"stream_name"], @"full");
        XCTAssertEqualObjects(labels[@"segment_name"], @"segment");
        XCTAssertEqualObjects(labels[@"overridable_name"], @"segment");
        XCTAssertEqualObjects(labels[@"media_position"], @"2");
        return YES;
    }];
    
    [self.mediaPlayerController pause];
    
    [self waitForExpectationsWithTimeout:20. handler:nil];
    
    // Resume playback. Expect segment information
    [self expectationForPlayerSingleHiddenEventNotificationWithHandler:^BOOL(NSString *event, NSDictionary *labels) {
        XCTAssertEqualObjects(labels[@"event_id"], @"play");
        XCTAssertEqualObjects(labels[@"stream_name"], @"full");
        XCTAssertEqualObjects(labels[@"segment_name"], @"segment");
        XCTAssertEqualObjects(labels[@"overridable_name"], @"segment");
        XCTAssertEqualObjects(labels[@"media_position"], @"2");
        return YES;
    }];
    
    [self.mediaPlayerController play];
    
    [self waitForExpectationsWithTimeout:20. handler:nil];
}

- (void)testInitialSegmentSelectionAndPlaythrough
{
    // No end on full since we start with the segment, only a play for the segment
    [self expectationForPlayerSingleHiddenEventNotificationWithHandler:^BOOL(NSString *event, NSDictionary *labels) {
        XCTAssertEqualObjects(labels[@"event_id"], @"play");
        XCTAssertEqualObjects(labels[@"stream_name"], @"full");
        XCTAssertEqualObjects(labels[@"segment_name"], @"segment");
        XCTAssertEqualObjects(labels[@"overridable_name"], @"segment");
        XCTAssertEqualObjects(labels[@"media_position"], @"50");
        return YES;
    }];
    
    SRGAnalyticsPlayerLabels *labels = [[SRGAnalyticsPlayerLabels alloc] init];
    labels.customInfo = @{ @"stream_name" : @"full",
                           @"overridable_name" : @"full" };
    
    Segment *segment = [Segment segmentWithName:@"segment" timeRange:CMTimeRangeMake(CMTimeMakeWithSeconds(50., NSEC_PER_SEC), CMTimeMakeWithSeconds(3., NSEC_PER_SEC))];
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
    
    [self expectationForPlayerSingleHiddenEventNotificationWithHandler:^BOOL(NSString *event, NSDictionary *labels) {
        if ([event isEqualToString:@"eof"]) {
            XCTAssertFalse(segmentEndReceived);
            XCTAssertFalse(fullPlayReceived);
            
            XCTAssertEqualObjects(labels[@"stream_name"], @"full");
            XCTAssertEqualObjects(labels[@"segment_name"], @"segment");
            XCTAssertEqualObjects(labels[@"overridable_name"], @"segment");
            XCTAssertEqualObjects(labels[@"media_position"], @"53");
            segmentEndReceived = YES;
        }
        else if ([event isEqualToString:@"play"]) {
            XCTAssertFalse(fullPlayReceived);
            
            XCTAssertEqualObjects(labels[@"stream_name"], @"full");
            XCTAssertNil(labels[@"segment_name"]);
            XCTAssertEqualObjects(labels[@"overridable_name"], @"full");
            XCTAssertEqualObjects(labels[@"media_position"], @"53");
            fullPlayReceived = YES;
        }
        else {
            XCTFail(@"Unexpected event %@", event);
        }
        
        return segmentEndReceived && fullPlayReceived;
    }];
    
    [self waitForExpectationsWithTimeout:20. handler:nil];
}

- (void)testPrepareInitialSegmentSelectionAndPlayAndReset
{
    // Prepare the player until it is paused. No event must be received
    id prepareObserver = [[NSNotificationCenter defaultCenter] addObserverForPlayerSingleHiddenEventNotificationUsingBlock:^(NSString * _Nonnull event, NSDictionary * _Nonnull labels) {
        XCTFail(@"No event must be received when preparing a player");
    }];
    
    
    SRGAnalyticsPlayerLabels *labels = [[SRGAnalyticsPlayerLabels alloc] init];
    labels.customInfo = @{ @"stream_name" : @"full",
                           @"overridable_name" : @"full" };
    
    Segment *segment = [Segment segmentWithName:@"segment" timeRange:CMTimeRangeMake(CMTimeMakeWithSeconds(50., NSEC_PER_SEC), CMTimeMakeWithSeconds(3., NSEC_PER_SEC))];
    [self.mediaPlayerController prepareToPlayURL:OnDemandTestURL()
                                         atIndex:0
                                      inSegments:@[segment]
                             withAnalyticsLabels:labels
                                        userInfo:nil
                               completionHandler:^{
                                   [[NSNotificationCenter defaultCenter] removeObserver:prepareObserver];
                               }];
    
    // Now playing must trigger a play event
    [self expectationForPlayerSingleHiddenEventNotificationWithHandler:^BOOL(NSString *event, NSDictionary *labels) {
        XCTAssertEqualObjects(labels[@"event_id"], @"play");
        XCTAssertEqualObjects(labels[@"stream_name"], @"full");
        XCTAssertEqualObjects(labels[@"segment_name"], @"segment");
        XCTAssertEqualObjects(labels[@"overridable_name"], @"segment");
        XCTAssertEqualObjects(labels[@"media_position"], @"50");
        return YES;
    }];
    
    [self.mediaPlayerController play];
    
    [self waitForExpectationsWithTimeout:20. handler:nil];
    
    [self expectationForPlayerSingleHiddenEventNotificationWithHandler:^BOOL(NSString *event, NSDictionary *labels) {
        XCTAssertEqualObjects(labels[@"event_id"], @"stop");
        XCTAssertEqualObjects(labels[@"stream_name"], @"full");
        XCTAssertEqualObjects(labels[@"segment_name"], @"segment");
        XCTAssertEqualObjects(labels[@"overridable_name"], @"segment");
        XCTAssertEqualObjects(labels[@"media_position"], @"50");
        return YES;
    }];
    
    [self.mediaPlayerController reset];
    
    [self waitForExpectationsWithTimeout:20. handler:nil];
}

- (void)testSegmentSelectionAfterStartOnFullLength
{
    [self expectationForPlayerSingleHiddenEventNotificationWithHandler:^BOOL(NSString *event, NSDictionary *labels) {
        XCTAssertEqualObjects(labels[@"event_id"], @"play");
        XCTAssertEqualObjects(labels[@"stream_name"], @"full");
        XCTAssertNil(labels[@"segment_name"]);
        XCTAssertEqualObjects(labels[@"overridable_name"], @"full");
        XCTAssertEqualObjects(labels[@"media_position"], @"0");
        return YES;
    }];
    
    SRGAnalyticsPlayerLabels *labels = [[SRGAnalyticsPlayerLabels alloc] init];
    labels.customInfo = @{ @"stream_name" : @"full",
                           @"overridable_name" : @"full" };
    
    Segment *segment = [Segment segmentWithName:@"segment" timeRange:CMTimeRangeMake(CMTimeMakeWithSeconds(50., NSEC_PER_SEC), CMTimeMakeWithSeconds(3., NSEC_PER_SEC))];
    [self.mediaPlayerController playURL:OnDemandTestURL()
                                 atTime:kCMTimeZero
                           withSegments:@[segment]
                        analyticsLabels:labels
                               userInfo:nil];
    
    [self waitForExpectationsWithTimeout:20. handler:nil];
    
    // Play for a while. No stream events must be received
    id eventObserver = [[NSNotificationCenter defaultCenter] addObserverForPlayerSingleHiddenEventNotificationUsingBlock:^(NSString * _Nonnull event, NSDictionary * _Nonnull labels) {
        XCTFail(@"No event must be received when playing");
    }];
    // Wait 1 second
    [self expectationForElapsedTimeInterval:1. withHandler:nil];
    [self waitForExpectationsWithTimeout:20. handler:^(NSError * _Nullable error) {
        [[NSNotificationCenter defaultCenter] removeObserver:eventObserver];
    }];
    
    // When selecting a segment, usual playback events due to seeking must be inhibited
    
    __block BOOL fullEndReceived = NO;
    __block BOOL segmentPlayReceived = NO;
    
    [self expectationForPlayerSingleHiddenEventNotificationWithHandler:^BOOL(NSString *event, NSDictionary *labels) {
        if ([event isEqualToString:@"stop"]) {
            XCTAssertFalse(fullEndReceived);
            XCTAssertFalse(segmentPlayReceived);
            
            XCTAssertEqualObjects(labels[@"stream_name"], @"full");
            XCTAssertNil(labels[@"segment_name"]);
            XCTAssertEqualObjects(labels[@"overridable_name"], @"full");
            XCTAssertEqualObjects(labels[@"media_position"], @"1");
            fullEndReceived = YES;
        }
        else if ([event isEqualToString:@"play"]) {
            XCTAssertFalse(segmentPlayReceived);
            
            XCTAssertEqualObjects(labels[@"stream_name"], @"full");
            XCTAssertEqualObjects(labels[@"segment_name"], @"segment");
            XCTAssertEqualObjects(labels[@"overridable_name"], @"segment");
            XCTAssertEqualObjects(labels[@"media_position"], @"50");
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
    [self expectationForPlayerSingleHiddenEventNotificationWithHandler:^BOOL(NSString *event, NSDictionary *labels) {
        XCTAssertEqualObjects(labels[@"event_id"], @"play");
        XCTAssertEqualObjects(labels[@"stream_name"], @"full");
        XCTAssertEqualObjects(labels[@"segment_name"], @"segment1");
        XCTAssertEqualObjects(labels[@"overridable_name"], @"segment1");
        XCTAssertEqualObjects(labels[@"media_position"], @"50");
        return YES;
    }];
    
    Segment *segment1 = [Segment segmentWithName:@"segment1" timeRange:CMTimeRangeMake(CMTimeMakeWithSeconds(50., NSEC_PER_SEC), CMTimeMakeWithSeconds(10., NSEC_PER_SEC))];
    Segment *segment2 = [Segment segmentWithName:@"segment2" timeRange:CMTimeRangeMake(CMTimeMakeWithSeconds(100., NSEC_PER_SEC), CMTimeMakeWithSeconds(10., NSEC_PER_SEC))];
    
    SRGAnalyticsPlayerLabels *labels = [[SRGAnalyticsPlayerLabels alloc] init];
    labels.customInfo = @{ @"stream_name" : @"full",
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
    
    [self expectationForPlayerSingleHiddenEventNotificationWithHandler:^BOOL(NSString *event, NSDictionary *labels) {
        if ([event isEqualToString:@"stop"]) {
            XCTAssertFalse(segment1EndReceived);
            XCTAssertFalse(segment2PlayReceived);
            
            XCTAssertEqualObjects(labels[@"stream_name"], @"full");
            XCTAssertEqualObjects(labels[@"segment_name"], @"segment1");
            XCTAssertEqualObjects(labels[@"overridable_name"], @"segment1");
            XCTAssertEqualObjects(labels[@"media_position"], @"50");
            segment1EndReceived = YES;
        }
        else if ([event isEqualToString:@"play"]) {
            XCTAssertFalse(segment2PlayReceived);
            
            XCTAssertEqualObjects(labels[@"stream_name"], @"full");
            XCTAssertEqualObjects(labels[@"segment_name"], @"segment2");
            XCTAssertEqualObjects(labels[@"overridable_name"], @"segment2");
            XCTAssertEqualObjects(labels[@"media_position"], @"100");
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
    [self expectationForPlayerSingleHiddenEventNotificationWithHandler:^BOOL(NSString *event, NSDictionary *labels) {
        XCTAssertEqualObjects(labels[@"event_id"], @"play");
        XCTAssertEqualObjects(labels[@"stream_name"], @"full");
        XCTAssertEqualObjects(labels[@"segment_name"], @"segment1");
        XCTAssertEqualObjects(labels[@"overridable_name"], @"segment1");
        XCTAssertEqualObjects(labels[@"media_position"], @"20");
        return YES;
    }];
    
    Segment *segment1 = [Segment segmentWithName:@"segment1" timeRange:CMTimeRangeMake(CMTimeMakeWithSeconds(20., NSEC_PER_SEC), CMTimeMakeWithSeconds(3., NSEC_PER_SEC))];
    Segment *segment2 = [Segment segmentWithName:@"segment2" timeRange:CMTimeRangeMake(CMTimeMakeWithSeconds(23., NSEC_PER_SEC), CMTimeMakeWithSeconds(3., NSEC_PER_SEC))];
    
    SRGAnalyticsPlayerLabels *labels = [[SRGAnalyticsPlayerLabels alloc] init];
    labels.customInfo = @{ @"stream_name" : @"full",
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
    
    [self expectationForPlayerSingleHiddenEventNotificationWithHandler:^BOOL(NSString *event, NSDictionary *labels) {
        if ([event isEqualToString:@"eof"]) {
            XCTAssertFalse(segment1EndReceived);
            XCTAssertFalse(fullLengthPlayReceived);
            
            XCTAssertEqualObjects(labels[@"stream_name"], @"full");
            XCTAssertEqualObjects(labels[@"segment_name"], @"segment1");
            XCTAssertEqualObjects(labels[@"overridable_name"], @"segment1");
            XCTAssertEqualObjects(labels[@"media_position"], @"23");
            segment1EndReceived = YES;
        }
        else if ([event isEqualToString:@"play"]) {
            XCTAssertFalse(fullLengthPlayReceived);
            
            XCTAssertEqualObjects(labels[@"stream_name"], @"full");
            XCTAssertNil(labels[@"segment_name"]);
            XCTAssertEqualObjects(labels[@"overridable_name"], @"full");
            XCTAssertEqualObjects(labels[@"media_position"], @"23");
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
    [self expectationForPlayerSingleHiddenEventNotificationWithHandler:^BOOL(NSString *event, NSDictionary *labels) {
        XCTAssertEqualObjects(labels[@"event_id"], @"play");
        XCTAssertEqualObjects(labels[@"stream_name"], @"full");
        XCTAssertEqualObjects(labels[@"segment_name"], @"segment");
        XCTAssertEqualObjects(labels[@"overridable_name"], @"segment");
        XCTAssertEqualObjects(labels[@"media_position"], @"50");
        return YES;
    }];
    
    Segment *segment = [Segment segmentWithName:@"segment" timeRange:CMTimeRangeMake(CMTimeMakeWithSeconds(50., NSEC_PER_SEC), CMTimeMakeWithSeconds(10., NSEC_PER_SEC))];
    
    SRGAnalyticsPlayerLabels *labels = [[SRGAnalyticsPlayerLabels alloc] init];
    labels.customInfo = @{ @"stream_name" : @"full",
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
    
    [self expectationForPlayerSingleHiddenEventNotificationWithHandler:^BOOL(NSString *event, NSDictionary *labels) {
        if ([event isEqualToString:@"stop"]) {
            XCTAssertFalse(segmentEndReceived);
            XCTAssertFalse(segmentPlayReceived);
            
            XCTAssertEqualObjects(labels[@"stream_name"], @"full");
            XCTAssertEqualObjects(labels[@"segment_name"], @"segment");
            XCTAssertEqualObjects(labels[@"overridable_name"], @"segment");
            XCTAssertEqualObjects(labels[@"media_position"], @"50");
            segmentEndReceived = YES;
        }
        else if ([event isEqualToString:@"play"]) {
            XCTAssertFalse(segmentPlayReceived);
            
            XCTAssertEqualObjects(labels[@"stream_name"], @"full");
            XCTAssertEqualObjects(labels[@"segment_name"], @"segment");
            XCTAssertEqualObjects(labels[@"overridable_name"], @"segment");
            XCTAssertEqualObjects(labels[@"media_position"], @"50");
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
    [self expectationForPlayerSingleHiddenEventNotificationWithHandler:^BOOL(NSString *event, NSDictionary *labels) {
        XCTAssertEqualObjects(labels[@"event_id"], @"play");
        XCTAssertEqualObjects(labels[@"stream_name"], @"full");
        XCTAssertEqualObjects(labels[@"segment_name"], @"segment1");
        XCTAssertEqualObjects(labels[@"overridable_name"], @"segment1");
        XCTAssertEqualObjects(labels[@"media_position"], @"50");
        return YES;
    }];
    
    Segment *segment1 = [Segment segmentWithName:@"segment1" timeRange:CMTimeRangeMake(CMTimeMakeWithSeconds(50., NSEC_PER_SEC), CMTimeMakeWithSeconds(10., NSEC_PER_SEC))];
    Segment *segment2 = [Segment segmentWithName:@"segment2" timeRange:CMTimeRangeMake(CMTimeMakeWithSeconds(60., NSEC_PER_SEC), CMTimeMakeWithSeconds(20., NSEC_PER_SEC))];
    
    SRGAnalyticsPlayerLabels *labels = [[SRGAnalyticsPlayerLabels alloc] init];
    labels.customInfo = @{ @"stream_name" : @"full",
                           @"overridable_name" : @"full" };
    
    [self.mediaPlayerController playURL:OnDemandTestURL()
                                atIndex:0
                             inSegments:@[segment1, segment2]
                    withAnalyticsLabels:labels
                               userInfo:nil];
    
    [self waitForExpectationsWithTimeout:20. handler:nil];
    
    // Expect transition into the full-length since, even if seeking resumes in another segment (since this segment has
    // not been selected, we don't want to track it)
    
    __block BOOL segment1SeekReceived = NO;
    __block BOOL segment1StopReceived = NO;
    __block BOOL fullLengthPlayReceived = NO;
    
    [self expectationForPlayerSingleHiddenEventNotificationWithHandler:^BOOL(NSString *event, NSDictionary *labels) {
        if ([event isEqualToString:@"seek"]) {
            XCTAssertFalse(segment1SeekReceived);
            XCTAssertFalse(segment1StopReceived);
            XCTAssertFalse(fullLengthPlayReceived);
            
            XCTAssertEqualObjects(labels[@"stream_name"], @"full");
            XCTAssertEqualObjects(labels[@"segment_name"], @"segment1");
            XCTAssertEqualObjects(labels[@"overridable_name"], @"segment1");
            XCTAssertEqualObjects(labels[@"media_position"], @"50");
            segment1SeekReceived = YES;
        }
        else if ([event isEqualToString:@"stop"]) {
            XCTAssertFalse(segment1StopReceived);
            XCTAssertFalse(fullLengthPlayReceived);
            
            XCTAssertEqualObjects(labels[@"stream_name"], @"full");
            XCTAssertEqualObjects(labels[@"segment_name"], @"segment1");
            XCTAssertEqualObjects(labels[@"overridable_name"], @"segment1");
            XCTAssertEqualObjects(labels[@"media_position"], @"50");
            segment1StopReceived = YES;
        }
        else if ([event isEqualToString:@"play"]) {
            XCTAssertFalse(fullLengthPlayReceived);
            
            XCTAssertEqualObjects(labels[@"stream_name"], @"full");
            XCTAssertNil(labels[@"segment_name"]);
            XCTAssertEqualObjects(labels[@"overridable_name"], @"full");
            XCTAssertEqualObjects(labels[@"media_position"], @"70");
            fullLengthPlayReceived = YES;
        }
        
        return segment1SeekReceived && segment1StopReceived && fullLengthPlayReceived;
    }];
    
    [self.mediaPlayerController seekPreciselyToTime:CMTimeAdd(CMTimeRangeGetEnd(segment1.srg_timeRange), CMTimeMakeWithSeconds(10., NSEC_PER_SEC)) withCompletionHandler:nil];
    
    [self waitForExpectationsWithTimeout:20. handler:nil];
}

- (void)testSeekWithinSelectedSegment
{
    [self expectationForPlayerSingleHiddenEventNotificationWithHandler:^BOOL(NSString *event, NSDictionary *labels) {
        XCTAssertEqualObjects(labels[@"event_id"], @"play");
        XCTAssertEqualObjects(labels[@"stream_name"], @"full");
        XCTAssertEqualObjects(labels[@"segment_name"], @"segment");
        XCTAssertEqualObjects(labels[@"overridable_name"], @"segment");
        XCTAssertEqualObjects(labels[@"media_position"], @"50");
        return YES;
    }];
    
    Segment *segment = [Segment segmentWithName:@"segment" timeRange:CMTimeRangeMake(CMTimeMakeWithSeconds(50., NSEC_PER_SEC), CMTimeMakeWithSeconds(10., NSEC_PER_SEC))];
    
    SRGAnalyticsPlayerLabels *labels = [[SRGAnalyticsPlayerLabels alloc] init];
    labels.customInfo = @{ @"stream_name" : @"full",
                           @"overridable_name" : @"full" };
    
    [self.mediaPlayerController playURL:OnDemandTestURL()
                                atIndex:0
                             inSegments:@[segment]
                    withAnalyticsLabels:labels
                               userInfo:nil];
    
    [self waitForExpectationsWithTimeout:20. handler:nil];
    
    // Expect seek - play transition with segment labels
    
    __block BOOL segmentSeekReceived = NO;
    __block BOOL segmentPlayReceived = NO;
    
    [self expectationForPlayerSingleHiddenEventNotificationWithHandler:^BOOL(NSString *event, NSDictionary *labels) {
        if ([event isEqualToString:@"seek"]) {
            XCTAssertFalse(segmentSeekReceived);
            XCTAssertFalse(segmentPlayReceived);
            
            XCTAssertEqualObjects(labels[@"stream_name"], @"full");
            XCTAssertEqualObjects(labels[@"segment_name"], @"segment");
            XCTAssertEqualObjects(labels[@"overridable_name"], @"segment");
            XCTAssertEqualObjects(labels[@"media_position"], @"50");
            segmentSeekReceived = YES;
        }
        else if ([event isEqualToString:@"play"]) {
            XCTAssertFalse(segmentPlayReceived);
            
            XCTAssertEqualObjects(labels[@"stream_name"], @"full");
            XCTAssertEqualObjects(labels[@"segment_name"], @"segment");
            XCTAssertEqualObjects(labels[@"overridable_name"], @"segment");
            XCTAssertEqualObjects(labels[@"media_position"], @"53");
            segmentPlayReceived = YES;
        }
        else {
            XCTFail(@"Unexpected event %@", event);
        }
        
        return segmentSeekReceived && segmentPlayReceived;
    }];
    
    [self.mediaPlayerController seekPreciselyToTime:CMTimeAdd(segment.srg_timeRange.start, CMTimeMakeWithSeconds(3., NSEC_PER_SEC)) withCompletionHandler:nil];
    
    [self waitForExpectationsWithTimeout:20. handler:nil];
}

- (void)testSelectedSegmentAtStreamEnd
{
    // Precise timing information gathered from the stream itself
    Segment *segment = [Segment segmentWithName:@"segment" timeRange:CMTimeRangeMake(CMTimeMakeWithSeconds(1795.045, NSEC_PER_SEC), CMTimeMakeWithSeconds(5., NSEC_PER_SEC))];
    
    [self expectationForPlayerSingleHiddenEventNotificationWithHandler:^BOOL(NSString *event, NSDictionary *labels) {
        XCTAssertEqualObjects(labels[@"event_id"], @"play");
        XCTAssertEqualObjects(labels[@"stream_name"], @"full");
        XCTAssertEqualObjects(labels[@"segment_name"], @"segment");
        XCTAssertEqualObjects(labels[@"overridable_name"], @"segment");
        XCTAssertEqualObjects(labels[@"media_position"], @"1795");
        return YES;
    }];
    
    SRGAnalyticsPlayerLabels *labels = [[SRGAnalyticsPlayerLabels alloc] init];
    labels.customInfo = @{ @"stream_name" : @"full",
                           @"overridable_name" : @"full" };
    
    [self.mediaPlayerController playURL:OnDemandTestURL()
                                atIndex:0
                             inSegments:@[segment]
                    withAnalyticsLabels:labels
                               userInfo:nil];
    
    [self waitForExpectationsWithTimeout:20. handler:nil];
    
    XCTAssertEqualObjects(self.mediaPlayerController.currentSegment, segment);
    XCTAssertEqualObjects(self.mediaPlayerController.selectedSegment, segment);
    
    // Expect end of segment and play / eof for the full-length (which does not harm for statistics)
    
    __block BOOL segmentEofReceived = NO;
    __block BOOL fullLengthPlayReceived = NO;
    __block BOOL fullLengthEofReceived = NO;
    
    [self expectationForPlayerSingleHiddenEventNotificationWithHandler:^BOOL(NSString *event, NSDictionary *labels) {
        if ([event isEqualToString:@"eof"]) {
            if (! segmentEofReceived) {
                XCTAssertFalse(fullLengthPlayReceived);
                XCTAssertFalse(fullLengthEofReceived);
                
                XCTAssertEqualObjects(labels[@"stream_name"], @"full");
                XCTAssertEqualObjects(labels[@"segment_name"], @"segment");
                XCTAssertEqualObjects(labels[@"overridable_name"], @"segment");
                XCTAssertEqualObjects(labels[@"media_position"], @"1800");
                segmentEofReceived = YES;
            }
            else {
                XCTAssertFalse(fullLengthEofReceived);
                
                XCTAssertEqualObjects(labels[@"stream_name"], @"full");
                XCTAssertNil(labels[@"segment_name"]);
                XCTAssertEqualObjects(labels[@"overridable_name"], @"full");
                XCTAssertEqualObjects(labels[@"media_position"], @"1800");
                fullLengthEofReceived = YES;
            }
        }
        else if ([event isEqualToString:@"play"]) {
            XCTAssertFalse(fullLengthPlayReceived);
            XCTAssertFalse(fullLengthEofReceived);
            
            XCTAssertEqualObjects(labels[@"stream_name"], @"full");
            XCTAssertNil(labels[@"segment_name"]);
            XCTAssertEqualObjects(labels[@"overridable_name"], @"full");
            XCTAssertEqualObjects(labels[@"media_position"], @"1800");
            fullLengthPlayReceived = YES;
        }
        else {
            XCTFail(@"Unexpected event %@", event);
        }
        
        return segmentEofReceived && fullLengthPlayReceived && fullLengthEofReceived;
    }];
    
    [self waitForExpectationsWithTimeout:20. handler:nil];
    
    XCTAssertNil(self.mediaPlayerController.currentSegment);
    XCTAssertNil(self.mediaPlayerController.selectedSegment);
}

- (void)testResetWhilePlayingSegment
{
    [self expectationForPlayerSingleHiddenEventNotificationWithHandler:^BOOL(NSString *event, NSDictionary *labels) {
        XCTAssertEqualObjects(labels[@"event_id"], @"play");
        XCTAssertEqualObjects(labels[@"stream_name"], @"full");
        XCTAssertEqualObjects(labels[@"segment_name"], @"segment");
        XCTAssertEqualObjects(labels[@"overridable_name"], @"segment");
        XCTAssertEqualObjects(labels[@"media_position"], @"50");
        return YES;
    }];
    
    Segment *segment = [Segment segmentWithName:@"segment" timeRange:CMTimeRangeMake(CMTimeMakeWithSeconds(50., NSEC_PER_SEC), CMTimeMakeWithSeconds(10., NSEC_PER_SEC))];
    
    SRGAnalyticsPlayerLabels *labels = [[SRGAnalyticsPlayerLabels alloc] init];
    labels.customInfo = @{ @"stream_name" : @"full",
                           @"overridable_name" : @"full" };
    
    [self.mediaPlayerController playURL:OnDemandTestURL()
                                atIndex:0
                             inSegments:@[segment]
                    withAnalyticsLabels:labels
                               userInfo:nil];
    
    [self waitForExpectationsWithTimeout:20. handler:nil];
    
    // Play for a while. No stream events must be received
    id eventObserver = [[NSNotificationCenter defaultCenter] addObserverForPlayerSingleHiddenEventNotificationUsingBlock:^(NSString * _Nonnull event, NSDictionary * _Nonnull labels) {
        XCTFail(@"No event must be received when playing");
    }];
    // Wait 1 second
    [self expectationForElapsedTimeInterval:1. withHandler:nil];
    [self waitForExpectationsWithTimeout:20. handler:^(NSError * _Nullable error) {
        [[NSNotificationCenter defaultCenter] removeObserver:eventObserver];
    }];
    
    // Expect stop event with segment labels
    
    [self expectationForPlayerSingleHiddenEventNotificationWithHandler:^BOOL(NSString *event, NSDictionary *labels) {
        XCTAssertEqualObjects(labels[@"event_id"], @"stop");
        XCTAssertEqualObjects(labels[@"stream_name"], @"full");
        XCTAssertEqualObjects(labels[@"segment_name"], @"segment");
        XCTAssertEqualObjects(labels[@"overridable_name"], @"segment");
        XCTAssertEqualObjects(labels[@"media_position"], @"51");
        return YES;
    }];
    
    [self.mediaPlayerController reset];
    
    [self waitForExpectationsWithTimeout:20. handler:nil];
}

- (void)testBlockedSegmentSelection
{
    [self expectationForPlayerSingleHiddenEventNotificationWithHandler:^BOOL(NSString *event, NSDictionary *labels) {
        XCTAssertEqualObjects(labels[@"event_id"], @"play");
        XCTAssertEqualObjects(labels[@"stream_name"], @"full");
        XCTAssertNil(labels[@"segment_name"]);
        XCTAssertEqualObjects(labels[@"overridable_name"], @"full");
        return YES;
    }];
    
    SRGAnalyticsPlayerLabels *labels = [[SRGAnalyticsPlayerLabels alloc] init];
    labels.customInfo = @{ @"stream_name" : @"full",
                           @"overridable_name" : @"full" };
    
    Segment *segment = [Segment blockedSegmentWithName:@"segment" timeRange:CMTimeRangeMake(CMTimeMakeWithSeconds(50., NSEC_PER_SEC), CMTimeMakeWithSeconds(10., NSEC_PER_SEC))];
    [self.mediaPlayerController playURL:OnDemandTestURL()
                                 atTime:kCMTimeZero
                           withSegments:@[segment]
                        analyticsLabels:labels
                               userInfo:nil];
    
    [self waitForExpectationsWithTimeout:20. handler:nil];
    
    // Expect seek and play on the full-length (corresponding to the segment being skipped)
    
    __block BOOL fullLengthSeekReceived = NO;
    __block BOOL fullLengthPlayReceived = NO;
    
    [self expectationForPlayerSingleHiddenEventNotificationWithHandler:^BOOL(NSString *event, NSDictionary *labels) {
        if ([event isEqualToString:@"seek"]) {
            XCTAssertFalse(fullLengthSeekReceived);
            XCTAssertFalse(fullLengthPlayReceived);
            
            XCTAssertEqualObjects(labels[@"stream_name"], @"full");
            XCTAssertNil(labels[@"segment_name"]);
            XCTAssertEqualObjects(labels[@"overridable_name"], @"full");
            fullLengthSeekReceived = YES;
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
        
        return fullLengthSeekReceived && fullLengthPlayReceived;
    }];
    
    [self.mediaPlayerController seekToSegment:segment withCompletionHandler:nil];
    
    [self waitForExpectationsWithTimeout:20. handler:nil];
}

- (void)testSeekIntoBlockedSegment
{
    [self expectationForPlayerSingleHiddenEventNotificationWithHandler:^BOOL(NSString *event, NSDictionary *labels) {
        XCTAssertEqualObjects(labels[@"event_id"], @"play");
        XCTAssertEqualObjects(labels[@"stream_name"], @"full");
        XCTAssertNil(labels[@"segment_name"]);
        XCTAssertEqualObjects(labels[@"overridable_name"], @"full");
        return YES;
    }];
    
    Segment *segment = [Segment blockedSegmentWithName:@"segment" timeRange:CMTimeRangeMake(CMTimeMakeWithSeconds(50., NSEC_PER_SEC), CMTimeMakeWithSeconds(10., NSEC_PER_SEC))];
    
    SRGAnalyticsPlayerLabels *labels = [[SRGAnalyticsPlayerLabels alloc] init];
    labels.customInfo = @{ @"stream_name" : @"full",
                           @"overridable_name" : @"full" };
    
    [self.mediaPlayerController playURL:OnDemandTestURL()
                                 atTime:kCMTimeZero
                           withSegments:@[segment]
                        analyticsLabels:labels
                               userInfo:nil];
    
    [self waitForExpectationsWithTimeout:20. handler:nil];
    
    // Expect seek / play for the full-length
    
    __block BOOL fullLengthSeekReceived = NO;
    __block BOOL fullLengthPlayReceived = NO;
    
    [self expectationForPlayerSingleHiddenEventNotificationWithHandler:^BOOL(NSString *event, NSDictionary *labels) {
        if ([event isEqualToString:@"seek"]) {
            XCTAssertFalse(fullLengthSeekReceived);
            XCTAssertFalse(fullLengthPlayReceived);
            
            XCTAssertEqualObjects(labels[@"stream_name"], @"full");
            XCTAssertNil(labels[@"segment_name"]);
            XCTAssertEqualObjects(labels[@"overridable_name"], @"full");
            fullLengthSeekReceived = YES;
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
        
        return fullLengthSeekReceived && fullLengthPlayReceived;
    }];
    
    [self.mediaPlayerController seekPreciselyToTime:CMTimeMakeWithSeconds(55., NSEC_PER_SEC) withCompletionHandler:nil];
    
    [self waitForExpectationsWithTimeout:20. handler:nil];
}

- (void)testPlayStartingWithBlockedSegment
{
    [self expectationForPlayerSingleHiddenEventNotificationWithHandler:^BOOL(NSString *event, NSDictionary *labels) {
        XCTAssertEqualObjects(labels[@"event_id"], @"play");
        XCTAssertEqualObjects(labels[@"stream_name"], @"full");
        XCTAssertNil(labels[@"segment_name"]);
        XCTAssertEqualObjects(labels[@"overridable_name"], @"full");
        return YES;
    }];
    
    SRGAnalyticsPlayerLabels *labels = [[SRGAnalyticsPlayerLabels alloc] init];
    labels.customInfo = @{ @"stream_name" : @"full",
                           @"overridable_name" : @"full" };
    
    Segment *segment = [Segment blockedSegmentWithName:@"segment" timeRange:CMTimeRangeMake(CMTimeMakeWithSeconds(50., NSEC_PER_SEC), CMTimeMakeWithSeconds(10., NSEC_PER_SEC))];
    [self.mediaPlayerController playURL:OnDemandTestURL()
                                atIndex:0
                             inSegments:@[segment]
                    withAnalyticsLabels:labels
                               userInfo:nil];
    
    [self waitForExpectationsWithTimeout:20. handler:nil];
    
    // Expect pause / play for the full-length
    
    __block BOOL fullLengthSeekReceived = NO;
    __block BOOL fullLengthPlayReceived = NO;
    
    [self expectationForPlayerSingleHiddenEventNotificationWithHandler:^BOOL(NSString *event, NSDictionary *labels) {
        if ([event isEqualToString:@"seek"]) {
            XCTAssertFalse(fullLengthSeekReceived);
            XCTAssertFalse(fullLengthPlayReceived);
            
            XCTAssertEqualObjects(labels[@"stream_name"], @"full");
            XCTAssertNil(labels[@"segment_name"]);
            XCTAssertEqualObjects(labels[@"overridable_name"], @"full");
            fullLengthSeekReceived = YES;
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
        
        return fullLengthSeekReceived && fullLengthPlayReceived;
    }];
    
    [self.mediaPlayerController seekPreciselyToTime:CMTimeMakeWithSeconds(55., NSEC_PER_SEC) withCompletionHandler:nil];
    
    [self waitForExpectationsWithTimeout:20. handler:nil];
}

- (void)testBlockedSegmentPlaythrough
{
    [self expectationForPlayerSingleHiddenEventNotificationWithHandler:^BOOL(NSString *event, NSDictionary *labels) {
        XCTAssertEqualObjects(labels[@"event_id"], @"play");
        XCTAssertEqualObjects(labels[@"stream_name"], @"full");
        XCTAssertNil(labels[@"segment_name"]);
        XCTAssertEqualObjects(labels[@"overridable_name"], @"full");
        return YES;
    }];
    
    Segment *segment = [Segment blockedSegmentWithName:@"segment" timeRange:CMTimeRangeMake(CMTimeMakeWithSeconds(2., NSEC_PER_SEC), CMTimeMakeWithSeconds(3., NSEC_PER_SEC))];
    
    SRGAnalyticsPlayerLabels *labels = [[SRGAnalyticsPlayerLabels alloc] init];
    labels.customInfo = @{ @"stream_name" : @"full",
                           @"overridable_name" : @"full" };
    
    [self.mediaPlayerController playURL:OnDemandTestURL()
                                 atTime:kCMTimeZero
                           withSegments:@[segment]
                        analyticsLabels:labels
                               userInfo:nil];
    
    [self waitForExpectationsWithTimeout:20. handler:nil];
    
    // Play for a while. Expect seek / play for the full-length when skipping over the segment
    
    __block BOOL fullLengthSeekReceived = NO;
    __block BOOL fullLengthPlayReceived = NO;
    
    [self expectationForPlayerSingleHiddenEventNotificationWithHandler:^BOOL(NSString *event, NSDictionary *labels) {
        if ([event isEqualToString:@"seek"]) {
            XCTAssertFalse(fullLengthSeekReceived);
            XCTAssertFalse(fullLengthPlayReceived);
            XCTAssertEqualObjects(labels[@"stream_name"], @"full");
            XCTAssertNil(labels[@"segment_name"]);
            XCTAssertEqualObjects(labels[@"overridable_name"], @"full");
            fullLengthSeekReceived = YES;
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
        
        return fullLengthSeekReceived && fullLengthPlayReceived;
    }];
    
    [self waitForExpectationsWithTimeout:20. handler:nil];
}

- (void)testDisableTrackingWhileIdle
{
    // Play for a while. No stream events must be received
    id eventObserver = [[NSNotificationCenter defaultCenter] addObserverForPlayerSingleHiddenEventNotificationUsingBlock:^(NSString * _Nonnull event, NSDictionary * _Nonnull labels) {
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
    id eventObserver = [[NSNotificationCenter defaultCenter] addObserverForPlayerSingleHiddenEventNotificationUsingBlock:^(NSString * _Nonnull event, NSDictionary * _Nonnull labels) {
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
    [self expectationForPlayerSingleHiddenEventNotificationWithHandler:^BOOL(NSString *event, NSDictionary *labels) {
        XCTAssertEqualObjects(event, @"play");
        return YES;
    }];
    
    [self.mediaPlayerController playURL:OnDemandTestURL()];
    
    [self waitForExpectationsWithTimeout:20. handler:nil];
    
    // Stop tracking while playing. Expect a stop to be received
    [self expectationForPlayerSingleHiddenEventNotificationWithHandler:^BOOL(NSString *event, NSDictionary *labels) {
        XCTAssertEqualObjects(event, @"stop");
        return YES;
    }];
    
    XCTAssertEqual(self.mediaPlayerController.playbackState, SRGMediaPlayerPlaybackStatePlaying);
    self.mediaPlayerController.tracked = NO;
    
    [self waitForExpectationsWithTimeout:20. handler:nil];
}

- (void)testDisableTrackingWhilePlayingSegment
{
    // Wait until the media plays. Expect segment labels
    [self expectationForPlayerSingleHiddenEventNotificationWithHandler:^BOOL(NSString *event, NSDictionary *labels) {
        XCTAssertEqualObjects(labels[@"event_id"], @"play");
        XCTAssertEqualObjects(labels[@"stream_name"], @"full");
        XCTAssertEqualObjects(labels[@"segment_name"], @"segment");
        XCTAssertEqualObjects(labels[@"overridable_name"], @"segment");
        return YES;
    }];
    
    Segment *segment = [Segment segmentWithName:@"segment" timeRange:CMTimeRangeMake(CMTimeMakeWithSeconds(2., NSEC_PER_SEC), CMTimeMakeWithSeconds(3., NSEC_PER_SEC))];
    
    SRGAnalyticsPlayerLabels *labels = [[SRGAnalyticsPlayerLabels alloc] init];
    labels.customInfo = @{ @"stream_name" : @"full",
                           @"overridable_name" : @"full" };
    
    [self.mediaPlayerController playURL:OnDemandTestURL()
                                atIndex:0
                             inSegments:@[segment]
                    withAnalyticsLabels:labels
                               userInfo:nil];
    
    [self waitForExpectationsWithTimeout:20. handler:nil];
    
    // Stop tracking while playing. Expect a stop to be received with segment labels
    [self expectationForPlayerSingleHiddenEventNotificationWithHandler:^BOOL(NSString *event, NSDictionary *labels) {
        XCTAssertEqualObjects(labels[@"event_id"], @"stop");
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
    [self expectationForPlayerSingleHiddenEventNotificationWithHandler:^BOOL(NSString *event, NSDictionary *labels) {
        XCTAssertEqualObjects(event, @"play");
        return YES;
    }];
    
    [self.mediaPlayerController playURL:OnDemandTestURL()];
    
    [self waitForExpectationsWithTimeout:20. handler:nil];
    
    // Pause playback
    [self expectationForPlayerSingleHiddenEventNotificationWithHandler:^BOOL(NSString *event, NSDictionary *labels) {
        XCTAssertEqualObjects(event, @"pause");
        return YES;
    }];
    
    [self.mediaPlayerController pause];
    
    [self waitForExpectationsWithTimeout:20. handler:nil];
    
    // Stop tracking while paused. Expect a stop to be received
    [self expectationForPlayerSingleHiddenEventNotificationWithHandler:^BOOL(NSString *event, NSDictionary *labels) {
        XCTAssertEqualObjects(event, @"stop");
        return YES;
    }];
    
    XCTAssertEqual(self.mediaPlayerController.playbackState, SRGMediaPlayerPlaybackStatePaused);
    self.mediaPlayerController.tracked = NO;
    
    [self waitForExpectationsWithTimeout:20. handler:nil];
}

- (void)testDisableTrackingWhilePausedInSegment
{
    // Wait until the media plays. Expect segment labels
    [self expectationForPlayerSingleHiddenEventNotificationWithHandler:^BOOL(NSString *event, NSDictionary *labels) {
        XCTAssertEqualObjects(labels[@"event_id"], @"play");
        XCTAssertEqualObjects(labels[@"stream_name"], @"full");
        XCTAssertEqualObjects(labels[@"segment_name"], @"segment");
        XCTAssertEqualObjects(labels[@"overridable_name"], @"segment");
        return YES;
    }];
    
    SRGAnalyticsPlayerLabels *labels = [[SRGAnalyticsPlayerLabels alloc] init];
    labels.customInfo = @{ @"stream_name" : @"full",
                           @"overridable_name" : @"full" };
    
    Segment *segment = [Segment segmentWithName:@"segment" timeRange:CMTimeRangeMake(CMTimeMakeWithSeconds(2., NSEC_PER_SEC), CMTimeMakeWithSeconds(3., NSEC_PER_SEC))];
    [self.mediaPlayerController playURL:OnDemandTestURL()
                                atIndex:0
                             inSegments:@[segment]
                    withAnalyticsLabels:labels
                               userInfo:nil];
    
    [self waitForExpectationsWithTimeout:20. handler:nil];
    
    // Pause playback. Expect a pause with segment labels
    [self expectationForPlayerSingleHiddenEventNotificationWithHandler:^BOOL(NSString *event, NSDictionary *labels) {
        XCTAssertEqualObjects(labels[@"event_id"], @"pause");
        XCTAssertEqualObjects(labels[@"stream_name"], @"full");
        XCTAssertEqualObjects(labels[@"segment_name"], @"segment");
        XCTAssertEqualObjects(labels[@"overridable_name"], @"segment");
        return YES;
    }];
    
    [self.mediaPlayerController pause];
    
    [self waitForExpectationsWithTimeout:20. handler:nil];
    
    // Stop tracking while paused. Expect a stop to be received with segment labels
    [self expectationForPlayerSingleHiddenEventNotificationWithHandler:^BOOL(NSString *event, NSDictionary *labels) {
        XCTAssertEqualObjects(labels[@"event_id"], @"stop");
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
    
    // Enable tracking. Expect a play to be received
    [self expectationForPlayerSingleHiddenEventNotificationWithHandler:^BOOL(NSString *event, NSDictionary *labels) {
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
    labels.customInfo = @{ @"stream_name" : @"full",
                           @"overridable_name" : @"full" };
    
    [self.mediaPlayerController playURL:OnDemandTestURL()
                                atIndex:0
                             inSegments:@[segment]
                    withAnalyticsLabels:labels
                               userInfo:nil];
    
    [self waitForExpectationsWithTimeout:20. handler:nil];
    
    // Enable tracking. Expect a play to be received
    [self expectationForPlayerSingleHiddenEventNotificationWithHandler:^BOOL(NSString *event, NSDictionary *labels) {
        XCTAssertEqualObjects(labels[@"event_id"], @"play");
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
    id eventObserver = [[NSNotificationCenter defaultCenter] addObserverForPlayerSingleHiddenEventNotificationUsingBlock:^(NSString * _Nonnull event, NSDictionary * _Nonnull labels) {
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
    [self expectationForPlayerSingleHiddenEventNotificationWithHandler:^BOOL(NSString *event, NSDictionary *labels) {
        XCTAssertEqualObjects(labels[@"event_id"], @"play");
        return YES;
    }];
    
    XCTAssertEqual(self.mediaPlayerController.playbackState, SRGMediaPlayerPlaybackStatePlaying);
    self.mediaPlayerController.tracked = YES;
    
    [self waitForExpectationsWithTimeout:20. handler:nil];
}

- (void)testEnableTrackingWhilePlayingSegment
{
    // Wait until the player is playing. No event must be received since tracking is not enabled yet
    id eventObserver = [[NSNotificationCenter defaultCenter] addObserverForPlayerSingleHiddenEventNotificationUsingBlock:^(NSString * _Nonnull event, NSDictionary * _Nonnull labels) {
        XCTFail(@"No event must be received when tracking has been disabled");
    }];
    
    [self expectationForNotification:SRGMediaPlayerPlaybackStateDidChangeNotification object:self.mediaPlayerController handler:^BOOL(NSNotification * _Nonnull notification) {
        return [notification.userInfo[SRGMediaPlayerPlaybackStateKey] integerValue] == SRGMediaPlayerPlaybackStatePlaying;
    }];
    
    self.mediaPlayerController.tracked = NO;
    Segment *segment = [Segment segmentWithName:@"segment" timeRange:CMTimeRangeMake(CMTimeMakeWithSeconds(2., NSEC_PER_SEC), CMTimeMakeWithSeconds(3., NSEC_PER_SEC))];
    
    SRGAnalyticsPlayerLabels *labels = [[SRGAnalyticsPlayerLabels alloc] init];
    labels.customInfo = @{ @"stream_name" : @"full",
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
    [self expectationForPlayerSingleHiddenEventNotificationWithHandler:^BOOL(NSString *event, NSDictionary *labels) {
        XCTAssertEqualObjects(labels[@"event_id"], @"play");
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
    id eventObserver = [[NSNotificationCenter defaultCenter] addObserverForPlayerSingleHiddenEventNotificationUsingBlock:^(NSString * _Nonnull event, NSDictionary * _Nonnull labels) {
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
    
    [self expectationForPlayerSingleHiddenEventNotificationWithHandler:^BOOL(NSString *event, NSDictionary *labels) {
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

- (void)testDisableTrackingTwiceWhilePlaying
{
    // Wait until the media plays
    [self expectationForPlayerSingleHiddenEventNotificationWithHandler:^BOOL(NSString *event, NSDictionary *labels) {
        XCTAssertEqualObjects(event, @"play");
        return YES;
    }];
    
    [self.mediaPlayerController playURL:OnDemandTestURL()];
    
    [self waitForExpectationsWithTimeout:20. handler:nil];
    
    // Stop tracking twice while playing. Expect a single stop to be received
    __block NSInteger stopEventCount = 0;
    id endEventObserver = [[NSNotificationCenter defaultCenter] addObserverForPlayerSingleHiddenEventNotificationUsingBlock:^(NSString * _Nonnull event, NSDictionary * _Nonnull labels) {
        if ([event isEqualToString:@"stop"]) {
            ++stopEventCount;
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
    
    // Check we have received the stop notification only once
    XCTAssertEqual(stopEventCount, 1);
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
    id endEventObserver = [[NSNotificationCenter defaultCenter] addObserverForPlayerSingleHiddenEventNotificationUsingBlock:^(NSString * _Nonnull event, NSDictionary * _Nonnull labels) {
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
    
    // Check we have received the play notification only once
    XCTAssertEqual(playEventCount, 1);
}

- (void)testOnDemandHeartbeatPlayPausePlay
{
    [self expectationForPlayerSingleHiddenEventNotificationWithHandler:^BOOL(NSString *event, NSDictionary *labels) {
        XCTAssertEqualObjects(labels[@"event_id"], @"play");
        XCTAssertEqualObjects(labels[@"stream_name"], @"full");
        return YES;
    }];
    
    SRGAnalyticsPlayerLabels *labels = [[SRGAnalyticsPlayerLabels alloc] init];
    labels.customInfo = @{ @"stream_name" : @"full" };
    
    [self.mediaPlayerController playURL:OnDemandTestURL() atTime:kCMTimeZero withSegments:nil analyticsLabels:labels userInfo:nil];
    
    [self waitForExpectationsWithTimeout:20. handler:nil];
    
    // For tests, heartbeat interval is set to 3 seconds.
    
    __block NSInteger heartbeatCount = 0;
    id hearbeatEventObserver = [[NSNotificationCenter defaultCenter] addObserverForHiddenEventNotificationUsingBlock:^(NSString * _Nonnull event, NSDictionary * _Nonnull labels) {
        if ([event isEqualToString:@"pos"]) {
            XCTAssertEqualObjects(labels[@"stream_name"], @"full");
            ++heartbeatCount;
        }
        else if ([event isEqualToString:@"uptime"]) {
            XCTFail(@"No uptime expected for on-demand streams");
        }
    }];
    
    // Wait a little bit to collect potential events
    [self expectationForElapsedTimeInterval:7. withHandler:nil];
    [self waitForExpectationsWithTimeout:20. handler:^(NSError * _Nullable error) {
        [[NSNotificationCenter defaultCenter] removeObserver:hearbeatEventObserver];
    }];
    
    XCTAssertEqual(heartbeatCount, 2);
    
    [self expectationForPlayerSingleHiddenEventNotificationWithHandler:^BOOL(NSString *event, NSDictionary *labels) {
        XCTAssertEqualObjects(labels[@"event_id"], @"pause");
        XCTAssertEqualObjects(labels[@"stream_name"], @"full");
        return YES;
    }];
    
    [self.mediaPlayerController pause];
    
    [self waitForExpectationsWithTimeout:20. handler:nil];
    
    heartbeatCount = 0;
    hearbeatEventObserver = [[NSNotificationCenter defaultCenter] addObserverForHiddenEventNotificationUsingBlock:^(NSString * _Nonnull event, NSDictionary * _Nonnull labels) {
        if ([event isEqualToString:@"pos"]) {
            XCTAssertEqualObjects(labels[@"stream_name"], @"full");
            ++heartbeatCount;
        }
        else if ([event isEqualToString:@"uptime"]) {
            XCTFail(@"No uptime expected for on-demand streams");
        }
    }];
    
    // Wait a little bit to collect potential events
    [self expectationForElapsedTimeInterval:4. withHandler:nil];
    [self waitForExpectationsWithTimeout:20. handler:^(NSError * _Nullable error) {
        [[NSNotificationCenter defaultCenter] removeObserver:hearbeatEventObserver];
    }];
    
    XCTAssertEqual(heartbeatCount, 0);
    
    [self expectationForPlayerSingleHiddenEventNotificationWithHandler:^BOOL(NSString *event, NSDictionary *labels) {
        XCTAssertEqualObjects(labels[@"event_id"], @"play");
        return YES;
    }];
    
    [self.mediaPlayerController play];
    
    [self waitForExpectationsWithTimeout:20. handler:nil];
    
    heartbeatCount = 0;
    hearbeatEventObserver = [[NSNotificationCenter defaultCenter] addObserverForHiddenEventNotificationUsingBlock:^(NSString * _Nonnull event, NSDictionary * _Nonnull labels) {
        if ([event isEqualToString:@"pos"]) {
            XCTAssertEqualObjects(labels[@"stream_name"], @"full");
            ++heartbeatCount;
        }
        else if ([event isEqualToString:@"uptime"]) {
            XCTFail(@"No uptime expected for on-demand streams");
        }
    }];
    
    // Wait a little bit to collect potential events
    [self expectationForElapsedTimeInterval:7. withHandler:nil];
    [self waitForExpectationsWithTimeout:20. handler:^(NSError * _Nullable error) {
        [[NSNotificationCenter defaultCenter] removeObserver:hearbeatEventObserver];
    }];
    
    XCTAssertEqual(heartbeatCount, 2);
}

- (void)testLivestreamHeartbeatPlay
{
    [self expectationForPlayerSingleHiddenEventNotificationWithHandler:^BOOL(NSString *event, NSDictionary *labels) {
        XCTAssertEqualObjects(labels[@"event_id"], @"play");
        XCTAssertEqualObjects(labels[@"stream_name"], @"full");
        return YES;
    }];
    
    SRGAnalyticsPlayerLabels *labels = [[SRGAnalyticsPlayerLabels alloc] init];
    labels.customInfo = @{ @"stream_name" : @"full" };
    
    [self.mediaPlayerController playURL:LiveTestURL() atTime:kCMTimeZero withSegments:nil analyticsLabels:labels userInfo:nil];
    
    [self waitForExpectationsWithTimeout:20. handler:nil];
    
    // For tests, heartbeat interval is set to 3 seconds.
    
    __block NSInteger heartbeatCount = 0;
    __block NSInteger liveheartbeatCount = 0;
    id hearbeatEventObserver = [[NSNotificationCenter defaultCenter] addObserverForHiddenEventNotificationUsingBlock:^(NSString * _Nonnull event, NSDictionary * _Nonnull labels) {
        if ([event isEqualToString:@"pos"]) {
            XCTAssertEqualObjects(labels[@"stream_name"], @"full");
            ++heartbeatCount;
        }
        else if ([event isEqualToString:@"uptime"]) {
            XCTAssertEqualObjects(labels[@"stream_name"], @"full");
            ++liveheartbeatCount;
        }
    }];
    
    // Wait a little bit to collect potential events
    [self expectationForElapsedTimeInterval:14. withHandler:nil];
    [self waitForExpectationsWithTimeout:20. handler:^(NSError * _Nullable error) {
        [[NSNotificationCenter defaultCenter] removeObserver:hearbeatEventObserver];
    }];
    
    XCTAssertEqual(heartbeatCount, 4);
    XCTAssertEqual(liveheartbeatCount, 2);
}

- (void)testHeartbeatWithSegmentPlayback
{
    [self expectationForPlayerSingleHiddenEventNotificationWithHandler:^BOOL(NSString *event, NSDictionary *labels) {
        XCTAssertEqualObjects(labels[@"event_id"], @"play");
        return YES;
    }];
    
    Segment *segment = [Segment segmentWithName:@"segment" timeRange:CMTimeRangeMake(CMTimeMakeWithSeconds(4., NSEC_PER_SEC), CMTimeMakeWithSeconds(4., NSEC_PER_SEC))];
    [self.mediaPlayerController playURL:OnDemandTestURL()
                                atIndex:0
                             inSegments:@[segment]
                    withAnalyticsLabels:nil
                               userInfo:nil];
    
    [self waitForExpectationsWithTimeout:20. handler:nil];
    
    // For tests, heartbeat interval is set to 3 seconds.
    
    __block NSInteger heartbeatCount = 0;
    __block NSInteger segmentHeartbeatCount = 0;
    id hearbeatEventObserver = [[NSNotificationCenter defaultCenter] addObserverForHiddenEventNotificationUsingBlock:^(NSString * _Nonnull event, NSDictionary * _Nonnull labels) {
        if ([event isEqualToString:@"pos"]) {
            if ([labels[@"segment_name"] isEqualToString:@"segment"]) {
                ++segmentHeartbeatCount;
            }
            else {
                ++heartbeatCount;
            }
        }
    }];
    
    // Wait a little bit to collect potential events
    [self expectationForElapsedTimeInterval:14. withHandler:nil];
    [self waitForExpectationsWithTimeout:20. handler:^(NSError * _Nullable error) {
        [[NSNotificationCenter defaultCenter] removeObserver:hearbeatEventObserver];
    }];
    
    XCTAssertEqual(heartbeatCount, 3);
    XCTAssertEqual(segmentHeartbeatCount, 1);
}

@end
