//
//  Copyright (c) SRG SSR. All rights reserved.
//
//  License information is available from the LICENSE file.
//

#import "AnalyticsTestCase.h"
#import "NSNotificationCenter+Tests.h"

#import <SRGAnalytics_MediaPlayer/SRGAnalytics_MediaPlayer.h>

static NSURL *PlaybackTestURL(void)
{
    return [NSURL URLWithString:@"https://devimages.apple.com.edgekey.net/streaming/examples/bipbop_16x9/bipbop_16x9_variant.m3u8"];
}

@interface MediaPlayerTestCase : AnalyticsTestCase

@end

@implementation MediaPlayerTestCase

#pragma mark Setup

+ (void)setUp
{
    SRGAnalyticsTracker *analyticsTracker = [SRGAnalyticsTracker sharedTracker];
    [analyticsTracker startTrackingForBusinessUnit:SSRBusinessUnitRTS withComScoreVirtualSite:@"rts-app-test-v" netMetrixIdentifier:@"test" debugMode:NO];
}

#pragma mark Tests

- (void)testPrepareToPlay
{
    SRGMediaPlayerController *mediaPlayerController = [[SRGMediaPlayerController alloc] init];
    
    // Prepare the player until it is paused. No event must be received
    id prepareObserver = [[NSNotificationCenter defaultCenter] addObserverForHiddenEventNotificationUsingBlock:^(NSString * _Nonnull event, NSDictionary * _Nonnull labels) {
        XCTFail(@"No event must be received when preparing a player");
    }];
    
    [mediaPlayerController prepareToPlayURL:PlaybackTestURL() withCompletionHandler:^{
        [[NSNotificationCenter defaultCenter] removeObserver:prepareObserver];
    }];
    
    // Now playing must trigger a play event
    [self expectationForHiddenEventNotificationWithHandler:^BOOL(NSString *event, NSDictionary *labels) {
        XCTAssertEqualObjects(labels[@"ns_st_ev"], @"play");
        return YES;
    }];
    
    [mediaPlayerController play];
    
    [self waitForExpectationsWithTimeout:20. handler:nil];
}

- (void)testPlayAndStop
{
    SRGMediaPlayerController *mediaPlayerController = [[SRGMediaPlayerController alloc] init];
    
    [self expectationForHiddenEventNotificationWithHandler:^BOOL(NSString *event, NSDictionary *labels) {
        XCTAssertEqualObjects(labels[@"ns_st_ev"], @"play");
        return YES;
    }];
    
    [mediaPlayerController playURL:PlaybackTestURL()];
    
    [self waitForExpectationsWithTimeout:20. handler:nil];
    
    [self expectationForHiddenEventNotificationWithHandler:^BOOL(NSString *event, NSDictionary *labels) {
        XCTAssertEqualObjects(labels[@"ns_st_ev"], @"end");
        return YES;
    }];
    
    [mediaPlayerController stop];
    
    [self waitForExpectationsWithTimeout:20. handler:nil];
}

- (void)testPlayAndReset
{
    SRGMediaPlayerController *mediaPlayerController = [[SRGMediaPlayerController alloc] init];
    
    [self expectationForHiddenEventNotificationWithHandler:^BOOL(NSString *event, NSDictionary *labels) {
        XCTAssertEqualObjects(labels[@"ns_st_ev"], @"play");
        return YES;
    }];
    
    [mediaPlayerController playURL:PlaybackTestURL()];
    
    [self waitForExpectationsWithTimeout:20. handler:nil];
    
    [self expectationForHiddenEventNotificationWithHandler:^BOOL(NSString *event, NSDictionary *labels) {
        XCTAssertEqualObjects(labels[@"ns_st_ev"], @"end");
        return YES;
    }];
    
    [mediaPlayerController reset];
    
    [self waitForExpectationsWithTimeout:20. handler:nil];
}

@end
