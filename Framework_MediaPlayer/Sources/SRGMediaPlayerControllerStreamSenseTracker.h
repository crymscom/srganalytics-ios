//
//  Copyright (c) SRG SSR. All rights reserved.
//
//  License information is available from the LICENSE file.
//

#import <Foundation/Foundation.h>
#import <ComScore/CSStreamSense.h>

@class SRGMediaPlayerController;
@protocol SRGSegment;
@protocol SRGAnalyticsMediaPlayerDataSource;

/**
 *  The `SRGMediaPlayerControllerStreamSenseTracker` is a plugin for `SRGMediaPlayerController` which takes care of populating persistent labels, 
 *  playlist labels and clip labels.
 *
 *  To add custom labels, playlist and clip labels implements a dataSource responding to `SRGAnalyticsMediaPlayerDataSource` protocol.
 *
 *  @discussion  Due to Comscore SDK implementation, Streamsense measurements are not sent when media player playback state changes to buffering.
 */
@interface SRGMediaPlayerControllerStreamSenseTracker : CSStreamSense

/**
 *  ----------------------------------------------------
 *  @name Initializing a Media Player Controller Tracker
 *  ----------------------------------------------------
 */

/**
 *  Returns a media player controller Streamsense tracker instance.
 *
 *  @param mediaPlayerController the media player controller used for generating persistent labels.
 *  @param dataSource            the datasource for custom labels, playlist labels and clip labels of currently playing media.
 *  @param virtualSite           the streamsense virtual site for stream measurement
 *
 *  @return a media player controller StreamSense tracker.
 */
- (id)initWithPlayer:(SRGMediaPlayerController *)mediaPlayerController
          dataSource:(id<SRGAnalyticsMediaPlayerDataSource>)dataSource
         virtualSite:(NSString *)virtualSite OS_NONNULL_ALL;

/**
 *  ---------------------
 *  @name Stream Tracking
 *  ---------------------
 */

/**
 *  Notify the tracker to send a stream event. This method must be called each time the media player controller playback state changes.
 *
 *  This method will update Streamsense persistent and custom labels by calling methods defined in `SRGAnalyticsMediaPlayerDataSource` protocol.
 *
 *  @param playerEvent the event type corresponding to the media player controller playback state.
 *  @param segment the segment information to use (nil for the full-length)
 */
- (void)notify:(CSStreamSenseEventType)playerEvent withSegment:(id<SRGSegment>)segment forIdentifier:(NSString *)identifier;

/**
 *  Update labels for a given segment. Is automatically performed when calling -notify:withSegment:
 *
 *  @param segment the segment information to use (nil for the full-length)
 */
- (void)updateLabelsWithSegment:(id<SRGSegment>)segment forIdentifier:(NSString *)identifier;

@end
