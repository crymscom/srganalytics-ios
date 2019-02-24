//
//  Copyright (c) SRG SSR. All rights reserved.
//
//  License information is available from the LICENSE file.
//

#import <SRGAnalytics/SRGAnalytics.h>
#import <SRGidentity/SRGIdentity.h>

NS_ASSUME_NONNULL_BEGIN

@interface SRGAnalyticsTracker (SRGAnalytics_Identity)

/**
 *  The identity service associated with the tracker.
 */
@property (nonatomic, nullable) SRGIdentityService *identityService;

@end

NS_ASSUME_NONNULL_END
