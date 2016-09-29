//
//  Copyright (c) SRG SSR. All rights reserved.
//
//  License information is available from the LICENSE file.
//

#import <SRGAnalytics_DataProvider/SRGAnalytics_DataProvider.h>
#import <XCTest/XCTest.h>

typedef BOOL (^HiddenEventExpectationHandler)(NSString *type, NSDictionary *labels);

static NSURL *ServiceTestURL(void)
{
    return [NSURL URLWithString:@"http://il-test.srgssr.ch"];
}

@interface DataProviderTestCase : XCTestCase

@property (nonatomic) SRGMediaPlayerController *mediaPlayerController;

@end

@implementation DataProviderTestCase

#pragma mark Helpers

// Expectation for global hidden event notifications (player notifications are all event notifications, we don't want to have a look
// at view events here)
// TODO: Factor out this code, available elsewhere
- (XCTestExpectation *)expectationForHiddenEventNotificationWithHandler:(HiddenEventExpectationHandler)handler
{
    return [self expectationForNotification:SRGAnalyticsComScoreRequestNotification object:nil handler:^BOOL(NSNotification * _Nonnull notification) {
        NSDictionary *labels = notification.userInfo[SRGAnalyticsComScoreLabelsKey];
        
        NSString *type = labels[@"ns_type"];
        if (! [type isEqualToString:@"hidden"]) {
            return NO;
        }
        
        // Discard heartbeats (though hidden events, they are outside our control)
        NSString *event = labels[@"ns_st_ev"];
        if ([event isEqualToString:@"hb"]) {
            return NO;
        }
        
        return handler(event, labels);
    }];
}

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

- (void)testPrepareToPlayMediaComposition
{
    XCTestExpectation *expectation = [self expectationWithDescription:@"Ready to play"];
    
    SRGDataProvider *dataProvider = [[SRGDataProvider alloc] initWithServiceURL:ServiceTestURL() businessUnitIdentifier:SRGDataProviderBusinessUnitIdentifierSWI];
    [[dataProvider mediaCompositionForVideoWithUid:@"42297626" completionBlock:^(SRGMediaComposition * _Nullable mediaComposition, NSError * _Nullable error) {
        XCTAssertNotNil(mediaComposition);
        
        [[self.mediaPlayerController prepareToPlayMediaComposition:mediaComposition withPreferredQuality:SRGQualityHD userInfo:nil completionHandler:^(NSError * _Nonnull error) {
            XCTAssertNil(error);
            [expectation fulfill];
        }] resume];
    }] resume];
    
    [self waitForExpectationsWithTimeout:20. handler:nil];
    
    [self expectationForHiddenEventNotificationWithHandler:^BOOL(NSString *type, NSDictionary *labels) {
        XCTAssertEqualObjects(labels[@"ns_st_ev"], @"play");
        XCTAssertEqualObjects(labels[@"ns_st_ep"], @"Archive footage of the man and his moods");
        XCTAssertEqualObjects(labels[@"srg_mqual"], @"HD");
        return YES;
    }];
    
    XCTAssertEqual(self.mediaPlayerController.playbackState, SRGMediaPlayerPlaybackStatePaused);
    
    // Start playback and check labels
    [self.mediaPlayerController play];
    
    [self waitForExpectationsWithTimeout:20. handler:nil];
}

- (void)testPlayMediaComposition
{
    XCTestExpectation *expectation = [self expectationWithDescription:@"Ready to play"];
    
    SRGDataProvider *dataProvider = [[SRGDataProvider alloc] initWithServiceURL:ServiceTestURL() businessUnitIdentifier:SRGDataProviderBusinessUnitIdentifierSWI];
    [[dataProvider mediaCompositionForVideoWithUid:@"42297626" completionBlock:^(SRGMediaComposition * _Nullable mediaComposition, NSError * _Nullable error) {
        XCTAssertNotNil(mediaComposition);
        
        [[self.mediaPlayerController playMediaComposition:mediaComposition withPreferredQuality:SRGQualityHD userInfo:nil completionHandler:^(NSError * _Nonnull error) {
            XCTAssertNil(error);
            [expectation fulfill];
        }] resume];
    }] resume];
    
    [self waitForExpectationsWithTimeout:20. handler:nil];
    
    XCTAssertEqual(self.mediaPlayerController.playbackState, SRGMediaPlayerPlaybackStatePlaying);
}

// TODO: This test currently fails since segment labels are incorrect in the media composition
//       This must be discussed (see https://srfmmz.atlassian.net/wiki/display/SRGPLAY/Developer+Meeting+2016-10-05)
- (void)testPlaySegmentInMediaComposition
{
    // Use a segment id as video id, expect segment labels
    XCTestExpectation *expectation = [self expectationWithDescription:@"Ready to play"];
    
    [self expectationForHiddenEventNotificationWithHandler:^BOOL(NSString *type, NSDictionary *labels) {
        XCTAssertEqualObjects(labels[@"ns_st_ev"], @"play");
        XCTAssertEqualObjects(labels[@"ns_st_ep"], @"Was ist bloss los mit der Schweizer Luftwaffe?");
        XCTAssertEqualObjects(labels[@"srg_mqual"], @"HD");
    }];
    
    SRGDataProvider *dataProvider = [[SRGDataProvider alloc] initWithServiceURL:ServiceTestURL() businessUnitIdentifier:SRGDataProviderBusinessUnitIdentifierSRF];
    [[dataProvider mediaCompositionForVideoWithUid:@"506e4ce5-169f-45ba-b7cd-5942801c75b0" completionBlock:^(SRGMediaComposition * _Nullable mediaComposition, NSError * _Nullable error) {
        XCTAssertNotNil(mediaComposition);
        
        [[self.mediaPlayerController playMediaComposition:mediaComposition withPreferredQuality:SRGQualityHD userInfo:nil completionHandler:^(NSError * _Nonnull error) {
            XCTAssertNil(error);
        }] resume];
    }] resume];
    
    [self waitForExpectationsWithTimeout:20. handler:nil];
}

@end
