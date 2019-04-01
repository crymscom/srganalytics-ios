//
//  Copyright (c) SRG SSR. All rights reserved.
//
//  License information is available from the LICENSE file.
//

#import "NSNotificationCenter+Tests.h"
#import "Segment.h"
#import "XCTestCase+Tests.h"

#import <MediaAccessibility/MediaAccessibility.h>
#import <SRGAnalytics_MediaPlayer/SRGAnalytics_MediaPlayer.h>

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

@interface MediaPlayerTestCase : XCTestCase

@property (nonatomic) SRGMediaPlayerController *mediaPlayerController;

@end

@implementation MediaPlayerTestCase

#pragma mark Setup and teardown

- (void)setUp
{
    self.mediaPlayerController = [[SRGMediaPlayerController alloc] init];
}

- (void)tearDown
{
    // Ensure each test ends in an expected state.
    if (self.mediaPlayerController.tracked && self.mediaPlayerController.playbackState != SRGMediaPlayerPlaybackStateIdle
            && self.mediaPlayerController.playbackState != SRGMediaPlayerPlaybackStateEnded) {
        [self expectationForHiddenPlaybackEventNotificationWithHandler:^BOOL(NSString * _Nonnull event, NSDictionary * _Nonnull labels) {
            return [event isEqualToString:@"stop"];
        }];
        
        [self.mediaPlayerController reset];
        
        [self waitForExpectationsWithTimeout:20. handler:nil];
    }
    self.mediaPlayerController = nil;
}

#pragma mark Tests

- (void)testPrepareToPlay
{
    // Prepare the player until it is paused. No event must be received
    id prepareObserver = [NSNotificationCenter.defaultCenter addObserverForPlayerSingleHiddenEventNotificationUsingBlock:^(NSString * _Nonnull event, NSDictionary * _Nonnull labels) {
        XCTFail(@"No event must be received when preparing a player");
    }];
    
    [self.mediaPlayerController prepareToPlayURL:OnDemandTestURL() withCompletionHandler:^{
        [NSNotificationCenter.defaultCenter removeObserver:prepareObserver];
    }];
    
    // Now playing must trigger a play event
    [self expectationForHiddenPlaybackEventNotificationWithHandler:^BOOL(NSString *event, NSDictionary *labels) {
        XCTAssertEqualObjects(labels[@"event_id"], @"play");
        return YES;
    }];
    
    [self.mediaPlayerController play];
    
    [self waitForExpectationsWithTimeout:20. handler:nil];
    
    [self expectationForHiddenPlaybackEventNotificationWithHandler:^BOOL(NSString *event, NSDictionary *labels) {
        XCTAssertEqualObjects(labels[@"event_id"], @"stop");
        return YES;
    }];
    
    [self.mediaPlayerController reset];
    
    [self waitForExpectationsWithTimeout:20. handler:nil];
}

- (void)testPlaybackToEnd
{
    [self expectationForHiddenPlaybackEventNotificationWithHandler:^BOOL(NSString *event, NSDictionary *labels) {
        XCTAssertEqualObjects(labels[@"event_id"], @"play");
        XCTAssertEqualObjects(labels[@"media_position"], @"0");
        return YES;
    }];
    
    [self.mediaPlayerController playURL:OnDemandTestURL()];
    
    [self waitForExpectationsWithTimeout:20. handler:nil];
    
    [self expectationForHiddenPlaybackEventNotificationWithHandler:^BOOL(NSString *event, NSDictionary *labels) {
        XCTAssertEqualObjects(labels[@"event_id"], @"seek");
        XCTAssertEqualObjects(labels[@"media_position"], @"0");
        return YES;
    }];
    
    // Seek near the end of the video
    CMTime pastTime = CMTimeSubtract(CMTimeRangeGetEnd(self.mediaPlayerController.timeRange), CMTimeMakeWithSeconds(5., NSEC_PER_SEC));
    [self.mediaPlayerController seekToPosition:[SRGPosition positionAtTime:pastTime] withCompletionHandler:nil];
    
    [self waitForExpectationsWithTimeout:20. handler:nil];
    
    [self expectationForHiddenPlaybackEventNotificationWithHandler:^BOOL(NSString *event, NSDictionary *labels) {
        XCTAssertEqualObjects(labels[@"event_id"], @"play");
        XCTAssertNotEqualObjects(labels[@"media_position"], @"0");
        return YES;
    }];
    
    [self waitForExpectationsWithTimeout:20. handler:nil];
    
    // Let playback finish normally
    
    [self expectationForHiddenPlaybackEventNotificationWithHandler:^BOOL(NSString *event, NSDictionary *labels) {
        XCTAssertEqualObjects(labels[@"event_id"], @"eof");
        XCTAssertNotEqualObjects(labels[@"media_position"], @"0");
        return YES;
    }];
    
    [self waitForExpectationsWithTimeout:20. handler:nil];
}

- (void)testPlayStop
{
    [self expectationForHiddenPlaybackEventNotificationWithHandler:^BOOL(NSString *event, NSDictionary *labels) {
        XCTAssertEqualObjects(labels[@"event_id"], @"play");
        XCTAssertEqualObjects(labels[@"media_position"], @"0");
        return YES;
    }];
    
    [self.mediaPlayerController playURL:OnDemandTestURL()];
    
    [self waitForExpectationsWithTimeout:20. handler:nil];
    
    // Play for a while. No stream events must be received
    id eventObserver = [NSNotificationCenter.defaultCenter addObserverForPlayerSingleHiddenEventNotificationUsingBlock:^(NSString * _Nonnull event, NSDictionary * _Nonnull labels) {
        XCTFail(@"No event must be received when playing");
    }];
    
    [self expectationForElapsedTimeInterval:1. withHandler:nil];
    [self waitForExpectationsWithTimeout:20. handler:^(NSError * _Nullable error) {
        [NSNotificationCenter.defaultCenter removeObserver:eventObserver];
    }];
    
    [self expectationForHiddenPlaybackEventNotificationWithHandler:^BOOL(NSString *event, NSDictionary *labels) {
        XCTAssertEqualObjects(labels[@"event_id"], @"stop");
        XCTAssertEqualObjects(labels[@"media_position"], @"1");
        return YES;
    }];
    
    [self.mediaPlayerController stop];
    
    [self waitForExpectationsWithTimeout:20. handler:nil];
}

- (void)testPlayReset
{
    [self expectationForHiddenPlaybackEventNotificationWithHandler:^BOOL(NSString *event, NSDictionary *labels) {
        XCTAssertEqualObjects(labels[@"event_id"], @"play");
        XCTAssertEqualObjects(labels[@"media_position"], @"0");
        return YES;
    }];
    
    [self.mediaPlayerController playURL:OnDemandTestURL()];
    
    [self waitForExpectationsWithTimeout:20. handler:nil];
    
    // Play for a while. No stream events must be received
    id eventObserver = [NSNotificationCenter.defaultCenter addObserverForPlayerSingleHiddenEventNotificationUsingBlock:^(NSString * _Nonnull event, NSDictionary * _Nonnull labels) {
        XCTFail(@"No event must be received when playing");
    }];
    
    [self expectationForElapsedTimeInterval:1. withHandler:nil];
    [self waitForExpectationsWithTimeout:20. handler:^(NSError * _Nullable error) {
        [NSNotificationCenter.defaultCenter removeObserver:eventObserver];
    }];
    
    [self expectationForHiddenPlaybackEventNotificationWithHandler:^BOOL(NSString *event, NSDictionary *labels) {
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
    id eventObserver1 = [NSNotificationCenter.defaultCenter addObserverForPlayerSingleHiddenEventNotificationUsingBlock:^(NSString * _Nonnull event, NSDictionary * _Nonnull labels) {
        ++count1;
    }];
    
    [self expectationForHiddenPlaybackEventNotificationWithHandler:^BOOL(NSString *event, NSDictionary *labels) {
        return [event isEqualToString:@"play"];
    }];
    
    [self.mediaPlayerController playURL:OnDemandTestURL()];
    
    [self waitForExpectationsWithTimeout:20. handler:^(NSError * _Nullable error) {
        [NSNotificationCenter.defaultCenter removeObserver:eventObserver1];
    }];
    
    // One event expected: play
    XCTAssertEqual(count1, 1);
    
    __block NSInteger count2 = 0;
    id eventObserver2 = [NSNotificationCenter.defaultCenter addObserverForPlayerSingleHiddenEventNotificationUsingBlock:^(NSString * _Nonnull event, NSDictionary * _Nonnull labels) {
        ++count2;
    }];
    
    [self expectationForHiddenPlaybackEventNotificationWithHandler:^BOOL(NSString *event, NSDictionary *labels) {
        return [event isEqualToString:@"pause"];
    }];
    
    [self.mediaPlayerController pause];
    
    [self waitForExpectationsWithTimeout:20. handler:^(NSError * _Nullable error) {
        [NSNotificationCenter.defaultCenter removeObserver:eventObserver2];
    }];
    
    // One event expected: pause
    XCTAssertEqual(count2, 1);
    
    __block NSInteger count3 = 0;
    id eventObserver3 = [NSNotificationCenter.defaultCenter addObserverForPlayerSingleHiddenEventNotificationUsingBlock:^(NSString * _Nonnull event, NSDictionary * _Nonnull labels) {
        ++count3;
    }];
    
    [self expectationForHiddenPlaybackEventNotificationWithHandler:^BOOL(NSString *event, NSDictionary *labels) {
        return [event isEqualToString:@"play"];
    }];
    
    [self.mediaPlayerController play];
    
    [self waitForExpectationsWithTimeout:20. handler:^(NSError * _Nullable error) {
        [NSNotificationCenter.defaultCenter removeObserver:eventObserver3];
    }];
    
    [self expectationForElapsedTimeInterval:3. withHandler:nil];
    
    id eventObserver4 = [NSNotificationCenter.defaultCenter addObserverForPlayerSingleHiddenEventNotificationUsingBlock:^(NSString * _Nonnull event, NSDictionary * _Nonnull labels) {
        // Also see http://stackoverflow.com/questions/14565405/avplayer-pauses-for-no-obvious-reason and
        // the demo project https://github.com/defagos/radars/tree/master/unexpected-player-rate-changes
        NSLog(@"[AVPlayer probable bug]: Unexpected state change to %@. Fast play - pause sequences can induce unexpected rate changes "
              "captured via KVO in our implementation. Those changes do not harm but cannot be tested reliably", @(self.mediaPlayerController.playbackState));
    }];
    
    [self waitForExpectationsWithTimeout:20. handler:^(NSError * _Nullable error) {
        [NSNotificationCenter.defaultCenter removeObserver:eventObserver4];
    }];
}

- (void)testPlaySeekPlay
{
    __block NSInteger count1 = 0;
    id eventObserver1 = [NSNotificationCenter.defaultCenter addObserverForPlayerSingleHiddenEventNotificationUsingBlock:^(NSString * _Nonnull event, NSDictionary * _Nonnull labels) {
        ++count1;
    }];
    
    [self expectationForHiddenPlaybackEventNotificationWithHandler:^BOOL(NSString *event, NSDictionary *labels) {
        return [event isEqualToString:@"play"];
    }];
    
    [self.mediaPlayerController playURL:OnDemandTestURL()];
    
    [self waitForExpectationsWithTimeout:20. handler:^(NSError * _Nullable error) {
        [NSNotificationCenter.defaultCenter removeObserver:eventObserver1];
    }];
    
    // One event expected: play
    XCTAssertEqual(count1, 1);
    
    __block NSInteger count2 = 0;
    id eventObserver2 = [NSNotificationCenter.defaultCenter addObserverForPlayerSingleHiddenEventNotificationUsingBlock:^(NSString * _Nonnull event, NSDictionary * _Nonnull labels) {
        ++count2;
    }];
    
    // Expect seek - play transition with labels
    
    __block BOOL seekReceived = NO;
    __block BOOL playReceived = NO;
    
    [self expectationForHiddenPlaybackEventNotificationWithHandler:^BOOL(NSString *event, NSDictionary *labels) {
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
    
    [self.mediaPlayerController seekToPosition:[SRGPosition positionAtTimeInSeconds:2.] withCompletionHandler:nil];
    
    [self waitForExpectationsWithTimeout:20. handler:^(NSError * _Nullable error) {
        [NSNotificationCenter.defaultCenter removeObserver:eventObserver2];
    }];
    
    // Two events expected: seek and play
    XCTAssertEqual(count2, 2);
    
    [self expectationForElapsedTimeInterval:3. withHandler:nil];
    
    id eventObserver4 = [NSNotificationCenter.defaultCenter addObserverForPlayerSingleHiddenEventNotificationUsingBlock:^(NSString * _Nonnull event, NSDictionary * _Nonnull labels) {
        // Also see http://stackoverflow.com/questions/14565405/avplayer-pauses-for-no-obvious-reason and
        // the demo project https://github.com/defagos/radars/tree/master/unexpected-player-rate-changes
        NSLog(@"[AVPlayer probable bug]: Unexpected state change to %@. Fast play - pause sequences can induce unexpected rate changes "
              "captured via KVO in our implementation. Those changes do not harm but cannot be tested reliably", @(self.mediaPlayerController.playbackState));
    }];
    
    [self waitForExpectationsWithTimeout:20. handler:^(NSError * _Nullable error) {
        [NSNotificationCenter.defaultCenter removeObserver:eventObserver4];
    }];
}

- (void)testPlayPauseSeekPause
{
    __block NSInteger count1 = 0;
    id eventObserver1 = [NSNotificationCenter.defaultCenter addObserverForPlayerSingleHiddenEventNotificationUsingBlock:^(NSString * _Nonnull event, NSDictionary * _Nonnull labels) {
        ++count1;
    }];
    
    [self expectationForHiddenPlaybackEventNotificationWithHandler:^BOOL(NSString *event, NSDictionary *labels) {
        return [event isEqualToString:@"play"];
    }];
    
    [self.mediaPlayerController playURL:OnDemandTestURL()];
    
    [self waitForExpectationsWithTimeout:20. handler:^(NSError * _Nullable error) {
        [NSNotificationCenter.defaultCenter removeObserver:eventObserver1];
    }];
    
    // One event expected: play
    XCTAssertEqual(count1, 1);
    
    __block NSInteger count2 = 0;
    id eventObserver2 = [NSNotificationCenter.defaultCenter addObserverForPlayerSingleHiddenEventNotificationUsingBlock:^(NSString * _Nonnull event, NSDictionary * _Nonnull labels) {
        ++count2;
    }];
    
    [self expectationForHiddenPlaybackEventNotificationWithHandler:^BOOL(NSString *event, NSDictionary *labels) {
        return [event isEqualToString:@"pause"];
    }];
    
    [self.mediaPlayerController pause];
    
    [self waitForExpectationsWithTimeout:20. handler:^(NSError * _Nullable error) {
        [NSNotificationCenter.defaultCenter removeObserver:eventObserver2];
    }];
    
    // One event expected: pause
    XCTAssertEqual(count2, 1);
    
    __block NSInteger count3 = 0;
    id eventObserver3 = [NSNotificationCenter.defaultCenter addObserverForPlayerSingleHiddenEventNotificationUsingBlock:^(NSString * _Nonnull event, NSDictionary * _Nonnull labels) {
        ++count3;
    }];
    
    // Expect seek - pause transition with labels
    
    __block BOOL seekReceived = NO;
    __block BOOL pauseReceived = NO;
    
    [self expectationForHiddenPlaybackEventNotificationWithHandler:^BOOL(NSString *event, NSDictionary *labels) {
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
    
    [self.mediaPlayerController seekToPosition:[SRGPosition positionAtTimeInSeconds:2.] withCompletionHandler:nil];
    
    [self waitForExpectationsWithTimeout:20. handler:^(NSError * _Nullable error) {
        [NSNotificationCenter.defaultCenter removeObserver:eventObserver3];
    }];
    
    // Two events expected: seek and pause
    XCTAssertEqual(count3, 2);
    
    [self expectationForElapsedTimeInterval:3. withHandler:nil];
    
    id eventObserver5 = [NSNotificationCenter.defaultCenter addObserverForPlayerSingleHiddenEventNotificationUsingBlock:^(NSString * _Nonnull event, NSDictionary * _Nonnull labels) {
        // Also see http://stackoverflow.com/questions/14565405/avplayer-pauses-for-no-obvious-reason and
        // the demo project https://github.com/defagos/radars/tree/master/unexpected-player-rate-changes
        NSLog(@"[AVPlayer probable bug]: Unexpected state change to %@. Fast play - pause sequences can induce unexpected rate changes "
              "captured via KVO in our implementation. Those changes do not harm but cannot be tested reliably", @(self.mediaPlayerController.playbackState));
    }];
    
    [self waitForExpectationsWithTimeout:20. handler:^(NSError * _Nullable error) {
        [NSNotificationCenter.defaultCenter removeObserver:eventObserver5];
    }];
}

- (void)testConsecutiveMedias
{
    [self expectationForHiddenPlaybackEventNotificationWithHandler:^BOOL(NSString *event, NSDictionary *labels) {
        XCTAssertEqualObjects(labels[@"event_id"], @"play");
        return YES;
    }];
    
    [self.mediaPlayerController playURL:OnDemandTestURL()];
    
    [self waitForExpectationsWithTimeout:20. handler:nil];
    
    [self expectationForHiddenPlaybackEventNotificationWithHandler:^BOOL(NSString *event, NSDictionary *labels) {
        XCTAssertEqualObjects(labels[@"event_id"], @"stop");
        return YES;
    }];
    
    [self.mediaPlayerController playURL:LiveTestURL()];
    
    [self waitForExpectationsWithTimeout:20. handler:nil];
    
    [self expectationForHiddenPlaybackEventNotificationWithHandler:^BOOL(NSString *event, NSDictionary *labels) {
        XCTAssertEqualObjects(labels[@"event_id"], @"play");
        return YES;
    }];
    
    [self waitForExpectationsWithTimeout:20. handler:nil];
    
    [self expectationForHiddenPlaybackEventNotificationWithHandler:^BOOL(NSString *event, NSDictionary *labels) {
        XCTAssertEqualObjects(labels[@"event_id"], @"stop");
        return YES;
    }];
    
    [self.mediaPlayerController reset];
    
    [self waitForExpectationsWithTimeout:20. handler:nil];
}

- (void)testMediaError
{
    id eventObserver = [NSNotificationCenter.defaultCenter addObserverForPlayerSingleHiddenEventNotificationUsingBlock:^(NSString * _Nonnull event, NSDictionary * _Nonnull labels) {
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
    [self expectationForHiddenPlaybackEventNotificationWithHandler:^BOOL(NSString *event, NSDictionary *labels) {
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
    [self expectationForHiddenPlaybackEventNotificationWithHandler:^BOOL(NSString *event, NSDictionary *labels) {
        XCTAssertEqualObjects(labels[@"event_id"], @"play");
        XCTAssertNil(labels[@"media_timeshift"]);
        return YES;
    }];
    
    [self.mediaPlayerController playURL:OnDemandTestURL()];
    
    [self waitForExpectationsWithTimeout:20. handler:nil];
    
    [self expectationForHiddenPlaybackEventNotificationWithHandler:^BOOL(NSString *event, NSDictionary *labels) {
        XCTAssertEqualObjects(labels[@"event_id"], @"pause");
        XCTAssertNil(labels[@"media_timeshift"]);
        return YES;
    }];
    
    [self.mediaPlayerController pause];
    
    [self waitForExpectationsWithTimeout:20. handler:nil];
    
    [self expectationForHiddenPlaybackEventNotificationWithHandler:^BOOL(NSString *event, NSDictionary *labels) {
        XCTAssertEqualObjects(labels[@"event_id"], @"stop");
        XCTAssertNil(labels[@"media_timeshift"]);
        return YES;
    }];
    
    [self.mediaPlayerController reset];
    
    [self waitForExpectationsWithTimeout:20. handler:nil];
}

- (void)testLiveLabels
{
    [self expectationForHiddenPlaybackEventNotificationWithHandler:^BOOL(NSString *event, NSDictionary *labels) {
        XCTAssertEqualObjects(labels[@"event_id"], @"play");
        XCTAssertEqualObjects(labels[@"media_timeshift"], @"0");
        XCTAssertEqualObjects(labels[@"media_position"], @"0");
        return YES;
    }];
    
    [self.mediaPlayerController playURL:LiveTestURL() atPosition:nil withSegments:nil analyticsLabels:nil userInfo:nil];
    
    [self waitForExpectationsWithTimeout:20. handler:nil];
    
    // Play for a while. No stream events must be received
    id eventObserver = [NSNotificationCenter.defaultCenter addObserverForPlayerSingleHiddenEventNotificationUsingBlock:^(NSString * _Nonnull event, NSDictionary * _Nonnull labels) {
        XCTFail(@"No event must be received when playing");
    }];
    
    [self expectationForElapsedTimeInterval:1. withHandler:nil];
    [self waitForExpectationsWithTimeout:20. handler:^(NSError * _Nullable error) {
        [NSNotificationCenter.defaultCenter removeObserver:eventObserver];
    }];
    
    [self expectationForHiddenPlaybackEventNotificationWithHandler:^BOOL(NSString *event, NSDictionary *labels) {
        XCTAssertEqualObjects(labels[@"event_id"], @"pause");
        XCTAssertEqualObjects(labels[@"media_timeshift"], @"0");
        XCTAssertEqualObjects(labels[@"media_position"], @"1");
        return YES;
    }];
    
    [self.mediaPlayerController pause];
    
    [self waitForExpectationsWithTimeout:20. handler:nil];
    
    // Pause for a while. No stream events must be received
    eventObserver = [NSNotificationCenter.defaultCenter addObserverForPlayerSingleHiddenEventNotificationUsingBlock:^(NSString * _Nonnull event, NSDictionary * _Nonnull labels) {
        XCTFail(@"No event must be received when it's in pause");
    }];
    
    [self expectationForElapsedTimeInterval:1. withHandler:nil];
    [self waitForExpectationsWithTimeout:20. handler:^(NSError * _Nullable error) {
        [NSNotificationCenter.defaultCenter removeObserver:eventObserver];
    }];
    
    [self expectationForHiddenPlaybackEventNotificationWithHandler:^BOOL(NSString *event, NSDictionary *labels) {
        XCTAssertEqualObjects(labels[@"event_id"], @"stop");
        XCTAssertEqualObjects(labels[@"media_timeshift"], @"0");
        XCTAssertEqualObjects(labels[@"media_position"], @"1");
        return YES;
    }];
    
    [self.mediaPlayerController reset];
    
    [self waitForExpectationsWithTimeout:20. handler:nil];
}

- (void)testLiveStopLive
{
    [self expectationForHiddenPlaybackEventNotificationWithHandler:^BOOL(NSString *event, NSDictionary *labels) {
        XCTAssertEqualObjects(labels[@"event_id"], @"play");
        XCTAssertEqualObjects(labels[@"media_timeshift"], @"0");
        XCTAssertEqualObjects(labels[@"media_position"], @"0");
        return YES;
    }];
    
    [self.mediaPlayerController playURL:LiveTestURL() atPosition:nil withSegments:nil analyticsLabels:nil userInfo:nil];
    
    [self waitForExpectationsWithTimeout:20. handler:nil];
    
    // Play for a while. No stream events must be received
    id eventObserver = [NSNotificationCenter.defaultCenter addObserverForPlayerSingleHiddenEventNotificationUsingBlock:^(NSString * _Nonnull event, NSDictionary * _Nonnull labels) {
        XCTFail(@"No event must be received when playing");
    }];
    
    [self expectationForElapsedTimeInterval:1. withHandler:nil];
    [self waitForExpectationsWithTimeout:20. handler:^(NSError * _Nullable error) {
        [NSNotificationCenter.defaultCenter removeObserver:eventObserver];
    }];
    
    [self expectationForHiddenPlaybackEventNotificationWithHandler:^BOOL(NSString *event, NSDictionary *labels) {
        XCTAssertEqualObjects(labels[@"event_id"], @"stop");
        XCTAssertEqualObjects(labels[@"media_timeshift"], @"0");
        XCTAssertEqualObjects(labels[@"media_position"], @"1");
        return YES;
    }];
    
    [self.mediaPlayerController stop];
    
    [self waitForExpectationsWithTimeout:20. handler:nil];
    
    [self expectationForHiddenPlaybackEventNotificationWithHandler:^BOOL(NSString *event, NSDictionary *labels) {
        XCTAssertEqualObjects(labels[@"event_id"], @"play");
        XCTAssertEqualObjects(labels[@"media_timeshift"], @"0");
        XCTAssertEqualObjects(labels[@"media_position"], @"0");
        return YES;
    }];
    
    [self.mediaPlayerController play];
    
    [self waitForExpectationsWithTimeout:20. handler:nil];
    
    // Pause for a while. No stream events must be received
    eventObserver = [NSNotificationCenter.defaultCenter addObserverForPlayerSingleHiddenEventNotificationUsingBlock:^(NSString * _Nonnull event, NSDictionary * _Nonnull labels) {
        XCTFail(@"No event must be received when it's in pause");
    }];
    
    [self expectationForElapsedTimeInterval:1. withHandler:nil];
    [self waitForExpectationsWithTimeout:20. handler:^(NSError * _Nullable error) {
        [NSNotificationCenter.defaultCenter removeObserver:eventObserver];
    }];
    
    [self expectationForHiddenPlaybackEventNotificationWithHandler:^BOOL(NSString *event, NSDictionary *labels) {
        XCTAssertEqualObjects(labels[@"event_id"], @"stop");
        XCTAssertEqualObjects(labels[@"media_timeshift"], @"0");
        XCTAssertEqualObjects(labels[@"media_position"], @"1");
        return YES;
    }];
    
    [self.mediaPlayerController reset];
    
    [self waitForExpectationsWithTimeout:20. handler:nil];
}

- (void)testDVRLabels
{
    [self expectationForHiddenPlaybackEventNotificationWithHandler:^BOOL(NSString *event, NSDictionary *labels) {
        XCTAssertEqualObjects(labels[@"event_id"], @"play");
        XCTAssertEqualObjects(labels[@"media_timeshift"], @"0");
        XCTAssertEqualObjects(labels[@"media_position"], @"0");
        return YES;
    }];
    
    [self.mediaPlayerController playURL:DVRTestURL()];
    
    [self waitForExpectationsWithTimeout:20. handler:nil];
    
    // Play for a while. No stream events must be received
    id eventObserver = [NSNotificationCenter.defaultCenter addObserverForPlayerSingleHiddenEventNotificationUsingBlock:^(NSString * _Nonnull event, NSDictionary * _Nonnull labels) {
        XCTFail(@"No event must be received when playing");
    }];
    
    [self expectationForElapsedTimeInterval:1. withHandler:nil];
    [self waitForExpectationsWithTimeout:20. handler:^(NSError * _Nullable error) {
        [NSNotificationCenter.defaultCenter removeObserver:eventObserver];
    }];
    
    [self expectationForHiddenPlaybackEventNotificationWithHandler:^BOOL(NSString *event, NSDictionary *labels) {
        XCTAssertEqualObjects(labels[@"event_id"], @"seek");
        XCTAssertEqualObjects(labels[@"media_timeshift"], @"0");
        XCTAssertEqualObjects(labels[@"media_position"], @"1");
        return YES;
    }];
    
    CMTime pastTime = CMTimeSubtract(CMTimeRangeGetEnd(self.mediaPlayerController.timeRange), CMTimeMakeWithSeconds(45., NSEC_PER_SEC));
    [self.mediaPlayerController seekToPosition:[SRGPosition positionAtTime:pastTime] withCompletionHandler:nil];
    
    [self waitForExpectationsWithTimeout:20. handler:nil];
    
    [self expectationForHiddenPlaybackEventNotificationWithHandler:^BOOL(NSString *event, NSDictionary *labels) {
        XCTAssertEqualObjects(labels[@"event_id"], @"play");
        XCTAssertEqualObjects(labels[@"media_timeshift"], @"45");
        XCTAssertEqualObjects(labels[@"media_position"], @"1");
        return YES;
    }];
    [self waitForExpectationsWithTimeout:20. handler:nil];
    
    // Play for a while. No stream events must be received
    eventObserver = [NSNotificationCenter.defaultCenter addObserverForPlayerSingleHiddenEventNotificationUsingBlock:^(NSString * _Nonnull event, NSDictionary * _Nonnull labels) {
        XCTFail(@"No event must be received when playing");
    }];
    
    [self expectationForElapsedTimeInterval:1. withHandler:nil];
    [self waitForExpectationsWithTimeout:20. handler:^(NSError * _Nullable error) {
        [NSNotificationCenter.defaultCenter removeObserver:eventObserver];
    }];
    
    [self expectationForHiddenPlaybackEventNotificationWithHandler:^BOOL(NSString *event, NSDictionary *labels) {
        XCTAssertEqualObjects(labels[@"event_id"], @"stop");
        XCTAssertNotNil(labels[@"media_timeshift"]); // Can't compare to 45, because of chunk size
        XCTAssertEqualObjects(labels[@"media_position"], @"2");
        return YES;
    }];
    
    [self.mediaPlayerController reset];
    
    [self waitForExpectationsWithTimeout:20. handler:nil];
}

- (void)testVolumeLabel
{
    [self expectationForHiddenPlaybackEventNotificationWithHandler:^BOOL(NSString *event, NSDictionary *labels) {
        XCTAssertEqualObjects(labels[@"event_id"], @"play");
        XCTAssertEqualObjects(labels[@"media_volume"], @"0");
        return YES;
    }];
    
    self.mediaPlayerController.playerCreationBlock = ^(AVPlayer *player) {
        player.muted = YES;
    };
    [self.mediaPlayerController playURL:OnDemandTestURL()];
    
    [self waitForExpectationsWithTimeout:20. handler:nil];
    
    [self expectationForHiddenPlaybackEventNotificationWithHandler:^BOOL(NSString *event, NSDictionary *labels) {
        XCTAssertEqualObjects(labels[@"event_id"], @"pause");
        XCTAssertNotNil(labels[@"media_volume"]);
        return YES;
    }];
    
    self.mediaPlayerController.player.muted = NO;
    [self.mediaPlayerController pause];
    
    [self waitForExpectationsWithTimeout:20. handler:nil];
}

- (void)testBandwidthLabel
{
    [self expectationForHiddenPlaybackEventNotificationWithHandler:^BOOL(NSString *event, NSDictionary *labels) {
        XCTAssertEqualObjects(labels[@"event_id"], @"play");
        XCTAssertNotEqualObjects(labels[@"media_bandwidth"], @"0");
        return YES;
    }];
    
    [self.mediaPlayerController playURL:OnDemandTestURL()];
    
    [self waitForExpectationsWithTimeout:20. handler:nil];
    
    [self expectationForHiddenPlaybackEventNotificationWithHandler:^BOOL(NSString *event, NSDictionary *labels) {
        XCTAssertEqualObjects(labels[@"event_id"], @"stop");
        XCTAssertNil(labels[@"media_bandwidth"]);
        return YES;
    }];
    
    [self.mediaPlayerController reset];
    
    [self waitForExpectationsWithTimeout:20. handler:nil];
}

- (void)testEnvironment
{
    [self expectationForHiddenPlaybackEventNotificationWithHandler:^BOOL(NSString *event, NSDictionary *labels) {
        XCTAssertEqualObjects(labels[@"event_id"], @"play");
        XCTAssertEqualObjects(labels[@"media_embedding_environment"], @"preprod");
        return YES;
    }];
    
    [self.mediaPlayerController playURL:OnDemandTestURL()];
    
    [self waitForExpectationsWithTimeout:20. handler:nil];
    
    [self expectationForHiddenPlaybackEventNotificationWithHandler:^BOOL(NSString *event, NSDictionary *labels) {
        XCTAssertEqualObjects(labels[@"event_id"], @"stop");
        XCTAssertEqualObjects(labels[@"media_embedding_environment"], @"preprod");
        return YES;
    }];
    
    [self.mediaPlayerController reset];
    
    [self waitForExpectationsWithTimeout:20. handler:nil];
}

- (void)testSubtitles
{
    MACaptionAppearanceSetDisplayType(kMACaptionAppearanceDomainUser, kMACaptionAppearanceDisplayTypeAutomatic);
    
    [self expectationForHiddenPlaybackEventNotificationWithHandler:^BOOL(NSString *event, NSDictionary *labels) {
        XCTAssertEqualObjects(labels[@"event_id"], @"play");
        XCTAssertEqualObjects(labels[@"media_subtitles_on"], @"true");
        return YES;
    }];
    
    [self.mediaPlayerController playURL:OnDemandTestURL()];
    
    [self waitForExpectationsWithTimeout:20. handler:nil];
    
    [self expectationForHiddenPlaybackEventNotificationWithHandler:^BOOL(NSString *event, NSDictionary *labels) {
        XCTAssertEqualObjects(labels[@"event_id"], @"stop");
        XCTAssertEqualObjects(labels[@"media_subtitles_on"], @"false");
        return YES;
    }];
    
    [self.mediaPlayerController reset];
    
    [self waitForExpectationsWithTimeout:20. handler:nil];
}

- (void)testNoSubtitles
{
    MACaptionAppearanceSetDisplayType(kMACaptionAppearanceDomainUser, kMACaptionAppearanceDisplayTypeAutomatic);
    
    [self expectationForHiddenPlaybackEventNotificationWithHandler:^BOOL(NSString *event, NSDictionary *labels) {
        XCTAssertEqualObjects(labels[@"event_id"], @"play");
        XCTAssertEqualObjects(labels[@"media_subtitles_on"], @"false");
        return YES;
    }];
    
    [self.mediaPlayerController playURL:LiveTestURL()];
    
    [self waitForExpectationsWithTimeout:20. handler:nil];
    
    [self expectationForHiddenPlaybackEventNotificationWithHandler:^BOOL(NSString *event, NSDictionary *labels) {
        XCTAssertEqualObjects(labels[@"event_id"], @"stop");
        XCTAssertEqualObjects(labels[@"media_subtitles_on"], @"false");
        return YES;
    }];
    
    [self.mediaPlayerController reset];
    
    [self waitForExpectationsWithTimeout:20. handler:nil];
}

- (void)testNonSelectedSegmentPlayback
{
    [self expectationForHiddenPlaybackEventNotificationWithHandler:^BOOL(NSString *event, NSDictionary *labels) {
        XCTAssertEqualObjects(labels[@"event_id"], @"play");
        XCTAssertEqualObjects(labels[@"stream_name"], @"full");
        XCTAssertNil(labels[@"segment_name"]);
        XCTAssertEqualObjects(labels[@"overridable_name"], @"full");
        return YES;
    }];
    
    NSDictionary<NSString *, NSString *> *labels = @{ @"stream_name" : @"full",
                                                      @"overridable_name" : @"full" };
    
    Segment *segment = [Segment segmentWithName:@"segment" timeRange:CMTimeRangeMake(CMTimeMakeWithSeconds(2., NSEC_PER_SEC), CMTimeMakeWithSeconds(3., NSEC_PER_SEC))];
    [self.mediaPlayerController playURL:OnDemandTestURL() atPosition:nil withSegments:@[segment] analyticsLabels:labels userInfo:nil];
    
    [self waitForExpectationsWithTimeout:20. handler:nil];
    
    // Let the segment be played through. No events must be received
    id eventObserver = [NSNotificationCenter.defaultCenter addObserverForPlayerSingleHiddenEventNotificationUsingBlock:^(NSString * _Nonnull event, NSDictionary * _Nonnull labels) {
        XCTFail(@"No event must be received");
    }];
    
    [self expectationForElapsedTimeInterval:3. withHandler:nil];
    
    [self waitForExpectationsWithTimeout:20. handler:^(NSError * _Nullable error) {
        [NSNotificationCenter.defaultCenter removeObserver:eventObserver];
    }];
    
    // Pause playback. Expect full-length information
    [self expectationForHiddenPlaybackEventNotificationWithHandler:^BOOL(NSString *event, NSDictionary *labels) {
        XCTAssertEqualObjects(labels[@"event_id"], @"pause");
        XCTAssertEqualObjects(labels[@"stream_name"], @"full");
        XCTAssertNil(labels[@"segment_name"]);
        XCTAssertEqualObjects(labels[@"overridable_name"], @"full");
        return YES;
    }];
    
    [self.mediaPlayerController pause];
    
    [self waitForExpectationsWithTimeout:20. handler:nil];
    
    // Resume playback. Expect full-length information
    [self expectationForHiddenPlaybackEventNotificationWithHandler:^BOOL(NSString *event, NSDictionary *labels) {
        XCTAssertEqualObjects(labels[@"event_id"], @"play");
        XCTAssertEqualObjects(labels[@"stream_name"], @"full");
        XCTAssertNil(labels[@"segment_name"]);
        XCTAssertEqualObjects(labels[@"overridable_name"], @"full");
        return YES;
    }];
    
    [self.mediaPlayerController play];
    
    [self waitForExpectationsWithTimeout:20. handler:nil];
    
    id eventObserver2 = [NSNotificationCenter.defaultCenter addObserverForPlayerSingleHiddenEventNotificationUsingBlock:^(NSString * _Nonnull event, NSDictionary * _Nonnull labels) {
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
    [self expectationForHiddenPlaybackEventNotificationWithHandler:^BOOL(NSString *event, NSDictionary *labels) {
        XCTAssertEqualObjects(labels[@"event_id"], @"play");
        XCTAssertEqualObjects(labels[@"stream_name"], @"full");
        XCTAssertEqualObjects(labels[@"segment_name"], @"segment");
        XCTAssertEqualObjects(labels[@"overridable_name"], @"segment");
        XCTAssertEqualObjects(labels[@"media_position"], @"2");
        return YES;
    }];
    
    NSDictionary<NSString *, NSString *> *labels = @{ @"stream_name" : @"full",
                                                      @"overridable_name" : @"full" };
    
    Segment *segment = [Segment segmentWithName:@"segment" timeRange:CMTimeRangeMake(CMTimeMakeWithSeconds(2., NSEC_PER_SEC), CMTimeMakeWithSeconds(10., NSEC_PER_SEC))];
    [self.mediaPlayerController playURL:OnDemandTestURL() atIndex:0 position:nil inSegments:@[segment] withAnalyticsLabels:labels userInfo:nil];
    
    [self waitForExpectationsWithTimeout:20. handler:nil];
    
    // Pause playback. Expect segment information
    [self expectationForHiddenPlaybackEventNotificationWithHandler:^BOOL(NSString *event, NSDictionary *labels) {
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
    [self expectationForHiddenPlaybackEventNotificationWithHandler:^BOOL(NSString *event, NSDictionary *labels) {
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
    [self expectationForHiddenPlaybackEventNotificationWithHandler:^BOOL(NSString *event, NSDictionary *labels) {
        XCTAssertEqualObjects(labels[@"event_id"], @"play");
        XCTAssertEqualObjects(labels[@"stream_name"], @"full");
        XCTAssertEqualObjects(labels[@"segment_name"], @"segment");
        XCTAssertEqualObjects(labels[@"overridable_name"], @"segment");
        XCTAssertEqualObjects(labels[@"media_position"], @"50");
        return YES;
    }];
    
    NSDictionary<NSString *, NSString *> *labels = @{ @"stream_name" : @"full",
                                                      @"overridable_name" : @"full" };
    
    Segment *segment = [Segment segmentWithName:@"segment" timeRange:CMTimeRangeMake(CMTimeMakeWithSeconds(50., NSEC_PER_SEC), CMTimeMakeWithSeconds(3., NSEC_PER_SEC))];
    [self.mediaPlayerController playURL:OnDemandTestURL() atIndex:0 position:nil inSegments:@[segment] withAnalyticsLabels:labels userInfo:nil];
    
    [self waitForExpectationsWithTimeout:20. handler:nil];
    
    // Let the segment be played through until we receive the transition notifications (since both are the same, capture
    // them with a single expectation)
    
    __block BOOL segmentEndReceived = NO;
    __block BOOL fullPlayReceived = NO;
    
    [self expectationForHiddenPlaybackEventNotificationWithHandler:^BOOL(NSString *event, NSDictionary *labels) {
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
    id prepareObserver = [NSNotificationCenter.defaultCenter addObserverForPlayerSingleHiddenEventNotificationUsingBlock:^(NSString * _Nonnull event, NSDictionary * _Nonnull labels) {
        XCTFail(@"No event must be received when preparing a player");
    }];
    
    NSDictionary<NSString *, NSString *> *labels = @{ @"stream_name" : @"full",
                                                      @"overridable_name" : @"full" };
    
    Segment *segment = [Segment segmentWithName:@"segment" timeRange:CMTimeRangeMake(CMTimeMakeWithSeconds(50., NSEC_PER_SEC), CMTimeMakeWithSeconds(3., NSEC_PER_SEC))];
    [self.mediaPlayerController prepareToPlayURL:OnDemandTestURL() atIndex:0 position:nil inSegments:@[segment] withAnalyticsLabels:labels userInfo:nil completionHandler:^{
        [NSNotificationCenter.defaultCenter removeObserver:prepareObserver];
    }];
    
    // Now playing must trigger a play event
    [self expectationForHiddenPlaybackEventNotificationWithHandler:^BOOL(NSString *event, NSDictionary *labels) {
        XCTAssertEqualObjects(labels[@"event_id"], @"play");
        XCTAssertEqualObjects(labels[@"stream_name"], @"full");
        XCTAssertEqualObjects(labels[@"segment_name"], @"segment");
        XCTAssertEqualObjects(labels[@"overridable_name"], @"segment");
        XCTAssertEqualObjects(labels[@"media_position"], @"50");
        return YES;
    }];
    
    [self.mediaPlayerController play];
    
    [self waitForExpectationsWithTimeout:20. handler:nil];
    
    [self expectationForHiddenPlaybackEventNotificationWithHandler:^BOOL(NSString *event, NSDictionary *labels) {
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
    [self expectationForHiddenPlaybackEventNotificationWithHandler:^BOOL(NSString *event, NSDictionary *labels) {
        XCTAssertEqualObjects(labels[@"event_id"], @"play");
        XCTAssertEqualObjects(labels[@"stream_name"], @"full");
        XCTAssertNil(labels[@"segment_name"]);
        XCTAssertEqualObjects(labels[@"overridable_name"], @"full");
        XCTAssertEqualObjects(labels[@"media_position"], @"0");
        return YES;
    }];
    
    NSDictionary<NSString *, NSString *> *labels = @{ @"stream_name" : @"full",
                                                      @"overridable_name" : @"full" };
    
    Segment *segment = [Segment segmentWithName:@"segment" timeRange:CMTimeRangeMake(CMTimeMakeWithSeconds(50., NSEC_PER_SEC), CMTimeMakeWithSeconds(3., NSEC_PER_SEC))];
    [self.mediaPlayerController playURL:OnDemandTestURL() atPosition:nil withSegments:@[segment] analyticsLabels:labels userInfo:nil];
    
    [self waitForExpectationsWithTimeout:20. handler:nil];
    
    // Play for a while. No stream events must be received
    id eventObserver = [NSNotificationCenter.defaultCenter addObserverForPlayerSingleHiddenEventNotificationUsingBlock:^(NSString * _Nonnull event, NSDictionary * _Nonnull labels) {
        XCTFail(@"No event must be received when playing");
    }];
    
    [self expectationForElapsedTimeInterval:1. withHandler:nil];
    [self waitForExpectationsWithTimeout:20. handler:^(NSError * _Nullable error) {
        [NSNotificationCenter.defaultCenter removeObserver:eventObserver];
    }];
    
    // When selecting a segment, usual playback events due to seeking must be inhibited
    
    __block BOOL fullEndReceived = NO;
    __block BOOL segmentPlayReceived = NO;
    
    [self expectationForHiddenPlaybackEventNotificationWithHandler:^BOOL(NSString *event, NSDictionary *labels) {
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
    
    [self.mediaPlayerController seekToPosition:nil inSegment:segment withCompletionHandler:nil];
    
    [self waitForExpectationsWithTimeout:20. handler:nil];
}

- (void)testSegmentSelectionWhilePlayingSelectedSegment
{
    [self expectationForHiddenPlaybackEventNotificationWithHandler:^BOOL(NSString *event, NSDictionary *labels) {
        XCTAssertEqualObjects(labels[@"event_id"], @"play");
        XCTAssertEqualObjects(labels[@"stream_name"], @"full");
        XCTAssertEqualObjects(labels[@"segment_name"], @"segment1");
        XCTAssertEqualObjects(labels[@"overridable_name"], @"segment1");
        XCTAssertEqualObjects(labels[@"media_position"], @"50");
        return YES;
    }];
    
    Segment *segment1 = [Segment segmentWithName:@"segment1" timeRange:CMTimeRangeMake(CMTimeMakeWithSeconds(50., NSEC_PER_SEC), CMTimeMakeWithSeconds(10., NSEC_PER_SEC))];
    Segment *segment2 = [Segment segmentWithName:@"segment2" timeRange:CMTimeRangeMake(CMTimeMakeWithSeconds(100., NSEC_PER_SEC), CMTimeMakeWithSeconds(10., NSEC_PER_SEC))];
    
    NSDictionary<NSString *, NSString *> *labels = @{ @"stream_name" : @"full",
                                                      @"overridable_name" : @"full" };
    
    [self.mediaPlayerController playURL:OnDemandTestURL() atIndex:0 position:nil inSegments:@[segment1, segment2] withAnalyticsLabels:labels userInfo:nil];
    
    [self waitForExpectationsWithTimeout:20. handler:nil];
    
    // Expect segment transition (but no playback events) when selecting another segment
    
    __block BOOL segment1EndReceived = NO;
    __block BOOL segment2PlayReceived = NO;
    
    [self expectationForHiddenPlaybackEventNotificationWithHandler:^BOOL(NSString *event, NSDictionary *labels) {
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
    
    [self.mediaPlayerController seekToPosition:nil inSegment:segment2 withCompletionHandler:nil];
    
    [self waitForExpectationsWithTimeout:20. handler:nil];
}

- (void)testTransitionFromSelectedSegmentIntoNonSelectedContiguousSegment
{
    [self expectationForHiddenPlaybackEventNotificationWithHandler:^BOOL(NSString *event, NSDictionary *labels) {
        XCTAssertEqualObjects(labels[@"event_id"], @"play");
        XCTAssertEqualObjects(labels[@"stream_name"], @"full");
        XCTAssertEqualObjects(labels[@"segment_name"], @"segment1");
        XCTAssertEqualObjects(labels[@"overridable_name"], @"segment1");
        XCTAssertEqualObjects(labels[@"media_position"], @"20");
        return YES;
    }];
    
    Segment *segment1 = [Segment segmentWithName:@"segment1" timeRange:CMTimeRangeMake(CMTimeMakeWithSeconds(20., NSEC_PER_SEC), CMTimeMakeWithSeconds(3., NSEC_PER_SEC))];
    Segment *segment2 = [Segment segmentWithName:@"segment2" timeRange:CMTimeRangeMake(CMTimeMakeWithSeconds(23., NSEC_PER_SEC), CMTimeMakeWithSeconds(3., NSEC_PER_SEC))];
    
    NSDictionary<NSString *, NSString *> *labels = @{ @"stream_name" : @"full",
                                                      @"overridable_name" : @"full" };
    
    [self.mediaPlayerController playURL:OnDemandTestURL() atIndex:0 position:nil inSegments:@[segment1, segment2] withAnalyticsLabels:labels userInfo:nil];
    
    [self waitForExpectationsWithTimeout:20. handler:nil];
    
    // Let the segment be played through. A transition into the full-length is expected since the second segment
    // is not selected
    
    __block BOOL segment1EndReceived = NO;
    __block BOOL fullLengthPlayReceived = NO;
    
    [self expectationForHiddenPlaybackEventNotificationWithHandler:^BOOL(NSString *event, NSDictionary *labels) {
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
    [self expectationForHiddenPlaybackEventNotificationWithHandler:^BOOL(NSString *event, NSDictionary *labels) {
        XCTAssertEqualObjects(labels[@"event_id"], @"play");
        XCTAssertEqualObjects(labels[@"stream_name"], @"full");
        XCTAssertEqualObjects(labels[@"segment_name"], @"segment");
        XCTAssertEqualObjects(labels[@"overridable_name"], @"segment");
        XCTAssertEqualObjects(labels[@"media_position"], @"50");
        return YES;
    }];
    
    Segment *segment = [Segment segmentWithName:@"segment" timeRange:CMTimeRangeMake(CMTimeMakeWithSeconds(50., NSEC_PER_SEC), CMTimeMakeWithSeconds(10., NSEC_PER_SEC))];
    
    NSDictionary<NSString *, NSString *> *labels = @{ @"stream_name" : @"full",
                                                      @"overridable_name" : @"full" };
    
    [self.mediaPlayerController playURL:OnDemandTestURL() atIndex:0 position:nil inSegments:@[segment] withAnalyticsLabels:labels userInfo:nil];
    
    [self waitForExpectationsWithTimeout:20. handler:nil];
    
    // Expect segment transition (but no playback events) when selecting another segment
    
    __block BOOL segmentEndReceived = NO;
    __block BOOL segmentPlayReceived = NO;
    
    [self expectationForHiddenPlaybackEventNotificationWithHandler:^BOOL(NSString *event, NSDictionary *labels) {
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
    
    [self.mediaPlayerController seekToPosition:nil inSegment:segment withCompletionHandler:nil];
    
    [self waitForExpectationsWithTimeout:20. handler:nil];
}

- (void)testSeekOutsideSelectedSegment
{
    [self expectationForHiddenPlaybackEventNotificationWithHandler:^BOOL(NSString *event, NSDictionary *labels) {
        XCTAssertEqualObjects(labels[@"event_id"], @"play");
        XCTAssertEqualObjects(labels[@"stream_name"], @"full");
        XCTAssertEqualObjects(labels[@"segment_name"], @"segment1");
        XCTAssertEqualObjects(labels[@"overridable_name"], @"segment1");
        XCTAssertEqualObjects(labels[@"media_position"], @"50");
        return YES;
    }];
    
    Segment *segment1 = [Segment segmentWithName:@"segment1" timeRange:CMTimeRangeMake(CMTimeMakeWithSeconds(50., NSEC_PER_SEC), CMTimeMakeWithSeconds(10., NSEC_PER_SEC))];
    Segment *segment2 = [Segment segmentWithName:@"segment2" timeRange:CMTimeRangeMake(CMTimeMakeWithSeconds(60., NSEC_PER_SEC), CMTimeMakeWithSeconds(20., NSEC_PER_SEC))];
    
    NSDictionary<NSString *, NSString *> *labels = @{ @"stream_name" : @"full",
                                                      @"overridable_name" : @"full" };
    
    [self.mediaPlayerController playURL:OnDemandTestURL() atIndex:0 position:nil inSegments:@[segment1, segment2] withAnalyticsLabels:labels userInfo:nil];
    
    [self waitForExpectationsWithTimeout:20. handler:nil];
    
    // Expect transition into the full-length since, even if seeking resumes in another segment (since this segment has
    // not been selected, we don't want to track it)
    
    __block BOOL segment1SeekReceived = NO;
    __block BOOL segment1StopReceived = NO;
    __block BOOL fullLengthPlayReceived = NO;
    
    [self expectationForHiddenPlaybackEventNotificationWithHandler:^BOOL(NSString *event, NSDictionary *labels) {
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
    
    CMTime seekTime = CMTimeAdd(CMTimeRangeGetEnd(segment1.srg_timeRange), CMTimeMakeWithSeconds(10., NSEC_PER_SEC));
    [self.mediaPlayerController seekToPosition:[SRGPosition positionAtTime:seekTime] withCompletionHandler:nil];
    
    [self waitForExpectationsWithTimeout:20. handler:nil];
}

- (void)testSeekWithinSelectedSegment
{
    [self expectationForHiddenPlaybackEventNotificationWithHandler:^BOOL(NSString *event, NSDictionary *labels) {
        XCTAssertEqualObjects(labels[@"event_id"], @"play");
        XCTAssertEqualObjects(labels[@"stream_name"], @"full");
        XCTAssertEqualObjects(labels[@"segment_name"], @"segment");
        XCTAssertEqualObjects(labels[@"overridable_name"], @"segment");
        XCTAssertEqualObjects(labels[@"media_position"], @"50");
        return YES;
    }];
    
    Segment *segment = [Segment segmentWithName:@"segment" timeRange:CMTimeRangeMake(CMTimeMakeWithSeconds(50., NSEC_PER_SEC), CMTimeMakeWithSeconds(10., NSEC_PER_SEC))];
    
    NSDictionary<NSString *, NSString *> *labels = @{ @"stream_name" : @"full",
                                                      @"overridable_name" : @"full" };
    
    [self.mediaPlayerController playURL:OnDemandTestURL() atIndex:0 position:nil inSegments:@[segment] withAnalyticsLabels:labels userInfo:nil];
    
    [self waitForExpectationsWithTimeout:20. handler:nil];
    
    // Expect seek - play transition with segment labels
    
    __block BOOL segmentSeekReceived = NO;
    __block BOOL segmentPlayReceived = NO;
    
    [self expectationForHiddenPlaybackEventNotificationWithHandler:^BOOL(NSString *event, NSDictionary *labels) {
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
    
    CMTime seekTime = CMTimeAdd(segment.srg_timeRange.start, CMTimeMakeWithSeconds(3., NSEC_PER_SEC));
    [self.mediaPlayerController seekToPosition:[SRGPosition positionAtTime:seekTime] withCompletionHandler:nil];
    
    [self waitForExpectationsWithTimeout:20. handler:nil];
}

- (void)testSelectedSegmentAtStreamEnd
{
    // Precise timing information gathered from the stream itself
    Segment *segment = [Segment segmentWithName:@"segment" timeRange:CMTimeRangeMake(CMTimeMakeWithSeconds(1795.045, NSEC_PER_SEC), CMTimeMakeWithSeconds(5., NSEC_PER_SEC))];
    
    [self expectationForHiddenPlaybackEventNotificationWithHandler:^BOOL(NSString *event, NSDictionary *labels) {
        XCTAssertEqualObjects(labels[@"event_id"], @"play");
        XCTAssertEqualObjects(labels[@"stream_name"], @"full");
        XCTAssertEqualObjects(labels[@"segment_name"], @"segment");
        XCTAssertEqualObjects(labels[@"overridable_name"], @"segment");
        XCTAssertEqualObjects(labels[@"media_position"], @"1795");
        return YES;
    }];
    
    NSDictionary<NSString *, NSString *> *labels = @{ @"stream_name" : @"full",
                                                      @"overridable_name" : @"full" };
    
    [self.mediaPlayerController playURL:OnDemandTestURL() atIndex:0 position:nil inSegments:@[segment] withAnalyticsLabels:labels userInfo:nil];
    
    [self waitForExpectationsWithTimeout:20. handler:nil];
    
    XCTAssertEqualObjects(self.mediaPlayerController.currentSegment, segment);
    XCTAssertEqualObjects(self.mediaPlayerController.selectedSegment, segment);
    
    // Expect end of segment and play / eof for the full-length (which does not harm for statistics)
    
    __block BOOL segmentEofReceived = NO;
    __block BOOL fullLengthPlayReceived = NO;
    __block BOOL fullLengthEofReceived = NO;
    
    [self expectationForHiddenPlaybackEventNotificationWithHandler:^BOOL(NSString *event, NSDictionary *labels) {
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
    [self expectationForHiddenPlaybackEventNotificationWithHandler:^BOOL(NSString *event, NSDictionary *labels) {
        XCTAssertEqualObjects(labels[@"event_id"], @"play");
        XCTAssertEqualObjects(labels[@"stream_name"], @"full");
        XCTAssertEqualObjects(labels[@"segment_name"], @"segment");
        XCTAssertEqualObjects(labels[@"overridable_name"], @"segment");
        XCTAssertEqualObjects(labels[@"media_position"], @"50");
        return YES;
    }];
    
    Segment *segment = [Segment segmentWithName:@"segment" timeRange:CMTimeRangeMake(CMTimeMakeWithSeconds(50., NSEC_PER_SEC), CMTimeMakeWithSeconds(10., NSEC_PER_SEC))];
    
    NSDictionary<NSString *, NSString *> *labels = @{ @"stream_name" : @"full",
                                                      @"overridable_name" : @"full" };
    
    [self.mediaPlayerController playURL:OnDemandTestURL() atIndex:0 position:nil inSegments:@[segment] withAnalyticsLabels:labels userInfo:nil];
    
    [self waitForExpectationsWithTimeout:20. handler:nil];
    
    // Play for a while. No stream events must be received
    id eventObserver = [NSNotificationCenter.defaultCenter addObserverForPlayerSingleHiddenEventNotificationUsingBlock:^(NSString * _Nonnull event, NSDictionary * _Nonnull labels) {
        XCTFail(@"No event must be received when playing");
    }];
    
    [self expectationForElapsedTimeInterval:1. withHandler:nil];
    [self waitForExpectationsWithTimeout:20. handler:^(NSError * _Nullable error) {
        [NSNotificationCenter.defaultCenter removeObserver:eventObserver];
    }];
    
    // Expect stop event with segment labels
    
    [self expectationForHiddenPlaybackEventNotificationWithHandler:^BOOL(NSString *event, NSDictionary *labels) {
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
    [self expectationForHiddenPlaybackEventNotificationWithHandler:^BOOL(NSString *event, NSDictionary *labels) {
        XCTAssertEqualObjects(labels[@"event_id"], @"play");
        XCTAssertEqualObjects(labels[@"stream_name"], @"full");
        XCTAssertNil(labels[@"segment_name"]);
        XCTAssertEqualObjects(labels[@"overridable_name"], @"full");
        return YES;
    }];
    
    NSDictionary<NSString *, NSString *> *labels = @{ @"stream_name" : @"full",
                                                      @"overridable_name" : @"full" };
    
    Segment *segment = [Segment blockedSegmentWithName:@"segment" timeRange:CMTimeRangeMake(CMTimeMakeWithSeconds(50., NSEC_PER_SEC), CMTimeMakeWithSeconds(10., NSEC_PER_SEC))];
    [self.mediaPlayerController playURL:OnDemandTestURL() atPosition:nil withSegments:@[segment] analyticsLabels:labels userInfo:nil];
    
    [self waitForExpectationsWithTimeout:20. handler:nil];
    
    // Expect seek and play on the full-length (corresponding to the segment being skipped)
    
    __block BOOL fullLengthSeekReceived = NO;
    __block BOOL fullLengthPlayReceived = NO;
    
    [self expectationForHiddenPlaybackEventNotificationWithHandler:^BOOL(NSString *event, NSDictionary *labels) {
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
    
    [self.mediaPlayerController seekToPosition:nil inSegment:segment withCompletionHandler:nil];
    
    [self waitForExpectationsWithTimeout:20. handler:nil];
}

- (void)testSeekIntoBlockedSegment
{
    [self expectationForHiddenPlaybackEventNotificationWithHandler:^BOOL(NSString *event, NSDictionary *labels) {
        XCTAssertEqualObjects(labels[@"event_id"], @"play");
        XCTAssertEqualObjects(labels[@"stream_name"], @"full");
        XCTAssertNil(labels[@"segment_name"]);
        XCTAssertEqualObjects(labels[@"overridable_name"], @"full");
        return YES;
    }];
    
    Segment *segment = [Segment blockedSegmentWithName:@"segment" timeRange:CMTimeRangeMake(CMTimeMakeWithSeconds(50., NSEC_PER_SEC), CMTimeMakeWithSeconds(10., NSEC_PER_SEC))];
    
    NSDictionary<NSString *, NSString *> *labels = @{ @"stream_name" : @"full",
                                                      @"overridable_name" : @"full" };
    
    [self.mediaPlayerController playURL:OnDemandTestURL() atPosition:nil withSegments:@[segment] analyticsLabels:labels userInfo:nil];
    
    [self waitForExpectationsWithTimeout:20. handler:nil];
    
    // Expect seek / play for the full-length
    
    __block BOOL fullLengthSeekReceived = NO;
    __block BOOL fullLengthPlayReceived = NO;
    
    [self expectationForHiddenPlaybackEventNotificationWithHandler:^BOOL(NSString *event, NSDictionary *labels) {
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
    
    [self.mediaPlayerController seekToPosition:[SRGPosition positionAtTimeInSeconds:55.] withCompletionHandler:nil];
    
    [self waitForExpectationsWithTimeout:20. handler:nil];
}

- (void)testPlayStartingWithBlockedSegment
{
    // Expect a play attempt at 50, then a seek / play transition to 60 because of the blocked segment
    
    __block BOOL fullLengthPlayAt50Received = NO;
    __block BOOL fullLengthSeekAt50Received = NO;
    __block BOOL fullLengthPlayAt60Received = NO;
    
    [self expectationForHiddenPlaybackEventNotificationWithHandler:^BOOL(NSString *event, NSDictionary *labels) {
        if ([event isEqualToString:@"play"]) {
            if ([labels[@"media_position"] isEqualToString:@"50"]) {
                XCTAssertFalse(fullLengthSeekAt50Received);
                XCTAssertFalse(fullLengthPlayAt60Received);
                
                XCTAssertEqualObjects(labels[@"stream_name"], @"full");
                XCTAssertNil(labels[@"segment_name"]);
                XCTAssertEqualObjects(labels[@"overridable_name"], @"full");
                
                fullLengthPlayAt50Received = YES;
            }
            else if ([labels[@"media_position"] isEqualToString:@"60"]) {
                XCTAssertEqualObjects(labels[@"stream_name"], @"full");
                XCTAssertNil(labels[@"segment_name"]);
                XCTAssertEqualObjects(labels[@"overridable_name"], @"full");
                
                fullLengthPlayAt60Received = YES;
            }
            else {
                XCTFail(@"Unexpected event %@", event);
            }
        }
        else if ([event isEqualToString:@"seek"]) {
            XCTAssertFalse(fullLengthPlayAt60Received);
            
            XCTAssertEqualObjects(labels[@"stream_name"], @"full");
            XCTAssertNil(labels[@"segment_name"]);
            XCTAssertEqualObjects(labels[@"overridable_name"], @"full");
            
            fullLengthSeekAt50Received = YES;
        }
        else {
            XCTFail(@"Unexpected event %@", event);
        }
        
        return fullLengthPlayAt50Received && fullLengthSeekAt50Received && fullLengthPlayAt60Received;
    }];
    
    NSDictionary<NSString *, NSString *> *labels = @{ @"stream_name" : @"full",
                                                      @"overridable_name" : @"full" };
    
    Segment *segment = [Segment blockedSegmentWithName:@"segment" timeRange:CMTimeRangeMake(CMTimeMakeWithSeconds(50., NSEC_PER_SEC), CMTimeMakeWithSeconds(10., NSEC_PER_SEC))];
    [self.mediaPlayerController playURL:OnDemandTestURL() atIndex:0 position:nil inSegments:@[segment] withAnalyticsLabels:labels userInfo:nil];
    
    [self waitForExpectationsWithTimeout:20. handler:nil];
}

- (void)testBlockedSegmentPlaythrough
{
    [self expectationForHiddenPlaybackEventNotificationWithHandler:^BOOL(NSString *event, NSDictionary *labels) {
        XCTAssertEqualObjects(labels[@"event_id"], @"play");
        XCTAssertEqualObjects(labels[@"stream_name"], @"full");
        XCTAssertNil(labels[@"segment_name"]);
        XCTAssertEqualObjects(labels[@"overridable_name"], @"full");
        return YES;
    }];
    
    Segment *segment = [Segment blockedSegmentWithName:@"segment" timeRange:CMTimeRangeMake(CMTimeMakeWithSeconds(2., NSEC_PER_SEC), CMTimeMakeWithSeconds(3., NSEC_PER_SEC))];
    
    NSDictionary<NSString *, NSString *> *labels = @{ @"stream_name" : @"full",
                                                      @"overridable_name" : @"full" };
    
    [self.mediaPlayerController playURL:OnDemandTestURL() atPosition:nil withSegments:@[segment] analyticsLabels:labels userInfo:nil];
    
    [self waitForExpectationsWithTimeout:20. handler:nil];
    
    // Play for a while. Expect seek / play for the full-length when skipping over the segment
    
    __block BOOL fullLengthSeekReceived = NO;
    __block BOOL fullLengthPlayReceived = NO;
    
    [self expectationForHiddenPlaybackEventNotificationWithHandler:^BOOL(NSString *event, NSDictionary *labels) {
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
    id eventObserver = [NSNotificationCenter.defaultCenter addObserverForPlayerSingleHiddenEventNotificationUsingBlock:^(NSString * _Nonnull event, NSDictionary * _Nonnull labels) {
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
    id eventObserver = [NSNotificationCenter.defaultCenter addObserverForPlayerSingleHiddenEventNotificationUsingBlock:^(NSString * _Nonnull event, NSDictionary * _Nonnull labels) {
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
    [self expectationForHiddenPlaybackEventNotificationWithHandler:^BOOL(NSString *event, NSDictionary *labels) {
        XCTAssertEqualObjects(event, @"play");
        return YES;
    }];
    
    [self.mediaPlayerController playURL:OnDemandTestURL()];
    
    [self waitForExpectationsWithTimeout:20. handler:nil];
    
    // Stop tracking while playing. Expect a stop to be received
    [self expectationForHiddenPlaybackEventNotificationWithHandler:^BOOL(NSString *event, NSDictionary *labels) {
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
    [self expectationForHiddenPlaybackEventNotificationWithHandler:^BOOL(NSString *event, NSDictionary *labels) {
        XCTAssertEqualObjects(labels[@"event_id"], @"play");
        XCTAssertEqualObjects(labels[@"stream_name"], @"full");
        XCTAssertEqualObjects(labels[@"segment_name"], @"segment");
        XCTAssertEqualObjects(labels[@"overridable_name"], @"segment");
        return YES;
    }];
    
    Segment *segment = [Segment segmentWithName:@"segment" timeRange:CMTimeRangeMake(CMTimeMakeWithSeconds(2., NSEC_PER_SEC), CMTimeMakeWithSeconds(3., NSEC_PER_SEC))];
    
    NSDictionary<NSString *, NSString *> *labels = @{ @"stream_name" : @"full",
                                                      @"overridable_name" : @"full" };
    
    [self.mediaPlayerController playURL:OnDemandTestURL() atIndex:0 position:nil inSegments:@[segment] withAnalyticsLabels:labels userInfo:nil];
    
    [self waitForExpectationsWithTimeout:20. handler:nil];
    
    // Stop tracking while playing. Expect a stop to be received with segment labels
    [self expectationForHiddenPlaybackEventNotificationWithHandler:^BOOL(NSString *event, NSDictionary *labels) {
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
    [self expectationForHiddenPlaybackEventNotificationWithHandler:^BOOL(NSString *event, NSDictionary *labels) {
        XCTAssertEqualObjects(event, @"play");
        return YES;
    }];
    
    [self.mediaPlayerController playURL:OnDemandTestURL()];
    
    [self waitForExpectationsWithTimeout:20. handler:nil];
    
    // Pause playback
    [self expectationForHiddenPlaybackEventNotificationWithHandler:^BOOL(NSString *event, NSDictionary *labels) {
        XCTAssertEqualObjects(event, @"pause");
        return YES;
    }];
    
    [self.mediaPlayerController pause];
    
    [self waitForExpectationsWithTimeout:20. handler:nil];
    
    // Stop tracking while paused. Expect a stop to be received
    [self expectationForHiddenPlaybackEventNotificationWithHandler:^BOOL(NSString *event, NSDictionary *labels) {
        XCTAssertEqualObjects(event, @"stop");
        return YES;
    }];
    
    XCTAssertEqual(self.mediaPlayerController.playbackState, SRGMediaPlayerPlaybackStatePaused);
    self.mediaPlayerController.tracked = NO;
    
    [self waitForExpectationsWithTimeout:20. handler:nil];
}

- (void)testDisableTrackingWhileSeeking
{
    // Wait until the media plays
    [self expectationForHiddenPlaybackEventNotificationWithHandler:^BOOL(NSString *event, NSDictionary *labels) {
        XCTAssertEqualObjects(event, @"play");
        return YES;
    }];
    
    [self.mediaPlayerController playURL:OnDemandTestURL()];
    
    [self waitForExpectationsWithTimeout:20. handler:nil];
    
    // Stop tracking while seeking. Expect a seek and a stop to be received in a row
    __block BOOL fullLengthSeekReceived = NO;
    __block BOOL fullLengthStopReceived = NO;
    
    [self expectationForHiddenPlaybackEventNotificationWithHandler:^BOOL(NSString *event, NSDictionary *labels) {
        if ([event isEqualToString:@"seek"]) {
            XCTAssertFalse(fullLengthStopReceived);
            fullLengthSeekReceived = YES;
        }
        else if ([event isEqualToString:@"stop"]) {
            fullLengthStopReceived = YES;
        }
        else {
            XCTFail(@"Unexpected event %@", event);
        }
        
        return fullLengthSeekReceived && fullLengthStopReceived;
    }];
    
    XCTAssertEqual(self.mediaPlayerController.playbackState, SRGMediaPlayerPlaybackStatePlaying);
    [self.mediaPlayerController seekToPosition:[SRGPosition positionAtTimeInSeconds:20.] withCompletionHandler:nil];
    self.mediaPlayerController.tracked = NO;
    
    [self waitForExpectationsWithTimeout:20. handler:nil];
}

- (void)testDisableTrackingWhilePausedInSegment
{
    // Wait until the media plays. Expect segment labels
    [self expectationForHiddenPlaybackEventNotificationWithHandler:^BOOL(NSString *event, NSDictionary *labels) {
        XCTAssertEqualObjects(labels[@"event_id"], @"play");
        XCTAssertEqualObjects(labels[@"stream_name"], @"full");
        XCTAssertEqualObjects(labels[@"segment_name"], @"segment");
        XCTAssertEqualObjects(labels[@"overridable_name"], @"segment");
        return YES;
    }];
    
    NSDictionary<NSString *, NSString *> *labels = @{ @"stream_name" : @"full",
                                                      @"overridable_name" : @"full" };
    
    Segment *segment = [Segment segmentWithName:@"segment" timeRange:CMTimeRangeMake(CMTimeMakeWithSeconds(2., NSEC_PER_SEC), CMTimeMakeWithSeconds(3., NSEC_PER_SEC))];
    [self.mediaPlayerController playURL:OnDemandTestURL() atIndex:0 position:nil inSegments:@[segment] withAnalyticsLabels:labels userInfo:nil];
    
    [self waitForExpectationsWithTimeout:20. handler:nil];
    
    // Pause playback. Expect a pause with segment labels
    [self expectationForHiddenPlaybackEventNotificationWithHandler:^BOOL(NSString *event, NSDictionary *labels) {
        XCTAssertEqualObjects(labels[@"event_id"], @"pause");
        XCTAssertEqualObjects(labels[@"stream_name"], @"full");
        XCTAssertEqualObjects(labels[@"segment_name"], @"segment");
        XCTAssertEqualObjects(labels[@"overridable_name"], @"segment");
        return YES;
    }];
    
    [self.mediaPlayerController pause];
    
    [self waitForExpectationsWithTimeout:20. handler:nil];
    
    // Stop tracking while paused. Expect a stop to be received with segment labels
    [self expectationForHiddenPlaybackEventNotificationWithHandler:^BOOL(NSString *event, NSDictionary *labels) {
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
    [self expectationForSingleNotification:SRGMediaPlayerPlaybackStateDidChangeNotification object:self.mediaPlayerController handler:^BOOL(NSNotification * _Nonnull notification) {
        XCTAssertEqual([notification.userInfo[SRGMediaPlayerPlaybackStateKey] integerValue], SRGMediaPlayerPlaybackStatePreparing);
        return YES;
    }];
    
    self.mediaPlayerController.tracked = NO;
    [self.mediaPlayerController playURL:OnDemandTestURL()];
    
    [self waitForExpectationsWithTimeout:20. handler:nil];
    
    // Enable tracking. Expect a play to be received
    [self expectationForHiddenPlaybackEventNotificationWithHandler:^BOOL(NSString *event, NSDictionary *labels) {
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
    
    NSDictionary<NSString *, NSString *> *labels = @{ @"stream_name" : @"full",
                                                      @"overridable_name" : @"full" };
    
    [self.mediaPlayerController playURL:OnDemandTestURL() atIndex:0 position:nil inSegments:@[segment] withAnalyticsLabels:labels userInfo:nil];
    
    [self waitForExpectationsWithTimeout:20. handler:nil];
    
    // Enable tracking. Expect a play to be received
    [self expectationForHiddenPlaybackEventNotificationWithHandler:^BOOL(NSString *event, NSDictionary *labels) {
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
    id eventObserver = [NSNotificationCenter.defaultCenter addObserverForPlayerSingleHiddenEventNotificationUsingBlock:^(NSString * _Nonnull event, NSDictionary * _Nonnull labels) {
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
    [self expectationForHiddenPlaybackEventNotificationWithHandler:^BOOL(NSString *event, NSDictionary *labels) {
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
    id eventObserver = [NSNotificationCenter.defaultCenter addObserverForPlayerSingleHiddenEventNotificationUsingBlock:^(NSString * _Nonnull event, NSDictionary * _Nonnull labels) {
        XCTFail(@"No event must be received when tracking has been disabled");
    }];
    
    [self expectationForSingleNotification:SRGMediaPlayerPlaybackStateDidChangeNotification object:self.mediaPlayerController handler:^BOOL(NSNotification * _Nonnull notification) {
        return [notification.userInfo[SRGMediaPlayerPlaybackStateKey] integerValue] == SRGMediaPlayerPlaybackStatePlaying;
    }];
    
    self.mediaPlayerController.tracked = NO;
    Segment *segment = [Segment segmentWithName:@"segment" timeRange:CMTimeRangeMake(CMTimeMakeWithSeconds(2., NSEC_PER_SEC), CMTimeMakeWithSeconds(3., NSEC_PER_SEC))];
    
    NSDictionary<NSString *, NSString *> *labels = @{ @"stream_name" : @"full",
                                                      @"overridable_name" : @"full" };
    
    [self.mediaPlayerController playURL:OnDemandTestURL() atIndex:0 position:nil inSegments:@[segment] withAnalyticsLabels:labels userInfo:nil];
    
    [self waitForExpectationsWithTimeout:20. handler:^(NSError * _Nullable error) {
        [NSNotificationCenter.defaultCenter removeObserver:eventObserver];
    }];
    
    // Enable tracking. Expect a play to be received, with segment labels
    [self expectationForHiddenPlaybackEventNotificationWithHandler:^BOOL(NSString *event, NSDictionary *labels) {
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

- (void)testEnableTrackingWhileSeeking
{
    // Wait until the player is playing. No event must be received since tracking is not enabled yet
    id eventObserver = [NSNotificationCenter.defaultCenter addObserverForPlayerSingleHiddenEventNotificationUsingBlock:^(NSString * _Nonnull event, NSDictionary * _Nonnull labels) {
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
    
    // Enable tracking right after seeking. Expect a play to be received, and the initial seek reflecting the player state
    __block BOOL fullLengthPlayReceived = NO;
    __block BOOL fullLengthSeekReceived = NO;
    
    [self expectationForHiddenPlaybackEventNotificationWithHandler:^BOOL(NSString *event, NSDictionary *labels) {
        if ([event isEqualToString:@"play"]) {
            XCTAssertFalse(fullLengthSeekReceived);
            fullLengthPlayReceived = YES;
        }
        else if ([event isEqualToString:@"seek"]) {
            fullLengthSeekReceived = YES;
        }
        else {
            XCTFail(@"Unexpected event %@", event);
        }
        
        return fullLengthPlayReceived && fullLengthSeekReceived;
    }];
    
    XCTAssertEqual(self.mediaPlayerController.playbackState, SRGMediaPlayerPlaybackStatePlaying);
    [self.mediaPlayerController seekToPosition:[SRGPosition positionAtTimeInSeconds:20.] withCompletionHandler:nil];
    self.mediaPlayerController.tracked = YES;
    
    [self waitForExpectationsWithTimeout:20. handler:nil];
}

- (void)testEnableTrackingWhilePaused
{
    // Wait until the player is playing. No event must be received since tracking is not enabled yet
    id eventObserver = [NSNotificationCenter.defaultCenter addObserverForPlayerSingleHiddenEventNotificationUsingBlock:^(NSString * _Nonnull event, NSDictionary * _Nonnull labels) {
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
    
    [self expectationForHiddenPlaybackEventNotificationWithHandler:^BOOL(NSString *event, NSDictionary *labels) {
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
    [self expectationForHiddenPlaybackEventNotificationWithHandler:^BOOL(NSString *event, NSDictionary *labels) {
        XCTAssertEqualObjects(event, @"play");
        return YES;
    }];
    
    [self.mediaPlayerController playURL:OnDemandTestURL()];
    
    [self waitForExpectationsWithTimeout:20. handler:nil];
    
    // Stop tracking twice while playing. Expect a single stop to be received
    __block NSInteger stopEventCount = 0;
    id endEventObserver = [NSNotificationCenter.defaultCenter addObserverForPlayerSingleHiddenEventNotificationUsingBlock:^(NSString * _Nonnull event, NSDictionary * _Nonnull labels) {
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
        [NSNotificationCenter.defaultCenter removeObserver:endEventObserver];
    }];
    
    // Check we have received the stop notification only once
    XCTAssertEqual(stopEventCount, 1);
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
    id endEventObserver = [NSNotificationCenter.defaultCenter addObserverForPlayerSingleHiddenEventNotificationUsingBlock:^(NSString * _Nonnull event, NSDictionary * _Nonnull labels) {
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
    
    // Check we have received the play notification only once
    XCTAssertEqual(playEventCount, 1);
}

- (void)testOnDemandHeartbeatPlayPausePlay
{
    [self expectationForHiddenPlaybackEventNotificationWithHandler:^BOOL(NSString *event, NSDictionary *labels) {
        XCTAssertEqualObjects(labels[@"event_id"], @"play");
        XCTAssertEqualObjects(labels[@"stream_name"], @"full");
        return YES;
    }];
    
    NSDictionary<NSString *, NSString *> *labels = @{ @"stream_name" : @"full" };
    
    [self.mediaPlayerController playURL:OnDemandTestURL() atPosition:nil withSegments:nil analyticsLabels:labels userInfo:nil];
    
    [self waitForExpectationsWithTimeout:20. handler:nil];
    
    // For tests, heartbeat interval is set to 3 seconds.
    
    __block NSInteger heartbeatCount = 0;
    id heartbeatEventObserver = [NSNotificationCenter.defaultCenter addObserverForHiddenEventNotificationUsingBlock:^(NSString * _Nonnull event, NSDictionary * _Nonnull labels) {
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
        [NSNotificationCenter.defaultCenter removeObserver:heartbeatEventObserver];
    }];
    
    XCTAssertEqual(heartbeatCount, 2);
    
    [self expectationForHiddenPlaybackEventNotificationWithHandler:^BOOL(NSString *event, NSDictionary *labels) {
        XCTAssertEqualObjects(labels[@"event_id"], @"pause");
        XCTAssertEqualObjects(labels[@"stream_name"], @"full");
        return YES;
    }];
    
    [self.mediaPlayerController pause];
    
    [self waitForExpectationsWithTimeout:20. handler:nil];
    
    heartbeatCount = 0;
    heartbeatEventObserver = [NSNotificationCenter.defaultCenter addObserverForHiddenEventNotificationUsingBlock:^(NSString * _Nonnull event, NSDictionary * _Nonnull labels) {
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
        [NSNotificationCenter.defaultCenter removeObserver:heartbeatEventObserver];
    }];
    
    XCTAssertEqual(heartbeatCount, 0);
    
    [self expectationForHiddenPlaybackEventNotificationWithHandler:^BOOL(NSString *event, NSDictionary *labels) {
        XCTAssertEqualObjects(labels[@"event_id"], @"play");
        return YES;
    }];
    
    [self.mediaPlayerController play];
    
    [self waitForExpectationsWithTimeout:20. handler:nil];
    
    heartbeatCount = 0;
    heartbeatEventObserver = [NSNotificationCenter.defaultCenter addObserverForHiddenEventNotificationUsingBlock:^(NSString * _Nonnull event, NSDictionary * _Nonnull labels) {
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
        [NSNotificationCenter.defaultCenter removeObserver:heartbeatEventObserver];
    }];
    
    XCTAssertEqual(heartbeatCount, 2);
}

- (void)testLivestreamHeartbeatPlay
{
    [self expectationForHiddenPlaybackEventNotificationWithHandler:^BOOL(NSString *event, NSDictionary *labels) {
        XCTAssertEqualObjects(labels[@"event_id"], @"play");
        XCTAssertEqualObjects(labels[@"stream_name"], @"full");
        XCTAssertEqualObjects(labels[@"media_position"], @"0");
        XCTAssertEqualObjects(labels[@"media_timeshift"], @"0");
        return YES;
    }];
    
    NSDictionary<NSString *, NSString *> *labels = @{ @"stream_name" : @"full" };
    
    [self.mediaPlayerController playURL:LiveTestURL() atPosition:nil withSegments:nil analyticsLabels:labels userInfo:nil];
    
    [self waitForExpectationsWithTimeout:20. handler:nil];
    
    // For tests, heartbeat interval is set to 3 seconds.
    
    __block NSInteger heartbeatCount = 0;
    __block NSInteger liveHeartbeatCount = 0;
    id heartbeatEventObserver = [NSNotificationCenter.defaultCenter addObserverForHiddenEventNotificationUsingBlock:^(NSString * _Nonnull event, NSDictionary * _Nonnull labels) {
        if ([event isEqualToString:@"pos"]) {
            XCTAssertEqualObjects(labels[@"stream_name"], @"full");
            XCTAssertTrue(([labels[@"media_position"] integerValue] % 3) == 0);
            XCTAssertEqualObjects(labels[@"media_timeshift"], @"0");
            ++heartbeatCount;
        }
        else if ([event isEqualToString:@"uptime"]) {
            XCTAssertEqualObjects(labels[@"stream_name"], @"full");
            XCTAssertTrue(([labels[@"media_position"] integerValue] % 6) == 0);
            XCTAssertEqualObjects(labels[@"media_timeshift"], @"0");
            ++liveHeartbeatCount;
        }
    }];
    
    // Wait a little bit to collect potential events
    [self expectationForElapsedTimeInterval:14. withHandler:nil];
    [self waitForExpectationsWithTimeout:20. handler:^(NSError * _Nullable error) {
        [NSNotificationCenter.defaultCenter removeObserver:heartbeatEventObserver];
    }];
    
    XCTAssertEqual(heartbeatCount, 4);
    XCTAssertEqual(liveHeartbeatCount, 2);
}

- (void)testHeartbeatWithInitialSegmentSelectionAndPlaythrough
{
    [self expectationForHiddenPlaybackEventNotificationWithHandler:^BOOL(NSString *event, NSDictionary *labels) {
        XCTAssertEqualObjects(labels[@"event_id"], @"play");
        return YES;
    }];
    
    Segment *segment = [Segment segmentWithName:@"segment" timeRange:CMTimeRangeMake(CMTimeMakeWithSeconds(4., NSEC_PER_SEC), CMTimeMakeWithSeconds(7., NSEC_PER_SEC))];
    [self.mediaPlayerController playURL:OnDemandTestURL() atIndex:0 position:nil inSegments:@[segment] withAnalyticsLabels:nil userInfo:nil];
    
    [self waitForExpectationsWithTimeout:20. handler:nil];
    
    Segment *updatedSegment = [Segment segmentWithName:@"segment" timeRange:CMTimeRangeMake(CMTimeMakeWithSeconds(4., NSEC_PER_SEC), CMTimeMakeWithSeconds(7., NSEC_PER_SEC))];
    self.mediaPlayerController.segments = @[updatedSegment];
    
    // For tests, heartbeat interval is set to 3 seconds.
    
    __block NSInteger fullLengthHeartbeatCount = 0;
    __block NSInteger segmentHeartbeatCount = 0;
    id heartbeatEventObserver = [NSNotificationCenter.defaultCenter addObserverForHiddenEventNotificationUsingBlock:^(NSString * _Nonnull event, NSDictionary * _Nonnull labels) {
        if ([event isEqualToString:@"pos"]) {
            if ([labels[@"segment_name"] isEqualToString:@"segment"]) {
                ++segmentHeartbeatCount;
            }
            else {
                ++fullLengthHeartbeatCount;
            }
        }
    }];
    
    // Wait a little bit to collect potential events
    [self expectationForElapsedTimeInterval:14. withHandler:nil];
    [self waitForExpectationsWithTimeout:20. handler:^(NSError * _Nullable error) {
        [NSNotificationCenter.defaultCenter removeObserver:heartbeatEventObserver];
    }];
    
    XCTAssertEqual(fullLengthHeartbeatCount, 2);
    XCTAssertEqual(segmentHeartbeatCount, 2);
}

- (void)testHeartbeatWithSegmentSelectionAfterStartOnFullLength
{
    [self expectationForHiddenPlaybackEventNotificationWithHandler:^BOOL(NSString *event, NSDictionary *labels) {
        XCTAssertEqualObjects(labels[@"event_id"], @"play");
        return YES;
    }];
    
    NSDictionary<NSString *, NSString *> *labels = @{ @"stream_name" : @"full",
                                                      @"overridable_name" : @"full" };
    
    Segment *segment = [Segment segmentWithName:@"segment" timeRange:CMTimeRangeMake(CMTimeMakeWithSeconds(50., NSEC_PER_SEC), CMTimeMakeWithSeconds(7., NSEC_PER_SEC))];
    [self.mediaPlayerController playURL:OnDemandTestURL() atPosition:nil withSegments:@[segment] analyticsLabels:labels userInfo:nil];
    
    [self waitForExpectationsWithTimeout:20. handler:nil];
    
    // Play for a while. No stream events must be received
    id eventObserver = [NSNotificationCenter.defaultCenter addObserverForPlayerSingleHiddenEventNotificationUsingBlock:^(NSString * _Nonnull event, NSDictionary * _Nonnull labels) {
        XCTFail(@"No event must be received when playing");
    }];
    
    [self expectationForElapsedTimeInterval:1. withHandler:nil];
    [self waitForExpectationsWithTimeout:20. handler:^(NSError * _Nullable error) {
        [NSNotificationCenter.defaultCenter removeObserver:eventObserver];
    }];
    
    // When selecting a segment, usual playback events due to seeking must be inhibited
    
    __block BOOL fullEndReceived = NO;
    __block BOOL segmentPlayReceived = NO;
    
    [self expectationForHiddenPlaybackEventNotificationWithHandler:^BOOL(NSString *event, NSDictionary *labels) {
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
    
    [self.mediaPlayerController seekToPosition:nil inSegment:segment withCompletionHandler:nil];
    
    [self waitForExpectationsWithTimeout:20. handler:nil];
    
    Segment *updatedSegment = [Segment segmentWithName:@"segment" timeRange:CMTimeRangeMake(CMTimeMakeWithSeconds(50., NSEC_PER_SEC), CMTimeMakeWithSeconds(7., NSEC_PER_SEC))];
    self.mediaPlayerController.segments = @[updatedSegment];
    
    // For tests, heartbeat interval is set to 3 seconds.
    
    __block NSInteger fullLengthHeartbeatCount = 0;
    __block NSInteger segmentHeartbeatCount = 0;
    id heartbeatEventObserver = [NSNotificationCenter.defaultCenter addObserverForHiddenEventNotificationUsingBlock:^(NSString * _Nonnull event, NSDictionary * _Nonnull labels) {
        if ([event isEqualToString:@"pos"]) {
            if ([labels[@"segment_name"] isEqualToString:@"segment"]) {
                ++segmentHeartbeatCount;
            }
            else {
                ++fullLengthHeartbeatCount;
            }
        }
    }];
    
    // Wait a little bit to collect potential events
    [self expectationForElapsedTimeInterval:15. withHandler:nil];
    [self waitForExpectationsWithTimeout:20. handler:^(NSError * _Nullable error) {
        [NSNotificationCenter.defaultCenter removeObserver:heartbeatEventObserver];
    }];
    
    XCTAssertEqual(fullLengthHeartbeatCount, 2);
    XCTAssertEqual(segmentHeartbeatCount, 2);
}

- (void)testDVRLiveHeartbeats
{
    [self expectationForHiddenPlaybackEventNotificationWithHandler:^BOOL(NSString *event, NSDictionary *labels) {
        XCTAssertEqualObjects(labels[@"event_id"], @"play");
        XCTAssertEqualObjects(labels[@"stream_name"], @"full");
        return YES;
    }];
    
    NSDictionary<NSString *, NSString *> *labels = @{ @"stream_name" : @"full" };
    
    [self.mediaPlayerController playURL:DVRTestURL() atPosition:nil withSegments:nil analyticsLabels:labels userInfo:nil];
    
    [self waitForExpectationsWithTimeout:20. handler:nil];
    
    // For tests, heartbeat interval is set to 3 seconds.
    
    __block NSInteger heartbeatCount = 0;
    __block NSInteger liveHeartbeatCount = 0;
    id heartbeatEventObserver = [NSNotificationCenter.defaultCenter addObserverForHiddenEventNotificationUsingBlock:^(NSString * _Nonnull event, NSDictionary * _Nonnull labels) {
        if ([event isEqualToString:@"pos"]) {
            XCTAssertEqualObjects(labels[@"stream_name"], @"full");
            ++heartbeatCount;
        }
        else if ([event isEqualToString:@"uptime"]) {
            XCTAssertEqualObjects(labels[@"stream_name"], @"full");
            ++liveHeartbeatCount;
        }
    }];
    
    // Wait a little bit to collect potential events
    [self expectationForElapsedTimeInterval:14. withHandler:nil];
    [self waitForExpectationsWithTimeout:20. handler:^(NSError * _Nullable error) {
        [NSNotificationCenter.defaultCenter removeObserver:heartbeatEventObserver];
    }];
    
    XCTAssertEqual(heartbeatCount, 4);
    XCTAssertEqual(liveHeartbeatCount, 2);
}

- (void)testDVRTimeshiftHeartbeats
{
    [self expectationForHiddenPlaybackEventNotificationWithHandler:^BOOL(NSString *event, NSDictionary *labels) {
        XCTAssertEqualObjects(labels[@"event_id"], @"play");
        XCTAssertEqualObjects(labels[@"stream_name"], @"full");
        return YES;
    }];
    
    NSDictionary<NSString *, NSString *> *labels = @{ @"stream_name" : @"full" };
    
    [self.mediaPlayerController playURL:DVRTestURL() atPosition:nil withSegments:nil analyticsLabels:labels userInfo:nil];
    
    [self waitForExpectationsWithTimeout:20. handler:nil];
    
    // Seek to the past
    
    [self expectationForHiddenPlaybackEventNotificationWithHandler:^BOOL(NSString *event, NSDictionary *labels) {
        return [labels[@"event_id"] isEqualToString:@"play"];
    }];
    
    CMTime seekTime = CMTimeSubtract(CMTimeRangeGetEnd(self.mediaPlayerController.timeRange), CMTimeMakeWithSeconds(60., NSEC_PER_SEC));
    [self.mediaPlayerController seekToPosition:[SRGPosition positionAtTime:seekTime] withCompletionHandler:nil];
    
    [self waitForExpectationsWithTimeout:20. handler:nil];
    
    // For tests, heartbeat interval is set to 3 seconds.
    
    __block NSInteger heartbeatCount = 0;
    __block NSInteger liveHeartbeatCount = 0;
    id heartbeatEventObserver = [NSNotificationCenter.defaultCenter addObserverForHiddenEventNotificationUsingBlock:^(NSString * _Nonnull event, NSDictionary * _Nonnull labels) {
        if ([event isEqualToString:@"pos"]) {
            XCTAssertEqualObjects(labels[@"stream_name"], @"full");
            ++heartbeatCount;
        }
        else if ([event isEqualToString:@"uptime"]) {
            XCTAssertEqualObjects(labels[@"stream_name"], @"full");
            ++liveHeartbeatCount;
        }
    }];
    
    // Wait a little bit to collect potential events
    [self expectationForElapsedTimeInterval:14. withHandler:nil];
    [self waitForExpectationsWithTimeout:20. handler:^(NSError * _Nullable error) {
        [NSNotificationCenter.defaultCenter removeObserver:heartbeatEventObserver];
    }];
    
    XCTAssertEqual(heartbeatCount, 4);
    XCTAssertEqual(liveHeartbeatCount, 0);
}

- (void)testHeartbeatAfterDisablingTracking
{
    [self expectationForHiddenPlaybackEventNotificationWithHandler:^BOOL(NSString *event, NSDictionary *labels) {
        XCTAssertEqualObjects(labels[@"event_id"], @"play");
        return YES;
    }];
    
    [self.mediaPlayerController playURL:LiveTestURL() atPosition:nil withSegments:nil analyticsLabels:nil userInfo:nil];
    
    [self waitForExpectationsWithTimeout:20. handler:nil];
    
    // For tests, heartbeat interval is set to 3 seconds.
    
    __block NSInteger heartbeatCount1 = 0;
    __block NSInteger liveHeartbeatCount1 = 0;
    id heartbeatEventObserver1 = [NSNotificationCenter.defaultCenter addObserverForHiddenEventNotificationUsingBlock:^(NSString * _Nonnull event, NSDictionary * _Nonnull labels) {
        if ([event isEqualToString:@"pos"]) {
            ++heartbeatCount1;
        }
        else if ([event isEqualToString:@"uptime"]) {
            ++liveHeartbeatCount1;
        }
    }];
    
    // Wait a little bit to collect potential events
    [self expectationForElapsedTimeInterval:7. withHandler:nil];
    [self waitForExpectationsWithTimeout:20. handler:^(NSError * _Nullable error) {
        [NSNotificationCenter.defaultCenter removeObserver:heartbeatEventObserver1];
    }];
    
    XCTAssertEqual(heartbeatCount1, 2);
    XCTAssertEqual(liveHeartbeatCount1, 1);
    
    // Disable tracking. No heartbeats must be received anymore
    self.mediaPlayerController.tracked = NO;
    
    __block NSInteger heartbeatCount2 = 0;
    __block NSInteger liveHeartbeatCount2 = 0;
    id heartbeatEventObserver2 = [NSNotificationCenter.defaultCenter addObserverForHiddenEventNotificationUsingBlock:^(NSString * _Nonnull event, NSDictionary * _Nonnull labels) {
        if ([event isEqualToString:@"pos"]) {
            ++heartbeatCount2;
        }
        else if ([event isEqualToString:@"uptime"]) {
            ++liveHeartbeatCount2;
        }
    }];
    
    // Wait a little bit to collect potential events
    [self expectationForElapsedTimeInterval:7. withHandler:nil];
    [self waitForExpectationsWithTimeout:20. handler:^(NSError * _Nullable error) {
        [NSNotificationCenter.defaultCenter removeObserver:heartbeatEventObserver2];
    }];
    
    XCTAssertEqual(heartbeatCount2, 0);
    XCTAssertEqual(liveHeartbeatCount2, 0);
}

- (void)testHeartbeatAfterEnablingTracking
{
    // Wait until the player is playing. No event must be received since tracking is not enabled yet
    id eventObserver = [NSNotificationCenter.defaultCenter addObserverForPlayerSingleHiddenEventNotificationUsingBlock:^(NSString * _Nonnull event, NSDictionary * _Nonnull labels) {
        XCTFail(@"No event must be received when tracking has been disabled");
    }];
    
    [self expectationForSingleNotification:SRGMediaPlayerPlaybackStateDidChangeNotification object:self.mediaPlayerController handler:^BOOL(NSNotification * _Nonnull notification) {
        return [notification.userInfo[SRGMediaPlayerPlaybackStateKey] integerValue] == SRGMediaPlayerPlaybackStatePlaying;
    }];
    
    self.mediaPlayerController.tracked = NO;
    [self.mediaPlayerController playURL:LiveTestURL()];
    
    [self waitForExpectationsWithTimeout:20. handler:^(NSError * _Nullable error) {
        [NSNotificationCenter.defaultCenter removeObserver:eventObserver];
    }];
    
    // Play a little bit. No heartbeats must be received
    __block NSInteger heartbeatCount1 = 0;
    __block NSInteger liveHeartbeatCount1 = 0;
    id heartbeatEventObserver1 = [NSNotificationCenter.defaultCenter addObserverForHiddenEventNotificationUsingBlock:^(NSString * _Nonnull event, NSDictionary * _Nonnull labels) {
        if ([event isEqualToString:@"pos"]) {
            ++heartbeatCount1;
        }
        else if ([event isEqualToString:@"uptime"]) {
            ++liveHeartbeatCount1;
        }
    }];
    
    [self expectationForElapsedTimeInterval:7. withHandler:nil];
    [self waitForExpectationsWithTimeout:20. handler:^(NSError * _Nullable error) {
        [NSNotificationCenter.defaultCenter removeObserver:heartbeatEventObserver1];
    }];
    
    XCTAssertEqual(heartbeatCount1, 0);
    XCTAssertEqual(liveHeartbeatCount1, 0);
    
    // Enable tracking. Expect a play to be received
    [self expectationForHiddenPlaybackEventNotificationWithHandler:^BOOL(NSString *event, NSDictionary *labels) {
        XCTAssertEqualObjects(labels[@"event_id"], @"play");
        return YES;
    }];
    
    XCTAssertEqual(self.mediaPlayerController.playbackState, SRGMediaPlayerPlaybackStatePlaying);
    self.mediaPlayerController.tracked = YES;
    
    // Heartbeats are now expected to be received
    
    __block NSInteger heartbeatCount2 = 0;
    __block NSInteger liveHeartbeatCount2 = 0;
    id heartbeatEventObserver2 = [NSNotificationCenter.defaultCenter addObserverForHiddenEventNotificationUsingBlock:^(NSString * _Nonnull event, NSDictionary * _Nonnull labels) {
        if ([event isEqualToString:@"pos"]) {
            ++heartbeatCount2;
        }
        else if ([event isEqualToString:@"uptime"]) {
            ++liveHeartbeatCount2;
        }
    }];
    
    [self expectationForElapsedTimeInterval:7. withHandler:nil];
    [self waitForExpectationsWithTimeout:20. handler:^(NSError * _Nullable error) {
        [NSNotificationCenter.defaultCenter removeObserver:heartbeatEventObserver2];
    }];
    
    XCTAssertEqual(heartbeatCount2, 2);
    XCTAssertEqual(liveHeartbeatCount2, 1);
}

- (void)testMetadata
{
    XCTAssertNil(self.mediaPlayerController.userInfo);
    XCTAssertNil(self.mediaPlayerController.analyticsLabels);
    
    [self expectationForHiddenPlaybackEventNotificationWithHandler:^BOOL(NSString *event, NSDictionary *labels) {
        return [labels[@"event_id"] isEqualToString:@"play"];
    }];
    
    NSDictionary<NSString *, NSString *> *analyticsLabels = @{ @"custom_key" : @"custom_value" };
    
    NSDictionary *userInfo = @{ @"key" : @"value" };
    [self.mediaPlayerController playURL:OnDemandTestURL() atPosition:nil withSegments:nil analyticsLabels:analyticsLabels userInfo:userInfo];
    XCTAssertEqualObjects([self.mediaPlayerController.userInfo dictionaryWithValuesForKeys:userInfo.allKeys], userInfo);
    XCTAssertEqualObjects(self.mediaPlayerController.analyticsLabels, analyticsLabels);
    
    [self waitForExpectationsWithTimeout:20. handler:nil];
}

- (void)testAnalyticsLabelsUpdates
{
    [self expectationForHiddenPlaybackEventNotificationWithHandler:^BOOL(NSString *event, NSDictionary *labels) {
        if (! [labels[@"event_id"] isEqualToString:@"play"]) {
            return NO;
        }
        
        XCTAssertEqualObjects(labels[@"custom_key"], @"custom_value");
        return YES;
    }];
    
    NSDictionary<NSString *, NSString *> *analyticsLabels = @{ @"custom_key" : @"custom_value" };
    [self.mediaPlayerController playURL:OnDemandTestURL() atPosition:nil withSegments:nil analyticsLabels:analyticsLabels userInfo:nil];
    
    [self waitForExpectationsWithTimeout:20. handler:nil];
    
    [self expectationForHiddenPlaybackEventNotificationWithHandler:^BOOL(NSString * _Nonnull event, NSDictionary * _Nonnull labels) {
        if (! [labels[@"event_id"] isEqualToString:@"pause"]) {
            return NO;
        }
        
        XCTAssertNil(labels[@"custom_key"]);
        XCTAssertEqualObjects(labels[@"other_custom_key"], @"other_custom_value");
        return YES;
    }];
    
    NSDictionary<NSString *, NSString *> *updatedAnalyticsLabels = @{ @"other_custom_key" : @"other_custom_value" };
    
    self.mediaPlayerController.analyticsLabels = updatedAnalyticsLabels;
    [self.mediaPlayerController pause];
    
    [self waitForExpectationsWithTimeout:20. handler:nil];
}

- (void)testAnalyticsLabelsIndirectChangeResilience
{
    [self expectationForHiddenPlaybackEventNotificationWithHandler:^BOOL(NSString *event, NSDictionary *labels) {
        if (! [labels[@"event_id"] isEqualToString:@"play"]) {
            return NO;
        }
        
        XCTAssertEqualObjects(labels[@"custom_key"], @"custom_value");
        return YES;
    }];
    
    NSMutableDictionary<NSString *, NSString *> *analyticsLabels = [@{ @"custom_key" : @"custom_value" } mutableCopy];
    [self.mediaPlayerController playURL:OnDemandTestURL() atPosition:nil withSegments:nil analyticsLabels:analyticsLabels userInfo:nil];
    
    [self waitForExpectationsWithTimeout:20. handler:nil];
    
    [self expectationForHiddenPlaybackEventNotificationWithHandler:^BOOL(NSString * _Nonnull event, NSDictionary * _Nonnull labels) {
        if (! [labels[@"event_id"] isEqualToString:@"pause"]) {
            return NO;
        }
        
        XCTAssertNil(labels[@"updated_key"]);
        XCTAssertEqualObjects(labels[@"custom_key"], @"custom_value");
        return YES;
    }];
    
    // Change the original labels. Labels attached to the controller must not be affected
    analyticsLabels[@"updated_key"] = @"updated_value";
    
    [self.mediaPlayerController pause];
    
    [self waitForExpectationsWithTimeout:20. handler:nil];
}

@end
