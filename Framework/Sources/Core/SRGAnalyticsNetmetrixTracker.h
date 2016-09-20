//
//  Copyright (c) SRG SSR. All rights reserved.
//
//  License information is available from the LICENSE file.
//

#import "SRGAnalyticsNetmetrixTracker.h"

/**
 *  `SRGAnalyticsNetmetrixTracker` is used to track view events for Netmetrix.
 * 
 *  The destination URL is specified by a domain and appID.
 */
@interface SRGAnalyticsNetmetrixTracker : NSObject

/**
 *  --------------------------------------
 *  @name Initializing a Netmetrix Tracker
 *  --------------------------------------
 */

/**
 *  Returns a `SRGAnalyticsNetmetrixTracker` object initialized with the specified appID and Netmetrix domain.
 *
 *  @param appID  a unique id identifying Netmetrics application (e.g. SRG-info, SRG-sport, srg-player, ...)
 *  @param domain the nexmetrics domain used  (e.g. SRG, srg, ...)
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
