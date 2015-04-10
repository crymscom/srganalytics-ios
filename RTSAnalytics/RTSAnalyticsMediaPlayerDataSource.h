//
//  Created by Cédric Foellmi on 27/03/15.
//  Copyright (c) 2015 RTS. All rights reserved.
//

#import <Foundation/Foundation.h>

@protocol RTSAnalyticsMediaPlayerDataSource <NSObject>

@optional
- (NSDictionary *)streamSenseLabelsMetadataForIdentifier:(NSString *)identifier;
- (NSDictionary *)streamSensePlaylistMetadataForIdentifier:(NSString *)identifier;
- (NSDictionary *)streamSenseClipMetadataForIdentifier:(NSString *)identifier;

// To be seen when implementing segments
//- (NSDictionary *)streamSenseSegmentClipMetadata;
//- (NSDictionary *)streamSenseSegmentMetadataWithPlaybackEventUserInfo:(NSDictionary *)userInfo wasSegmentSelected:(BOOL)segmentSelected;

@end
