//
//  Copyright (c) SRG SSR. All rights reserved.
//
//  License information is available from the LICENSE file.
//

#import "XCTestCase+Tests.h"

@interface StreamLabelsTestCase : XCTestCase

@end

@implementation StreamLabelsTestCase

- (void)testEmpty
{
    SRGAnalyticsStreamLabels *labels = [[SRGAnalyticsStreamLabels alloc] init];
    
    NSDictionary *labelsDictionary = @{ @"media_embedding_environment" : @"preprod",
                                        @"media_subtitles_on" : @"false",
                                        @"media_volume" : @"0" };
    XCTAssertEqualObjects(labels.labelsDictionary, labelsDictionary);
}

- (void)testNonEmpty
{
    SRGAnalyticsStreamLabels *labels = [[SRGAnalyticsStreamLabels alloc] init];
    labels.playerName = @"player";
    labels.playerVersion = @"1.0";
    labels.playerVolumeInPercent = @80;
    labels.subtitlesEnabled = @YES;
    labels.timeshiftInMilliseconds = @3000.350;
    labels.bandwidthInBitsPerSecond = @1024.567;
    labels.customInfo = @{ @"key" : @"value" };
    
    NSDictionary *labelsDictionary = @{ @"media_embedding_environment" : @"preprod",
                                        @"media_player_display" : @"player",
                                        @"media_player_version" : @"1.0",
                                        @"media_volume" : @"80",
                                        @"media_subtitles_on" : @"true",
                                        @"media_timeshift" : @"3",
                                        @"media_bandwidth" : @"1024.567",
                                        @"key" : @"value" };
    XCTAssertEqualObjects(labels.labelsDictionary, labelsDictionary);
}

- (void)testEquality
{
    SRGAnalyticsStreamLabels *labels1 = [[SRGAnalyticsStreamLabels alloc] init];
    labels1.playerName = @"player";
    labels1.playerVersion = @"1.0";
    labels1.subtitlesEnabled = @YES;
    XCTAssertEqualObjects(labels1, labels1);
    
    SRGAnalyticsStreamLabels *labels2 = [[SRGAnalyticsStreamLabels alloc] init];
    labels2.playerName = @"player";
    labels2.playerVersion = @"1.0";
    labels2.subtitlesEnabled = @YES;
    XCTAssertEqualObjects(labels1, labels2);
    
    SRGAnalyticsStreamLabels *labels3 = [[SRGAnalyticsStreamLabels alloc] init];
    labels3.playerName = @"other_player";
    labels3.playerVersion = @"1.0";
    labels3.subtitlesEnabled = @YES;
    XCTAssertNotEqualObjects(labels1, labels3);
    
    SRGAnalyticsStreamLabels *labels4 = [[SRGAnalyticsStreamLabels alloc] init];
    labels4.playerName = @"player";
    labels4.playerVersion = @"2.0";
    labels4.subtitlesEnabled = @YES;
    XCTAssertNotEqualObjects(labels1, labels4);
    
    SRGAnalyticsStreamLabels *labels5 = [[SRGAnalyticsStreamLabels alloc] init];
    labels5.playerName = @"player";
    labels5.playerVersion = @"1.0";
    labels5.subtitlesEnabled = @NO;
    XCTAssertNotEqualObjects(labels1, labels5);
}

- (void)testCopy
{
    SRGAnalyticsStreamLabels *labels = [[SRGAnalyticsStreamLabels alloc] init];
    labels.playerName = @"player";
    labels.playerVersion = @"1.0";
    labels.playerVolumeInPercent = @80;
    labels.subtitlesEnabled = @YES;
    labels.timeshiftInMilliseconds = @3000.350;
    labels.bandwidthInBitsPerSecond = @1024.567;
    labels.customInfo = @{ @"key" : @"value" };
    
    SRGAnalyticsStreamLabels *labelsCopy = [labels copy];
    XCTAssertEqualObjects(labels, labelsCopy);
}

- (void)testMergeWithEmpty
{
    SRGAnalyticsStreamLabels *mainLabels = [[SRGAnalyticsStreamLabels alloc] init];
    
    SRGAnalyticsStreamLabels *labels = [[SRGAnalyticsStreamLabels alloc] init];
    labels.playerName = @"player";
    labels.playerVersion = @"1.0";
    labels.playerVolumeInPercent = @80;
    labels.subtitlesEnabled = @YES;
    labels.timeshiftInMilliseconds = @3000.350;
    labels.bandwidthInBitsPerSecond = @1024.567;
    labels.customInfo = @{ @"key" : @"value" };
    
    [mainLabels mergeWithLabels:labels];
    NSDictionary *labelsDictionary = @{ @"media_embedding_environment" : @"preprod",
                                        @"media_player_display" : @"player",
                                        @"media_player_version" : @"1.0",
                                        @"media_volume" : @"80",
                                        @"media_subtitles_on" : @"true",
                                        @"media_timeshift" : @"3",
                                        @"media_bandwidth" : @"1024.567",
                                        @"key" : @"value" };
    XCTAssertEqualObjects(mainLabels.labelsDictionary, labelsDictionary);
}

- (void)testMergeOverrideAll
{
    SRGAnalyticsStreamLabels *mainLabels = [[SRGAnalyticsStreamLabels alloc] init];
    mainLabels.playerName = @"main_player";
    mainLabels.playerVersion = @"0.5";
    mainLabels.playerVolumeInPercent = @60;
    mainLabels.subtitlesEnabled = @NO;
    mainLabels.timeshiftInMilliseconds = @1000.450;
    mainLabels.bandwidthInBitsPerSecond = @200.45;
    mainLabels.customInfo = @{ @"main_key" : @"main_value" };
    
    SRGAnalyticsStreamLabels *labels = [[SRGAnalyticsStreamLabels alloc] init];
    labels.playerName = @"player";
    labels.playerVersion = @"1.0";
    labels.playerVolumeInPercent = @80;
    labels.subtitlesEnabled = @YES;
    labels.timeshiftInMilliseconds = @3000.350;
    labels.bandwidthInBitsPerSecond = @1024.567;
    labels.customInfo = @{ @"key" : @"value" };
    
    [mainLabels mergeWithLabels:labels];
    NSDictionary *labelsDictionary = @{ @"media_embedding_environment" : @"preprod",
                                        @"media_player_display" : @"player",
                                        @"media_player_version" : @"1.0",
                                        @"media_volume" : @"80",
                                        @"media_subtitles_on" : @"true",
                                        @"media_timeshift" : @"3",
                                        @"media_bandwidth" : @"1024.567",
                                        @"main_key" : @"main_value",
                                        @"key" : @"value" };
    XCTAssertEqualObjects(mainLabels.labelsDictionary, labelsDictionary);
}

- (void)testMergeOverrideSome
{
    SRGAnalyticsStreamLabels *mainLabels = [[SRGAnalyticsStreamLabels alloc] init];
    mainLabels.playerName = @"main_player";
    mainLabels.playerVersion = @"0.5";
    mainLabels.subtitlesEnabled = @YES;
    mainLabels.timeshiftInMilliseconds = @1000.450;
    mainLabels.customInfo = @{ @"main_key" : @"main_value" };
    
    SRGAnalyticsStreamLabels *labels = [[SRGAnalyticsStreamLabels alloc] init];
    labels.playerVersion = @"1.0";
    labels.playerVolumeInPercent = @80;
    labels.timeshiftInMilliseconds = @3000.350;
    labels.customInfo = @{ @"key" : @"value" };
    
    [mainLabels mergeWithLabels:labels];
    NSDictionary *labelsDictionary = @{ @"media_embedding_environment" : @"preprod",
                                        @"media_player_display" : @"main_player",
                                        @"media_player_version" : @"1.0",
                                        @"media_volume" : @"80",
                                        @"media_subtitles_on" : @"true",
                                        @"media_timeshift" : @"3",
                                        @"main_key" : @"main_value",
                                        @"key" : @"value" };
    XCTAssertEqualObjects(mainLabels.labelsDictionary, labelsDictionary);
}

- (void)testCustomInfoOverrides
{
    SRGAnalyticsStreamLabels *labels = [[SRGAnalyticsStreamLabels alloc] init];
    labels.playerName = @"player";
    labels.playerVersion = @"1.0";
    labels.playerVolumeInPercent = @80;
    labels.subtitlesEnabled = @YES;
    labels.timeshiftInMilliseconds = @3000.350;
    labels.bandwidthInBitsPerSecond = @1024.567;
    labels.customInfo = @{ @"media_embedding_environment" : @"overridden",
                           @"media_player_display" : @"overridden",
                           @"media_player_version" : @"overridden",
                           @"media_volume" : @"overridden",
                           @"media_subtitles_on" : @"overridden",
                           @"media_timeshift" : @"overridden",
                           @"media_bandwidth" : @"overridden" };
    XCTAssertEqualObjects(labels.labelsDictionary, labels.customInfo);
}

@end
