//
//  Copyright (c) SRG SSR. All rights reserved.
//
//  License information is available from the LICENSE file.
//

#import <SRGAnalytics_MediaPlayer/SRGAnalytics_MediaPlayer.h>
#import <XCTest/XCTest.h>

static NSURL *PlaybackTestURL(void)
{
    return [NSURL URLWithString:@"https://devimages.apple.com.edgekey.net/streaming/examples/bipbop_16x9/bipbop_16x9_variant.m3u8"];
}

@interface MediaPlayerTestCase : XCTestCase

@end

@implementation MediaPlayerTestCase

+ (void)setUp
{
    SRGAnalyticsTracker *analyticsTracker = [SRGAnalyticsTracker sharedTracker];
    [analyticsTracker startTrackingForBusinessUnit:SSRBusinessUnitRTS withComScoreVirtualSite:@"rts-app-test-v" netMetrixIdentifier:@"test" debugMode:NO];
}

- (void)testMediaPlayback
{
    SRGMediaPlayerController *mediaPlayerController = [[SRGMediaPlayerController alloc] init];
    
    [self expectationForNotification:SRGAnalyticsComScoreRequestDidFinishNotification object:nil handler:^BOOL(NSNotification * _Nonnull notification) {
        NSDictionary *labels = notification.userInfo[SRGAnalyticsComScoreRequestLabelsUserInfoKey];
        return YES;
    }];
    
    [mediaPlayerController playURL:PlaybackTestURL()];
    
    [self waitForExpectationsWithTimeout:20. handler:nil];
}

@end
