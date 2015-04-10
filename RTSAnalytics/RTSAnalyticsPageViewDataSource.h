//
//  Created by Frédéric Humbert-Droz on 09/04/15.
//  Copyright (c) 2015 RTS. All rights reserved.
//

#import <Foundation/Foundation.h>

@protocol RTSAnalyticsPageViewDataSource <NSObject>

- (NSString *) pageViewTitle;

@optional
- (NSArray *) pageViewLevels;
- (BOOL) pageViewFromPushNotification;

@end
