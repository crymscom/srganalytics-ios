//
//  RTSAnalyticsTrackerTest.m
//  RTSAnalytics
//
//  Created by Cédric Foellmi on 01/04/15.
//  Copyright (c) 2015 RTS. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <XCTest/XCTest.h>
#import <OCMock/OCMock.h>

#import <RTSMediaPlayer/RTSMediaPlayer.h>
#import <comScore-iOS-SDK/CSComScore.h>

#import "RTSAnalyticsTracker.h"

@interface RTSAnalyticsTrackerTest : XCTestCase
@property(nonatomic, strong) id dataSourceMock;
@property(nonatomic, strong) RTSAnalyticsTrackerConfig *config;
@end

@implementation RTSAnalyticsTrackerTest

- (void)setUp
{
    [super setUp];
    
    self.dataSourceMock = OCMProtocolMock(@protocol(RTSAnalyticsDataSource));
    self.config = [RTSAnalyticsTrackerConfig configWithBusinessUnit:@"rts"
                                                comScoreVirtualSite:@"cc_vsite"
                                             streamSenseVirtualSite:@"ss_vsite"];
}

- (void)tearDown
{
    self.dataSourceMock = nil;
    self.config = nil;
    [super tearDown];
}

// Making sure with AAAAA that this method is called first.
- (void)testAAAAATrackerValidSetup
{
    id comScoreClassMock = OCMClassMock([CSComScore class]);
    
    // Also check that when we have multiple trackers, the setup is done only once for comScore.
    RTSAnalyticsTracker *tracker1 = [[RTSAnalyticsTracker alloc] initWithConfig:self.config dataSource:self.dataSourceMock];
    RTSAnalyticsTracker *tracker2 = [[RTSAnalyticsTracker alloc] initWithConfig:self.config dataSource:self.dataSourceMock];
    
    OCMVerify([comScoreClassMock setCustomerC2:[OCMArg isNotNil]]);
    OCMVerify([comScoreClassMock setPublisherSecret:[OCMArg isNotNil]]);
    OCMVerify([comScoreClassMock onUxActive]);

    id checkBlock = ^BOOL(id obj) {
        if (![obj isKindOfClass:[NSDictionary class]]) {
            return NO;
        }
        
        NSDictionary *labels = (NSDictionary *)obj;
        NSArray *keys = @[@"ns_ap_an", @"ns_ap_ver", @"srg_unit", @"srg_ap_push", @"ns_site", @"ns_vsite"];
        
        if ([labels count] != [keys count]) {
            return NO;
        }
        
        for (NSString *key in keys) {
            if ([labels objectForKey:key] == nil) {
                return NO;
            }
        }
        
        return YES;
    };
    
    OCMVerify([comScoreClassMock setLabels:[OCMArg checkWithBlock:checkBlock]]);
    [comScoreClassMock stopMocking];

    // Avoiding warnings...
    tracker1 = nil;
    tracker2 = nil;
}

- (void)testSendComScoreLabelsAfterAppEnteringForegroundNotification
{
    id comScoreClassMock = OCMClassMock([CSComScore class]);
    
    RTSAnalyticsTracker *tracker = [[RTSAnalyticsTracker alloc] initWithConfig:self.config dataSource:self.dataSourceMock];
    
    [[NSNotificationCenter defaultCenter] postNotificationName:UIApplicationWillEnterForegroundNotification
                                                        object:nil
                                                      userInfo:nil];

    OCMVerify([comScoreClassMock viewWithLabels:[OCMArg any]]);
    OCMVerify([self.dataSourceMock comScoreLabelsForAppEnteringForeground]);
    
    [comScoreClassMock stopMocking];

    tracker = nil;
}

- (void)testSendComScoreLabelsUponStatusChangeNotificationWithStatusReadyToPlayComingFromPreparing
{
    id comScoreClassMock = OCMClassMock([CSComScore class]);
    id playerMock = OCMClassMock([RTSMediaPlayerController class]);
    OCMStub([playerMock playbackState]).andReturn(RTSMediaPlaybackStateReady);

    RTSAnalyticsTracker *tracker = [[RTSAnalyticsTracker alloc] initWithConfig:self.config dataSource:self.dataSourceMock];
    
    [[NSNotificationCenter defaultCenter] postNotificationName:RTSMediaPlayerPlaybackStateDidChangeNotification
                                                        object:playerMock
                                                      userInfo:@{RTSMediaPlayerPreviousPlaybackStateUserInfoKey: @(RTSMediaPlaybackStatePreparing)}];
    
    OCMVerify([comScoreClassMock viewWithLabels:[OCMArg any]]);
    
    [comScoreClassMock stopMocking];
    
    tracker = nil;
}


- (void)testNoSendLabelsUponStatusChangeNotificationWithStatusReadyToPlayNotComingFromPreparing
{
    id comScoreClassMock = OCMClassMock([CSComScore class]);
    id playerMock = OCMClassMock([RTSMediaPlayerController class]);
    
    RTSAnalyticsTracker *tracker = [[RTSAnalyticsTracker alloc] initWithConfig:self.config dataSource:self.dataSourceMock];
    
    for (RTSMediaPlaybackState state1 = 0; state1 < RTSMediaPlaybackStateStalled; state1++) {
        for (RTSMediaPlaybackState state2 = 0; state1 < RTSMediaPlaybackStateStalled; state1++) {
            if (!(state1 == RTSMediaPlaybackStateReady && state2 == RTSMediaPlaybackStatePreparing)) {
                
                OCMStub([playerMock playbackState]).andReturn(state1);
                
                [[NSNotificationCenter defaultCenter] postNotificationName:RTSMediaPlayerPlaybackStateDidChangeNotification
                                                                    object:playerMock
                                                                  userInfo:@{RTSMediaPlayerPreviousPlaybackStateUserInfoKey: @(state2)}];
                
                OCMVerifyAll(comScoreClassMock);
            }
        }
    }
    
    [comScoreClassMock stopMocking];
    
    tracker = nil;
}

@end
