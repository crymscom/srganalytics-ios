//
//  Created by Frédéric Humbert-Droz on 15/04/15.
//  Copyright (c) 2015 RTS. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "RTSAnalyticsMediaPlayerDataSource.h"

@interface RTSAnalyticsStreamTracker : NSObject

/**
 *  --------------------------------------------
 *  @name Initializing an Analytics Tracker
 *  --------------------------------------------
 */

/**
 *  Singleton instance of the tracker.
 *
 *  @return Tracker's Instance
 */
+ (instancetype)sharedTracker;

/**
 *  --------------------------------------------
 *  @name Stream Measurement
 *  --------------------------------------------
 */

/**
 *  Starts the tracker for page views and streams played with RTSMediaPlayerController.
 *
 *  @param dataSource the datasource which provides labels/playlist/clip for Streamsense tracker. (Mandatory)
 *
 *  @discussion the tracker uses values set in application Info.plist to track Comscore, Streamsense and Netmetrix measurement.
 *  Add an Info.plist dictionary named `RTSAnalytics` with 4 keypairs :
 *              ComscoreVirtualSite    : string - mandatory
 *              StreamsenseVirtualSite : string - mandatory
 *              NetmetrixAppID         : string - NetmetrixAppID MUST be set ONLY for application in production.
 *	            NetmetrixDomain        : string - optionnal - if not set, the domain will use the calculated BusinessUnit string based on the application bundleIdentifier.
 *
 *  The application MUST call `-startTrackingWithMediaDataSource:` ONLY in `-application:didFinishLaunchingWithOptions:`.
 */
- (void)startStreamMeasurementForVirtualSite:(NSString *)virtualSite mediaDataSource:(id<RTSAnalyticsMediaPlayerDataSource>)dataSource OS_NONNULL_ALL;

@end
