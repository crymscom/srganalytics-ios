//
//  Copyright (c) RTS. All rights reserved.
//
//  Licence information is available from the LICENCE file.
//

#import <Foundation/Foundation.h>
#import <SRGMediaPlayer/RTSMediaSegment.h>

/**
 *  The `RTSAnalyticsMediaPlayerDataSource` groups methods that are used for Streamsense measurement when using the SRG Media Player
 *  library controllers (`RTSMediaPlayerController` and `RTSMediaSegmentsController`). It can be used to customize the labels
 *  which are sent
 * 
 *  Each method is called when playback changes or at each Comscore SDK heartbeat, so the default labels, playlist labels and clip 
 *  labels are updated before sending measurement to Comscore/Streamsense. If a segments controller is used, additional events will 
 *  be received when the user selects a segment, switches segments, or when a currently selected segment playback ends
 */
@protocol RTSAnalyticsMediaPlayerDataSource <NSObject>

@optional

/**
 *  Returns a dictionary of key values that will be sent to comScore at the time of the player ready.
 *
 *  @param identifier the identifier of the media
 *
 *  @return a dictionary of view labels for comScore
 */
- (NSDictionary *)comScoreReadyToPlayLabelsForIdentifier:(NSString *)identifier;

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
