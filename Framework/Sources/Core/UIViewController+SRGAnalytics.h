//
//  Copyright (c) SRG SSR. All rights reserved.
//
//  License information is available from the LICENSE file.
//

#import <UIKit/UIKit.h>

/**
 *  Analytics extensions for `UIViewController` tracking
 */
@interface UIViewController (SRGAnalytics)

/**
 *  Call this method to send a page view event manually
 */
- (void)trackPageView;

@end
