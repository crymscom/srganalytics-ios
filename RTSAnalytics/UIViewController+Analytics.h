//
//  UIViewController+Analytics.h
//  RTSAnalytics
//
//  Created by Frédéric Humbert-Droz on 09/04/15.
//  Copyright (c) 2015 RTS. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface UIViewController (Analytics)
// The implementation swizzles `viewDidAppear:` for automatic analytics

- (void) sendPageView;

@end
