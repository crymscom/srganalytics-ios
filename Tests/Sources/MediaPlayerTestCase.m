//
//  Copyright (c) SRG SSR. All rights reserved.
//
//  License information is available from the LICENSE file.
//

#import <SRGAnalytics_MediaPlayer/SRGAnalytics_MediaPlayer.h>
#import <XCTest/XCTest.h>

typedef BOOL (^HiddenEventExpectationHandler)(NSString *event, NSDictionary *labels);

static NSURL *PlaybackTestURL(void)
{
    return [NSURL URLWithString:@"https://devimages.apple.com.edgekey.net/streaming/examples/bipbop_16x9/bipbop_16x9_variant.m3u8"];
}

@interface MediaPlayerTestCase : XCTestCase

@end

@implementation MediaPlayerTestCase

#pragma mark Helpers

// Expectation for global hidden event notifications (player notifications are all event notifications, we don't want to have a look
// at view events here)
- (XCTestExpectation *)expectationForHiddenEventNotificationWithHandler:(HiddenEventExpectationHandler)handler
{
    return [self expectationForNotification:SRGAnalyticsComScoreRequestDidFinishNotification object:nil handler:^BOOL(NSNotification * _Nonnull notification) {
        NSDictionary *labels = notification.userInfo[SRGAnalyticsComScoreRequestLabelsUserInfoKey];
        
        NSString *event = labels[@"ns_type"];
        if (! [event isEqualToString:@"hidden"]) {
            return NO;
        }
        
        return handler(event, labels);
    }];
}

#pragma mark Setup

+ (void)setUp
{
    SRGAnalyticsTracker *analyticsTracker = [SRGAnalyticsTracker sharedTracker];
    [analyticsTracker startTrackingForBusinessUnit:SSRBusinessUnitRTS withComScoreVirtualSite:@"rts-app-test-v" netMetrixIdentifier:@"test" debugMode:NO];
}

#pragma mark Tests

- (void)testMediaPlayback
{
    SRGMediaPlayerController *mediaPlayerController = [[SRGMediaPlayerController alloc] init];
    
    [self expectationForHiddenEventNotificationWithHandler:^BOOL(NSString *event, NSDictionary *labels) {
        XCTAssertEqualObjects(labels[@"ns_st_ev"], @"play");
        return YES;
    }];
    
    [mediaPlayerController playURL:PlaybackTestURL()];
    
    [self waitForExpectationsWithTimeout:20. handler:nil];
}

@end
