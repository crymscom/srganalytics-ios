//
//  SRGAnalyticsTracker+SRGAnalytics_Identity.h
//  SRGAnalytics_Identity
//
//  Created by Pierre-Yves on 22.02.19.
//  Copyright © 2019 SRG SSR. All rights reserved.
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
