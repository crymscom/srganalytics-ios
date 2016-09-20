//
//  Copyright (c) SRG SSR. All rights reserved.
//
//  License information is available from the LICENSE file.
//

#import "SRGAnalyticsNetMetrixTracker.h"

NS_ASSUME_NONNULL_BEGIN

/**
 *  Tracker for NetMetrix related events
 */
@interface SRGAnalyticsNetMetrixTracker : NSObject

/**
 *  Create a tracker for the specified NetMetrix identifier and business unit
 *
 *  @param identifier   A unique NetMetrix identifier for the application (e.g. SRG-info, SRG-sport, srg-player, ...)
 *  @param businessUnit The business unit to which events must be associated
 *
 *  @return a Netmetrix tracker
 */
- (instancetype)initWithIdentifier:(NSString *)identifier businessUnit:(SSRBusinessUnit)businessUnit;

/**
 *  Send a view event
 */
- (void)trackView;

@end

NS_ASSUME_NONNULL_END
