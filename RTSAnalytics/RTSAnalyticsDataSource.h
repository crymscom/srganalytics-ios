//
//  RTSAnalyticsDataSource.h
//  RTSAnalytics
//
//  Created by Cédric Foellmi on 27/03/15.
//  Copyright (c) 2015 RTS. All rights reserved.
//

#import <Foundation/Foundation.h>

typedef NS_ENUM(NSInteger, RTSAnalyticsMediaMode) {
    RTSAnalyticsMediaModeUnknown,
    RTSAnalyticsMediaModeOnDemand,
    RTSAnalyticsMediaModeLiveStream,
};

@protocol RTSAnalyticsDataSource <NSObject>

- (RTSAnalyticsMediaMode)mediaModeForIdentifier:(NSString *)identifier;

- (NSDictionary *)comScoreLabelsForAppEnteringForeground;
- (NSDictionary *)comScoreReadyToPlayLabelsForIdentifier:(NSString *)identifier;

- (NSDictionary *)streamSensePlaylistMetadataForIdentifier:(NSString *)identifier;
- (NSDictionary *)streamSenseFullLengthClipMetadataForIdentifier:(NSString *)identifier;

// To be seen when implementing segments
//- (NSDictionary *)streamSenseSegmentClipMetadata;
//- (NSDictionary *)streamSenseSegmentMetadataWithPlaybackEventUserInfo:(NSDictionary *)userInfo wasSegmentSelected:(BOOL)segmentSelected;

@end
