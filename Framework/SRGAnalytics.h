//
//  Copyright (c) SRG SSR. All rights reserved.
//
//  License information is available from the LICENSE file.
//

#import <Foundation/Foundation.h>

FOUNDATION_EXPORT double SRGAnalyticsVersionNumber;
FOUNDATION_EXPORT const unsigned char SRGAnalyticsVersionString[];

FOUNDATION_EXPORT NSString * SRGAnalyticsMarketingVersion(void);

#import "RTSAnalyticsTracker.h"
#import "RTSAnalyticsComScoreTracker.h"
#import "RTSAnalyticsNetmetrixTracker.h"
#import "RTSAnalyticsPageViewDataSource.h"
#import "UIViewController+RTSAnalytics.h"
