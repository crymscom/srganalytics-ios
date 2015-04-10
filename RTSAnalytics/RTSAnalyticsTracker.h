//
//  Created by Cédric Foellmi on 25/03/15.
//  Copyright (c) 2015 RTS. All rights reserved.
//

#import <Foundation/Foundation.h>

#import "RTSAnalyticsPageViewDataSource.h"
#import "RTSAnalyticsMediaPlayerDataSource.h"

@interface RTSAnalyticsTracker : NSObject

/**
 *  Singleton instance of the tracker
 *
 *  @return Instance
 */
+ (instancetype)sharedTracker;

/**
 *  <#Description#>
 */
- (void)startTrackingWithMediaDataSource:(id<RTSAnalyticsMediaPlayerDataSource>)dataSource;

/**
 *  <#Description#>
 *
 *  @param title    <#title description#>
 *  @param levels   <#levels description#>
 *  @param fromPush <#fromPush description#>
 */
- (void)trackPageViewTitle:(NSString *)title levels:(NSArray *)levels;

/**
 *  <#Description#>
 *
 *  @param title    <#title description#>
 *  @param levels   <#levels description#>
 *  @param fromPush <#fromPush description#>
 */
- (void)trackPageViewTitle:(NSString *)title levels:(NSArray *)levels fromPushNotification:(BOOL)fromPush;

@end
