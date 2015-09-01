//
//  Copyright (c) RTS. All rights reserved.
//
//  Licence information is available from the LICENCE file.
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
 *  @discussion The AppID and Netmetrix domain MUST be set ONLY when application is in production !
 *
 *  @return a Netmetrix tracker
 */
- (instancetype) initWithAppID:(NSString *)appID businessUnit:(SSRBusinessUnit)businessUnit production:(BOOL)production;

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
