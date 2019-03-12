//
//  Copyright (c) SRG SSR. All rights reserved.
//
//  License information is available from the LICENSE file.
//

#import "AnalyticsTestCase.h"

#import <SRGAnalytics_DataProvider/SRGAnalytics_DataProvider.h>

static NSURL *ServiceTestURL(void)
{
    return SRGIntegrationLayerProductionServiceURL();
}

@interface ComScoreDataProviderTestCase : AnalyticsTestCase

@property (nonatomic) SRGMediaPlayerController *mediaPlayerController;

@end

@implementation ComScoreDataProviderTestCase

#pragma mark Setup and teardown

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
        [self expectationForComScorePlaybackEventNotificationWithHandler:^BOOL(NSString * _Nonnull event, NSDictionary * _Nonnull labels) {
            return [event isEqualToString:@"end"];
        }];
        
        [self.mediaPlayerController reset];
        
        [self waitForExpectationsWithTimeout:10. handler:nil];
    }
    self.mediaPlayerController = nil;
}

#pragma mark Tests

- (void)testPrepareToPlayMediaComposition
{
    XCTestExpectation *expectation = [self expectationWithDescription:@"Ready to play"];
    
    SRGDataProvider *dataProvider = [[SRGDataProvider alloc] initWithServiceURL:ServiceTestURL()];
    [[dataProvider mediaCompositionForURN:@"urn:swi:video:42297626" standalone:NO withCompletionBlock:^(SRGMediaComposition * _Nullable mediaComposition, NSHTTPURLResponse * _Nullable HTTPResponse, NSError * _Nullable error) {
        XCTAssertNotNil(mediaComposition);
        
        SRGPlaybackSettings *settings = [[SRGPlaybackSettings alloc] init];
        settings.quality = SRGQualityHD;
        
        [self.mediaPlayerController prepareToPlayMediaComposition:mediaComposition atPosition:nil withPreferredSettings:settings userInfo:nil completionHandler:^{
            XCTAssertEqual(self.mediaPlayerController.mediaComposition, mediaComposition);
            [expectation fulfill];
        }];
    }] resume];
    
    [self waitForExpectationsWithTimeout:20. handler:nil];
    
    XCTAssertEqual(self.mediaPlayerController.playbackState, SRGMediaPlayerPlaybackStatePaused);
    
    // Start playback and check labels
    [self expectationForComScoreHiddenEventNotificationWithHandler:^BOOL(NSString *event, NSDictionary *labels) {
        XCTAssertEqualObjects(labels[@"ns_st_ev"], @"play");
        XCTAssertEqualObjects(labels[@"ns_st_ep"], @"Archive footage of the man and his moods");
        XCTAssertEqualObjects(labels[@"srg_mqual"], @"HD");
        return YES;
    }];
    
    [self.mediaPlayerController play];
    
    [self waitForExpectationsWithTimeout:20. handler:nil];
}

- (void)testPlayMediaComposition
{
    [self expectationForSingleNotification:SRGMediaPlayerPlaybackStateDidChangeNotification object:self.mediaPlayerController handler:^BOOL(NSNotification * _Nonnull notification) {
        return [notification.userInfo[SRGMediaPlayerPlaybackStateKey] integerValue] == SRGMediaPlayerPlaybackStatePlaying;
    }];
    
    SRGDataProvider *dataProvider = [[SRGDataProvider alloc] initWithServiceURL:ServiceTestURL()];
    
    __block SRGMediaComposition *fetchedMediaComposition = nil;
    [[dataProvider mediaCompositionForURN:@"urn:swi:video:42297626" standalone:NO withCompletionBlock:^(SRGMediaComposition * _Nullable mediaComposition, NSHTTPURLResponse * _Nullable HTTPResponse, NSError * _Nullable error) {
        XCTAssertNotNil(mediaComposition);
        fetchedMediaComposition = mediaComposition;
        
        [self.mediaPlayerController playMediaComposition:mediaComposition atPosition:nil withPreferredSettings:nil userInfo:nil];
    }] resume];
    
    [self waitForExpectationsWithTimeout:20. handler:nil];
    
    XCTAssertEqual(self.mediaPlayerController.playbackState, SRGMediaPlayerPlaybackStatePlaying);
    XCTAssertEqual(self.mediaPlayerController.mediaComposition, fetchedMediaComposition);
}

- (void)testPlaySegmentInMediaComposition
{
    // Use a segment id as video id, expect segment labels
    [self expectationForComScoreHiddenEventNotificationWithHandler:^BOOL(NSString *event, NSDictionary *labels) {
        XCTAssertEqualObjects(labels[@"ns_st_ev"], @"play");
        XCTAssertEqualObjects(labels[@"ns_st_ep"], @"Der Neue ist der Alte");
        XCTAssertEqualObjects(labels[@"srg_mqual"], @"HD");
        return YES;
    }];
    
    SRGDataProvider *dataProvider = [[SRGDataProvider alloc] initWithServiceURL:ServiceTestURL()];
    
    __block SRGMediaComposition *fetchedMediaComposition = nil;
    [[dataProvider mediaCompositionForURN:@"urn:srf:video:84043ead-6e5a-4a05-875c-c1aa2998aa43" standalone:NO withCompletionBlock:^(SRGMediaComposition * _Nullable mediaComposition, NSHTTPURLResponse * _Nullable HTTPResponse, NSError * _Nullable error) {
        XCTAssertNotNil(mediaComposition);
        fetchedMediaComposition = mediaComposition;
        
        SRGPlaybackSettings *settings = [[SRGPlaybackSettings alloc] init];
        settings.quality = SRGQualityHD;
        
        [self.mediaPlayerController playMediaComposition:mediaComposition atPosition:nil withPreferredSettings:nil userInfo:nil];
    }] resume];
    
    [self waitForExpectationsWithTimeout:20. handler:nil];
    
    XCTAssertEqual(self.mediaPlayerController.mediaComposition, fetchedMediaComposition);
}

@end
