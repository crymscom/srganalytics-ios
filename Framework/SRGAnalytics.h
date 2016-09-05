//
//  Copyright (c) SRG SSR. All rights reserved.
//
//  License information is available from the LICENSE file.
//

#import <Foundation/Foundation.h>

FOUNDATION_EXPORT double SRGAnalyticsVersionNumber;
FOUNDATION_EXPORT const unsigned char SRGAnalyticsVersionString[];

FOUNDATION_EXPORT NSString * SRGAnalyticsMarketingVersion(void);

#import "SRGAnalyticsLogger.h"
#import "SRGAnalyticsTracker.h"
#import "SRGAnalyticsComScoreTracker.h"
#import "SRGAnalyticsPageViewDataSource.h"
#import "UIViewController+SRGAnalytics.h"
