//
//  Created by Cédric Foellmi on 27/03/15.
//  Copyright (c) 2015 RTS. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <RTSMediaPlayer/RTSMediaSegment.h>

/**
 *  The `RTSAnalyticsMediaPlayerDataSource` groups methods that are used for Streamsense measurement when using `RTSMediaPlayerController`.
 * 
 *  Each method is called when playback changes or at each Comscore SDK heartbeat, so the default labels, playlist labels and clip labels are updated 
 *  before sending measurement to Comscore/Streamsense.
 */
@protocol RTSAnalyticsMediaPlayerDataSource <NSObject>

@optional

/**
 *  Returns a dictionary of key value that will be sent as Streamsense labels.
 *
 *  @param identifier the identifier of the video requesting default labels for Streamsense measurement.
 *
 *  @return a dictionary of labels.
 */
- (NSDictionary *)streamSenseLabelsMetadataForIdentifier:(NSString *)identifier;

/**
 *  Returns a dictionary of key values that will be sent as Streamsense playlist labels.
 *
 *  @param identifier the identifier of the video requesting playlist labels for Streamsense measurement.
 *
 *  @return a dictionary of playlist labels.
 */
- (NSDictionary *)streamSensePlaylistMetadataForIdentifier:(NSString *)identifier;

/**
 *  Returns a dictionary of key values that will be sent as Streamsens clip labels.
 *
 *  @param identifier the identifier of the video requesting clip labels for Streamsense measurement.
 *
 *  @return a dictionary of clip labels.
 */
- (NSDictionary *)streamSenseClipMetadataForIdentifier:(NSString *)identifier withSegment:(id<RTSMediaSegment>)segment;

@end
