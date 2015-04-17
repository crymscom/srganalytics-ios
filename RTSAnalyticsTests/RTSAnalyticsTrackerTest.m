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
#import "RTSAnalyticsMediaPlayerDataSource.h"

@interface RTSAnalyticsTrackerTest : XCTestCase
@property(nonatomic, strong) id<RTSAnalyticsMediaPlayerDataSource> dataSourceMock;
@end

@implementation RTSAnalyticsTrackerTest

- (void)setUp
{
    [super setUp];
    
    self.dataSourceMock = OCMProtocolMock(@protocol(RTSAnalyticsMediaPlayerDataSource));
}

- (void)tearDown
{
    self.dataSourceMock = nil;
    [super tearDown];
}

// Making sure with AAAAA that this method is called first.
- (void)testAAAAATrackerValidSetup
{
    id comScoreClassMock = OCMClassMock([CSComScore class]);
    
    // Also check that when we have multiple trackers, the setup is done only once for comScore.
	[[RTSAnalyticsTracker sharedTracker] startTrackingForBusinessUnit:SSRBusinessUnitRTS launchOptions:nil mediaDataSource:self.dataSourceMock];
	
    OCMVerify([comScoreClassMock setCustomerC2:[OCMArg isNotNil]]);
    OCMVerify([comScoreClassMock setPublisherSecret:[OCMArg isNotNil]]);
    OCMVerify([comScoreClassMock setAppContext]);

    id checkBlock = ^BOOL(id obj) {
        if (![obj isKindOfClass:[NSDictionary class]]) {
            return NO;
        }
        
        NSDictionary *labels = (NSDictionary *)obj;
        NSArray *keys = @[@"ns_ap_an", @"ns_ap_lang", @"ns_ap_ver", @"srg_unit", @"srg_ap_push", @"ns_site", @"ns_vsite"];
        
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
}

- (void)testSendComScoreLabelsAfterAppEnteringForegroundNotification
{
    id comScoreClassMock = OCMClassMock([CSComScore class]);
    
    [[RTSAnalyticsTracker sharedTracker] startTrackingForBusinessUnit:SSRBusinessUnitRTS launchOptions:nil mediaDataSource:self.dataSourceMock];
    
    [[NSNotificationCenter defaultCenter] postNotificationName:UIApplicationWillEnterForegroundNotification
                                                        object:nil
                                                      userInfo:nil];

    OCMVerify([comScoreClassMock viewWithLabels:[OCMArg any]]);
    
    [comScoreClassMock stopMocking];
}

@end
