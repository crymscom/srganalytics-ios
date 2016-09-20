//
//  Copyright (c) SRG SSR. All rights reserved.
//
//  License information is available from the LICENSE file.
//

#import <Foundation/Foundation.h>

// Framework standard version number
FOUNDATION_EXPORT double SRGAnalyticsVersionNumber;
FOUNDATION_EXPORT const unsigned char SRGAnalyticsVersionString[];

// Oficial version number
FOUNDATION_EXPORT NSString * SRGAnalyticsMarketingVersion(void);

// Public headers
#import "SRGAnalyticsLogger.h"
#import "SRGAnalyticsTracker.h"
#import "SRGAnalyticsComScoreTracker.h"
#import "SRGAnalyticsPageViewDataSource.h"
#import "UIViewController+SRGAnalytics.h"
