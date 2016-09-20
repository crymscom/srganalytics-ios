//
//  Copyright (c) SRG SSR. All rights reserved.
//
//  License information is available from the LICENSE file.
//

#import "SRGAnalyticsTracker.h"
#import "UIViewController+SRGAnalytics.h"

@interface SRGAnalyticsTracker (Private)

- (void)trackPageViewForObject:(id<SRGAnalyticsViewTracking>)dataSource;

@end
