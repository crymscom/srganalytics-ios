//
//  Copyright (c) SRG SSR. All rights reserved.
//
//  License information is available from the LICENSE file.
//

#import <Foundation/Foundation.h>

@class SRGMediaPlayerController;
@protocol SRGAnalyticsMediaPlayerDataSource;

@interface SRGMediaPlayerControllerTracker : NSObject

/**
 *  ---------------------------------------
 *  @name Initializing an Analytics Tracker
 *  ---------------------------------------
 */

/**
 *  Singleton instance of the tracker.
 *
 *  @return Tracker's Instance
 */
+ (instancetype)sharedTracker;

/**
 *  ------------------------
 *  @name Stream Measurement
 *  ------------------------
 */

/**
 *  StaSRG the tracker for stream measurements.
 *
 *  @param virtualSite the comscore/streamsense virtual site for media measurement
 *  @param dataSource  the datasource which provides labels/playlist/clip for Streamsense tracker. (Mandatory)
 */
- (void)startStreamMeasurementForVirtualSite:(NSString *)virtualSite mediaDataSource:(id<SRGAnalyticsMediaPlayerDataSource>)dataSource OS_NONNULL_ALL;

/**
 *  Force tracking a media. Create a new `SRGMediaPlayerControllerStreamSenseTracker` instance and sends a "start" event type.
 *
 *  @param mediaPlayerController the media player controller instance to track
 */
- (void)startTrackingMediaPlayerController:(SRGMediaPlayerController *)mediaPlayerController forIdentifier:(NSString *)identifier;

/**
 *  Force to stop tracking a media. Automatically sends an "end" event type and remove the `SRGMediaPlayerControllerStreamSenseTracker` instance.
 *
 *  @param mediaPlayerController the media player controller instance to be removed from tracking
 */
- (void)stopTrackingMediaPlayerControllerForIdentifier:(NSString *)identifier;

@end
