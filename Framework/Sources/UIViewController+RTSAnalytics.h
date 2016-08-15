//
//  Copyright (c) SRG SSR. All rights reserved.
//
//  License information is available from the LICENSE file.
//

#import <UIKit/UIKit.h>

/**
 *  The implementation swizzles `viewDidAppear:` for automatic analytics (can be opt-out, see `RTSAnalyticsPageViewDataSource` protocol)
 */
@interface UIViewController (RTSAnalytics)

/**
 *  Call this method to track view events manually when content changes (by ex.: filtering data, changing part of the view, ...)
 */
- (void)trackPageView;

@end
