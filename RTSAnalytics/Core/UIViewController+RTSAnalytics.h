//
//  Copyright (c) RTS. All rights reserved.
//
//  Licence information is available from the LICENCE file.
//

#import <UIKit/UIKit.h>

/**
 *  The implementation swizzles `viewDidAppear:` for automatic analytics
 */
@interface UIViewController (RTSAnalytics)

/**
 *  Call this method to track view events manually when content changes (by ex.: filtering data, changing part of the view, ...)
 */
- (void)trackPageView;

@end
