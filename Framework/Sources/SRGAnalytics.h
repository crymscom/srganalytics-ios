//
//  Copyright (c) SRG SSR. All rights reserved.
//
//  License information is available from the LICENSE file.
//

#import <Foundation/Foundation.h>

// Official version number.
FOUNDATION_EXPORT NSString * SRGAnalyticsMarketingVersion(void);

//  Return `YES` iff run in a public (open source) setup.
FOUNDATION_EXPORT BOOL SRGAnalyticsIsPublic(void);

// Public headers.
#import "SRGAnalyticsConfiguration.h"
#import "SRGAnalyticsHiddenEventLabels.h"
#import "SRGAnalyticsLabels.h"
#import "SRGAnalyticsNotifications.h"
#import "SRGAnalyticsPageViewLabels.h"
#import "SRGAnalyticsStreamLabels.h"
#import "SRGAnalyticsStreamTracker.h"
#import "SRGAnalyticsTracker.h"
#import "UIViewController+SRGAnalytics.h"
