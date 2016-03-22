//
//  Copyright (c) SRG SSR. All rights reserved.
//
//  License information is available from the LICENSE file.
//

#import "RTSAnalyticsNetmetrixTracker.h"

/**
 *  `RTSAnalyticsNetmetrixTracker` is used to track view events for Netmetrix.
 * 
 *  The destination URL is specified by a domain and appID.
 */
@interface RTSAnalyticsNetmetrixTracker : NSObject

/**
 *  --------------------------------------
 *  @name Initializing a Netmetrix Tracker
 *  --------------------------------------
 */

/**
 *  Returns a `RTSAnalyticsNetmetrixTracker` object initialized with the specified appID and Netmetrix domain.
 *
 *  @param appID  a unique id identifying Netmetrics application (e.g. rts-info, rts-sport, srg-player, ...)
 *  @param domain the nexmetrics domain used  (e.g. rts, srg, ...)
 *
 *  @return a Netmetrix tracker
 */
- (instancetype) initWithAppID:(NSString *)appID businessUnit:(SSRBusinessUnit)businessUnit;

/**
 *  -------------------
 *  @name View Tracking
 *  -------------------
 */

/**
 *  Send a view event for application specified by its AppID and domain.
 */
- (void) trackView;

@end
