//
//  Created by Frédéric Humbert-Droz on 15/04/15.
//  Copyright (c) 2015 RTS. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "RTSAnalyticsMediaPlayerDataSource.h"
#import "RTSAnalyticsMediaPlayerDelegate.h"

@interface RTSAnalyticsStreamTracker : NSObject

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
 *  Starts the tracker for stream measurements.
 *
 *  @param virtualSite the comscore/streamsense virtual site for media measurement
 *  @param dataSource  the datasource which provides labels/playlist/clip for Streamsense tracker. (Mandatory)
 */
- (void)startStreamMeasurementForVirtualSite:(NSString *)virtualSite mediaDataSource:(id<RTSAnalyticsMediaPlayerDataSource>)dataSource OS_NONNULL_ALL;

/**
 *  Keep a reference of the mediaPlayerDelegate. Called automatically by `UIViewController+RTSAnalyticsMediaPlayer.h` swizzled method.
 *
 *  @param mediPlayerDelegate the stream tracker delegate conforming to `RTSAnalyticsMediaPlayerDelegate`
 */
- (void) trackMediaPlayerFromPresentingViewController:(id<RTSAnalyticsMediaPlayerDelegate>)mediaPlayerDelegate;

/**
 *  Force tracking a media. Create a new `RTSMediaPlayerControllerStreamSenseTracker` instance and sends a "start" event type.
 *
 *  @param mediaPlayerController the media player controller instance to track
 */
- (void) startTrackingMediaPlayerController:(RTSMediaPlayerController *)mediaPlayerController;

/**
 *  Force to stop tracking a media. Automatically sends an "end" event type and remove the `RTSMediaPlayerControllerStreamSenseTracker` instance.
 *
 *  @param mediaPlayerController the media player controller instance to be removed from tracking
 */
- (void) stopTrackingMediaPlayerController:(RTSMediaPlayerController *)mediaPlayerController;

@end
