//
//  Copyright (c) SRG SSR. All rights reserved.
//
//  License information is available from the LICENSE file.
//

#import <SRGAnalytics_MediaPlayer/SRGAnalytics_MediaPlayer.h>
#import <XCTest/XCTest.h>

static NSURL *OnDemandTestURL(void)
{
    return [NSURL URLWithString:@"https://devimages.apple.com.edgekey.net/streaming/examples/bipbop_16x9/bipbop_16x9_variant.m3u8"];
}

@interface NonStartedTrackerTestCase : XCTestCase

@end

@implementation NonStartedTrackerTestCase

#pragma mark Helpers

- (XCTestExpectation *)expectationForElapsedTimeInterval:(NSTimeInterval)timeInterval withHandler:(void (^)(void))handler
{
    XCTestExpectation *expectation = [self expectationWithDescription:[NSString stringWithFormat:@"Wait for %@ seconds", @(timeInterval)]];
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(timeInterval * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        [expectation fulfill];
        handler ? handler() : nil;
    });
    return expectation;
}

#pragma mark Tests

// In all tests, the tracker has not been started

- (void)testHiddenEvent
{
    if ([SRGAnalyticsTracker sharedTracker].started) {
        NSLog(@"[WARNING] Shared tracker already started by another test. Please run this test individually");
        return;
    }
    
    [[SRGAnalyticsTracker sharedTracker] trackHiddenEventWithTitle:@"test"];
    
    // No events must be received. We cannot control the start event, though
    __block id comScoreRequestObserver = [[NSNotificationCenter defaultCenter] addObserverForName:SRGAnalyticsComScoreRequestNotification object:nil queue:nil usingBlock:^(NSNotification * _Nonnull notification) {
        NSDictionary *labels = notification.userInfo[SRGAnalyticsComScoreLabelsKey];
        if (! [labels[@"ns_ap_ev"] isEqualToString:@"start"]) {
            XCTFail(@"No comScore event is expected when the tracker has not been started");
        }
    }];
    
    // Wait for a while to check whether the observer collects any notifications
    [self expectationForElapsedTimeInterval:5. withHandler:nil];
    [self waitForExpectationsWithTimeout:20. handler:^(NSError * _Nullable error) {
        [[NSNotificationCenter defaultCenter] removeObserver:comScoreRequestObserver];
    }];
}

- (void)testStreamEvents
{
    if ([SRGAnalyticsTracker sharedTracker].started) {
        NSLog(@"[WARNING] Shared tracker already started by another test. Please run this test individually");
        return;
    }
    
    SRGMediaPlayerController *mediaPlayerController = [[SRGMediaPlayerController alloc] init];
    
    // No events must be received. We cannot control the start event, though
    __block id comScoreRequestObserver = [[NSNotificationCenter defaultCenter] addObserverForName:SRGAnalyticsComScoreRequestNotification object:nil queue:nil usingBlock:^(NSNotification * _Nonnull notification) {
        NSDictionary *labels = notification.userInfo[SRGAnalyticsComScoreLabelsKey];
        if (! [labels[@"ns_ap_ev"] isEqualToString:@"start"]) {
            XCTFail(@"No comScore event is expected when the tracker has not been started");
        }
    }];
    
    [mediaPlayerController playURL:OnDemandTestURL()];
    
    // Wait for a while to check whether the observer collects any notifications
    [self expectationForElapsedTimeInterval:5. withHandler:nil];
    [self waitForExpectationsWithTimeout:20. handler:^(NSError * _Nullable error) {
        [[NSNotificationCenter defaultCenter] removeObserver:comScoreRequestObserver];
    }];
    
    [mediaPlayerController reset];
}

// Contrieved test case, as the tracker should be start as early as possible (so that the start event is correct)
- (void)testTrackerStartWhenPlayingMedia
{
    if ([SRGAnalyticsTracker sharedTracker].started) {
        NSLog(@"[WARNING] Shared tracker already started by another test. Please run this test individually");
        return;
    }
    
    SRGMediaPlayerController *mediaPlayerController = [[SRGMediaPlayerController alloc] init];
    
    // No events must be received. We cannot control the start event, though
    __block id comScoreRequestObserver = [[NSNotificationCenter defaultCenter] addObserverForName:SRGAnalyticsComScoreRequestNotification object:nil queue:nil usingBlock:^(NSNotification * _Nonnull notification) {
        NSDictionary *labels = notification.userInfo[SRGAnalyticsComScoreLabelsKey];
        if (! [labels[@"ns_ap_ev"] isEqualToString:@"start"]) {
            XCTFail(@"No comScore event is expected when the tracker has not been started");
        }
    }];
    
    // Wait until playing
    [self expectationForNotification:SRGMediaPlayerPlaybackStateDidChangeNotification object:mediaPlayerController handler:^BOOL(NSNotification * _Nonnull notification) {
        return [notification.userInfo[SRGMediaPlayerPlaybackStateKey] integerValue] == SRGMediaPlayerPlaybackStatePlaying;
    }];
    
    [mediaPlayerController playURL:OnDemandTestURL()];
    
    [self waitForExpectationsWithTimeout:20. handler:^(NSError * _Nullable error) {
        [[NSNotificationCenter defaultCenter] removeObserver:comScoreRequestObserver];
    }];
    
    // Start the tracker. Expect a play notification
    [self expectationForNotification:SRGAnalyticsComScoreRequestNotification object:nil handler:^BOOL(NSNotification * _Nonnull notification) {
        NSDictionary *labels = notification.userInfo[SRGAnalyticsComScoreLabelsKey];
        return [labels[@"ns_st_ev"] isEqualToString:@"play"];
    }];
    
    [[SRGAnalyticsTracker sharedTracker] startWithBusinessUnitIdentifier:SRGAnalyticsBusinessUnitIdentifierTEST
                                                     comScoreVirtualSite:@"rts-app-test-v"
                                                     netMetrixIdentifier:@"test"];
    
    [self waitForExpectationsWithTimeout:20. handler:nil];
    
    [mediaPlayerController reset];
}

@end
